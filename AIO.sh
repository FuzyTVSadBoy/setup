#!/data/data/com.termux/files/usr/bin/bash

# ==============================================================================
# BOOTLOADER: CÀI ĐẶT MÔI TRƯỜNG PYTHON & RICH TRƯỚC KHI CHẠY UI
# ==============================================================================
clear
echo -e "\033[1;33m[!] Bootstrapping Python Environment...\033[0m"

# 1. Cài Python và pip nếu chưa có
if ! command -v python >/dev/null 2>&1; then
    echo " -> Installing Python..."
    pkg install python -y >/dev/null 2>&1
fi

# 2. Cài thư viện giao diện (Rich) và mạng (Requests)
echo " -> Installing dependencies (Rich & Requests)..."
pip install rich requests psutil --no-cache-dir --quiet >/dev/null 2>&1

# ==============================================================================
# MAIN PYTHON SCRIPT STARTS HERE
# ==============================================================================
cat <<EOF > run_aio.py
import os
import sys
import time
import subprocess
import shutil
import requests
import re
from rich.console import Console
from rich.panel import Panel
from rich.progress import Progress, SpinnerColumn, BarColumn, TextColumn, DownloadColumn, TransferSpeedColumn, TimeRemainingColumn
from rich.layout import Layout
from rich.live import Live
from rich.table import Table
from rich.style import Style
from rich import box

# --- CẤU HÌNH ---
console = Console()
DOWNLOAD_DIR = "/sdcard/Download/auto_apk_root"
TOOL_URL = "https://raw.githubusercontent.com/FuzyTVSadBoy/setup/refs/heads/main/OldShouko.py"
REPO_SCRIPT = "https://raw.githubusercontent.com/FuzyTVSadBoy/setup/refs/heads/main/termux-change-repo.sh"

APK_LINKS = [
    "https://download2272.mediafire.com/6xz4xlxoffagKvtpi3FSD-dX6QqN8tfX6NHSRXSvn0Nz6jAZLG9V5FyYwX2Wvi0K_B6p0KjgeT1jMPN_TNoCC4Rh8WUEjDt0TtTxr2wDKu5Mdp6stol7j7nHeKHCnO1mErxTKvjDYuBESGwJ55xu_12q3yPkhXgdFPKGMCB4g6laiw/x5b9678xq6ut13d/DeltaGlobalCloneByCherry+1-2.706.750.apk.apk",
    "https://download2264.mediafire.com/vi77ssprg8bgwmO2m2X5aYfbs1FAWWQI9nw9uu5i7GNvkHkFrMWLkFSSUzMTNfmOlhIt9COFrjSzMgkqHxw-6BlyXLCvgCBOCvQUaXwC_7BeArU3NAxiSWI8zKzmubxBLMgKu-g3qjQziBA-Xsh-MEt5nNJTqjNi8qmJ55DPlXTcwA/wyz9r4nwjbssnwg/DeltaGlobalCloneByCherry+2-2.706.750.apk.apk",
    "https://download1591.mediafire.com/iqaccp5d39gg3D3f3M6x8wwD5JmsHWyBP9bWH_wQ4yQdy13TY1w8V8yXRGRC1G2I-fxz6uqIaq3jglds_LvIB1GSuL9RPMZNp1TtSHa2rhdFgHpQYSOCazn65XF2_fmuNmftAQdTIawaVEGljQ8p4Tk-a0TuvalwahVpR_MMehN7Lw/dsrr6vxd35l63j8/DeltaGlobalCloneByCherry+3-2.706.750.apk.apk"
]

# --- HELPER FUNCTIONS ---
def header():
    console.clear()
    console.print(Panel.fit(
        "[bold cyan]UGPHONE AIO ULTIMATE[/bold cyan]\n[yellow]Python Rich UI Edition[/yellow]",
        border_style="bold blue",
        padding=(1, 5)
    ))

def run_cmd(command, shell=True):
    """Chạy lệnh shell ẩn"""
    try:
        subprocess.run(command, shell=shell, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return True
    except subprocess.CalledProcessError:
        return False

def check_root():
    """Kiểm tra quyền Root"""
    try:
        subprocess.check_call(['su', '-c', 'id'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return True
    except:
        return False

# --- TASKS ---

def step_1_storage():
    with console.status("[bold green]Setting up Storage...", spinner="dots"):
        home_storage = "/data/data/com.termux/files/home/storage"
        if os.path.exists(home_storage):
            shutil.rmtree(home_storage, ignore_errors=True)
        run_cmd("termux-setup-storage")
        time.sleep(1)
    console.print("[✓] Storage Configured", style="green")

def step_2_system_update():
    # Sử dụng Progress bar cho task dài
    with Progress(
        SpinnerColumn(),
        TextColumn("[progress.description]{task.description}"),
        BarColumn(),
        TimeRemainingColumn(),
        console=console
    ) as progress:
        task1 = progress.add_task("[cyan]Updating Packages...", total=3)
        
        # 1. Update
        run_cmd("pkg update -y")
        progress.advance(task1)
        
        # 2. Repo Config
        run_cmd(f'bash -c "$(curl -fsSL {REPO_SCRIPT})"')
        progress.advance(task1)
        
        # 3. Upgrade
        run_cmd('pkg upgrade -y -o Dpkg::Options::="--force-confnew"')
        progress.advance(task1)
        
    console.print("[✓] System Upgraded", style="green")

def step_3_libs():
    with console.status("[bold yellow]Installing Extra Libraries...", spinner="earth"):
        run_cmd("pip install psutil --no-cache-dir")
    console.print("[✓] Libraries Ready", style="green")

def step_4_device_config():
    if not check_root():
        console.print("[bold red][X] NO ROOT ACCESS! EXITING...[/bold red]")
        sys.exit(1)
        
    with console.status("[bold magenta]Configuring Device ID & Window...", spinner="bouncingBall"):
        hwid = "f43f5764ee3f616a"
        cmds = [
            f"settings put secure android_id {hwid}",
            "wm density 200",
            "settings put global development_settings_enabled 1",
            "settings put global force_resizable_activities 1",
            "settings put global enable_freeform_support 1"
        ]
        for cmd in cmds:
            run_cmd(f'su -c "{cmd}"')
            
    console.print(f"[✓] Device ID Set: ...{hwid[-4:]}", style="green")

def step_5_download_tool():
    dest = "/sdcard/Download/OldShouko.py"
    with console.status("[bold blue]Downloading Main Tool...", spinner="dots"):
        try:
            r = requests.get(TOOL_URL, timeout=10)
            if r.status_code == 200:
                with open(dest, 'wb') as f:
                    f.write(r.content)
                console.print("[✓] OldShouko.py Saved", style="green")
            else:
                console.print("[!] Tool Download Failed (HTTP Error)", style="red")
        except:
             console.print("[!] Tool Download Failed (Connection)", style="red")

def step_6_download_apks():
    if os.path.exists(DOWNLOAD_DIR):
        shutil.rmtree(DOWNLOAD_DIR)
    os.makedirs(DOWNLOAD_DIR)

    console.print(f"\n[bold cyan]Downloading {len(APK_LINKS)} APK(s) from Mediafire...[/bold cyan]")
    
    # Custom Progress Bar cho việc tải file
    progress = Progress(
        TextColumn("[bold blue]{task.fields[filename]}", justify="right"),
        BarColumn(bar_width=None),
        "[progress.percentage]{task.percentage:>3.1f}%",
        "•",
        DownloadColumn(),
        "•",
        TransferSpeedColumn(),
        "•",
        TimeRemainingColumn(),
        console=console
    )

    with progress:
        for url in APK_LINKS:
            try:
                # Xử lý tên file
                filename = url.split('/')[-1]
                # Fix lỗi .apk.apk
                if filename.endswith(".apk.apk"):
                    filename = filename[:-4]
                
                # Tên hiển thị ngắn gọn
                display_name = (filename[:25] + '..') if len(filename) > 25 else filename
                
                dest_path = os.path.join(DOWNLOAD_DIR, filename)
                
                # Tạo request stream
                response = requests.get(url, stream=True, timeout=30, headers={'User-Agent': 'Mozilla/5.0'})
                total_length = int(response.headers.get('content-length', 0))
                
                task_id = progress.add_task("download", filename=display_name, total=total_length)
                
                with open(dest_path, 'wb') as f:
                    for chunk in response.iter_content(chunk_size=8192):
                        if chunk:
                            f.write(chunk)
                            progress.update(task_id, advance=len(chunk))
                            
            except Exception as e:
                console.print(f"[red][X] Error downloading {filename}: {str(e)}[/red]")

    console.print("[✓] All Downloads Completed", style="green")

def step_7_install_apks():
    files = [f for f in os.listdir(DOWNLOAD_DIR) if f.endswith(".apk")]
    
    if not files:
        console.print("[bold red]No APKs found to install![/bold red]")
        return

    console.print(f"\n[bold cyan]Installing {len(files)} App(s)...[/bold cyan]")
    
    table = Table(show_header=True, header_style="bold magenta", box=box.SIMPLE)
    table.add_column("App Name")
    table.add_column("Status")
    
    with Live(table, refresh_per_second=4, console=console):
        for apk in files:
            full_path = os.path.join(DOWNLOAD_DIR, apk)
            # Fix quyền file
            os.chmod(full_path, 0o644)
            
            short_name = (apk[:30] + '..') if len(apk) > 30 else apk
            
            # Lệnh cài đặt
            cmd = f'su -c "pm install -r \\"{full_path}\\""'
            
            if run_cmd(cmd):
                table.add_row(short_name, "[green]SUCCESS[/green]")
            else:
                table.add_row(short_name, "[red]FAILED (GUI)[/red]")
                # Fallback mở GUI
                try:
                    subprocess.run(f'am start -a android.intent.action.VIEW -d "file://{full_path}" -t application/vnd.android.package-archive', shell=True, stderr=subprocess.DEVNULL)
                except: pass
            
            time.sleep(0.5)

# --- MAIN EXECUTION ---
if __name__ == "__main__":
    header()
    
    step_1_storage()
    console.print(Rule(style="dim"))
    
    step_2_system_update()
    console.print(Rule(style="dim"))
    
    step_3_libs()
    console.print(Rule(style="dim"))
    
    step_5_download_tool() # Đảo thứ tự xíu cho logic
    console.print(Rule(style="dim"))
    
    step_4_device_config()
    console.print(Rule(style="dim"))
    
    step_6_download_apks()
    
    step_7_install_apks()
    
    console.print(Panel("[bold yellow blink]REBOOT DEVICE NOW![/bold yellow blink]", style="red"))
EOF

# CHẠY PYTHON
python run_aio.py
rm run_aio.py
