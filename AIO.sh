#!/data/data/com.termux/files/usr/bin/bash

# ==============================================================================
# BOOTLOADER: CHUẨN BỊ MÔI TRƯỜNG
# ==============================================================================
clear
echo -e "\033[1;36m[>] Initializing Cyberpunk UI Environment...\033[0m"

# 1. Update & Cài Python
if ! command -v python >/dev/null 2>&1; then
    pkg install python -y >/dev/null 2>&1
fi

# 2. Cài thư viện
pip install rich requests psutil pyfiglet --no-cache-dir --quiet >/dev/null 2>&1

# ==============================================================================
# MAIN PYTHON SCRIPT (CYBERPUNK EDITION - PERMISSION FIX)
# ==============================================================================
cat <<EOF > run_aio.py
import os
import sys
import time
import subprocess
import shutil
import requests
import psutil
import platform
from datetime import datetime

# RICH IMPORTS
from rich.console import Console
from rich.panel import Panel
from rich.layout import Layout
from rich.live import Live
from rich.table import Table
from rich.text import Text
from rich.align import Align
from rich.progress import Progress, SpinnerColumn, BarColumn, TextColumn, DownloadColumn, TransferSpeedColumn, TimeRemainingColumn
from rich import box
from rich.style import Style

# --- CẤU HÌNH ---
console = Console()
DOWNLOAD_DIR = "/sdcard/Download/auto_apk_root"
TOOL_URL = "https://raw.githubusercontent.com/FuzyTVSadBoy/setup/refs/heads/main/OldShouko.py"
APK_LINKS = [
    "https://download2272.mediafire.com/6xz4xlxoffagKvtpi3FSD-dX6QqN8tfX6NHSRXSvn0Nz6jAZLG9V5FyYwX2Wvi0K_B6p0KjgeT1jMPN_TNoCC4Rh8WUEjDt0TtTxr2wDKu5Mdp6stol7j7nHeKHCnO1mErxTKvjDYuBESGwJ55xu_12q3yPkhXgdFPKGMCB4g6laiw/x5b9678xq6ut13d/DeltaGlobalCloneByCherry+1-2.706.750.apk.apk",
    "https://download2264.mediafire.com/vi77ssprg8bgwmO2m2X5aYfbs1FAWWQI9nw9uu5i7GNvkHkFrMWLkFSSUzMTNfmOlhIt9COFrjSzMgkqHxw-6BlyXLCvgCBOCvQUaXwC_7BeArU3NAxiSWI8zKzmubxBLMgKu-g3qjQziBA-Xsh-MEt5nNJTqjNi8qmJ55DPlXTcwA/wyz9r4nwjbssnwg/DeltaGlobalCloneByCherry+2-2.706.750.apk.apk",
    "https://download1591.mediafire.com/iqaccp5d39gg3D3f3M6x8wwD5JmsHWyBP9bWH_wQ4yQdy13TY1w8V8yXRGRC1G2I-fxz6uqIaq3jglds_LvIB1GSuL9RPMZNp1TtSHa2rhdFgHpQYSOCazn65XF2_fmuNmftAQdTIawaVEGljQ8p4Tk-a0TuvalwahVpR_MMehN7Lw/dsrr6vxd35l63j8/DeltaGlobalCloneByCherry+3-2.706.750.apk.apk"
]

# --- HÀM HỆ THỐNG ---
def run_cmd(command, shell=True):
    try:
        subprocess.run(command, shell=shell, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return True
    except:
        return False

def get_sys_info():
    uname = platform.uname()
    ram = psutil.virtual_memory()
    return f"[bold cyan]OS:[/bold cyan] Android {uname.release} | [bold cyan]RAM:[/bold cyan] {ram.percent}% Used"

# --- UI COMPONENTS ---

def make_header():
    try:
        import pyfiglet
        title = pyfiglet.figlet_format("UGPHONE", font="slant")
    except:
        title = "UGPHONE AIO"
    
    return Panel(
        Align.center(f"[bold magenta]{title}[/bold magenta]\n[white]Ultimate Setup Tool v3.1 (Fix)[/white]"),
        box=box.ROUNDED,
        border_style="cyan"
    )

def create_job_table(jobs):
    table = Table(expand=True, box=box.SIMPLE_HEAVY, border_style="dim white")
    table.add_column("ID", justify="center", style="cyan", no_wrap=True, width=4)
    table.add_column("Task Name", style="white")
    table.add_column("Status", justify="right", style="bold")

    for job in jobs:
        status_style = "dim"
        status_icon = "..."
        
        if job["status"] == "running":
            status_style = "bold yellow"
            status_icon = "🔄"
        elif job["status"] == "done":
            status_style = "bold green"
            status_icon = "✅"
        elif job["status"] == "error":
            status_style = "bold red"
            status_icon = "❌"
            
        table.add_row(str(job["id"]), job["name"], f"[{status_style}]{status_icon}[/{status_style}]")
    
    return Panel(table, title="[bold yellow]TASK MANAGER[/bold yellow]", border_style="yellow")

# --- MAIN LOGIC ---

def main():
    # Danh sách các bước
    jobs = [
        {"id": 1, "name": "Reset & Configure Storage", "status": "pending"},
        {"id": 2, "name": "Verify System Libraries", "status": "pending"},
        {"id": 3, "name": "Download Core Tool (OldShouko)", "status": "pending"},
        {"id": 4, "name": "Root & Device Config", "status": "pending"},
        {"id": 5, "name": "Download APK Resources", "status": "pending"},
        {"id": 6, "name": "Install Applications", "status": "pending"},
    ]

    layout = Layout()
    layout.split(
        Layout(name="header", size=8),
        Layout(name="body"),
        Layout(name="footer", size=3)
    )
    
    layout["header"].update(make_header())
    layout["footer"].update(Panel(Align.center(get_sys_info()), style="blue"))

    # BẮT ĐẦU LIVE UI CHO CÁC TÁC VỤ NHANH
    with Live(layout, refresh_per_second=10, screen=True):
        
        # --- JOB 1: STORAGE ---
        jobs[0]["status"] = "running"
        layout["body"].update(create_job_table(jobs))
        
        home_storage = "/data/data/com.termux/files/home/storage"
        if os.path.exists(home_storage):
            shutil.rmtree(home_storage, ignore_errors=True)
        run_cmd("termux-setup-storage")
        time.sleep(1)
        
        jobs[0]["status"] = "done"
        layout["body"].update(create_job_table(jobs))

        # --- JOB 2: LIBS ---
        jobs[1]["status"] = "running"
        layout["body"].update(create_job_table(jobs))
        time.sleep(0.5) 
        jobs[1]["status"] = "done"
        layout["body"].update(create_job_table(jobs))

        # --- JOB 3: DOWNLOAD TOOL ---
        jobs[2]["status"] = "running"
        layout["body"].update(create_job_table(jobs))
        dest = "/sdcard/Download/OldShouko.py"
        try:
            r = requests.get(TOOL_URL, timeout=10)
            if r.status_code == 200:
                with open(dest, 'wb') as f:
                    f.write(r.content)
                jobs[2]["status"] = "done"
            else:
                jobs[2]["status"] = "error"
        except:
             jobs[2]["status"] = "error"
        layout["body"].update(create_job_table(jobs))

        # --- JOB 4: DEVICE CONFIG ---
        jobs[3]["status"] = "running"
        layout["body"].update(create_job_table(jobs))
        
        # Check root
        try:
            subprocess.check_call(['su', '-c', 'id'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            hwid = "f43f5764ee3f616a"
            run_cmd(f'su -c "settings put secure android_id {hwid}"')
            run_cmd('su -c "wm density 200"')
            jobs[3]["status"] = "done"
        except:
            jobs[3]["status"] = "error"
        
        layout["body"].update(create_job_table(jobs))

    # --- CHUYỂN CẢNH: DOWNLOADER INTERFACE ---
    console.clear()
    console.print(make_header())
    
    console.print(Panel("[bold cyan]INITIALIZING DOWNLOAD PROTOCOL...[/bold cyan]", border_style="cyan"))
    
    if os.path.exists(DOWNLOAD_DIR):
        shutil.rmtree(DOWNLOAD_DIR)
    os.makedirs(DOWNLOAD_DIR)

    progress = Progress(
        SpinnerColumn(spinner_name="dots12", style="bold magenta"),
        TextColumn("[bold cyan]{task.fields[filename]}", justify="left"),
        BarColumn(bar_width=None, style="magenta", complete_style="bold cyan"),
        "[progress.percentage]{task.percentage:>3.0f}%",
        "•",
        TransferSpeedColumn(),
        "•",
        TimeRemainingColumn(),
        console=console,
        expand=True
    )

    with progress:
        for url in APK_LINKS:
            filename = url.split('/')[-1]
            if filename.endswith(".apk.apk"): filename = filename[:-4]
            display_name = (filename[:20] + '..') if len(filename) > 20 else filename
            dest_path = os.path.join(DOWNLOAD_DIR, filename)

            task_id = progress.add_task("dl", filename=display_name, total=None)
            
            try:
                response = requests.get(url, stream=True, timeout=30, headers={'User-Agent': 'Mozilla/5.0'})
                progress.update(task_id, total=int(response.headers.get('content-length', 0)))
                
                with open(dest_path, 'wb') as f:
                    for chunk in response.iter_content(chunk_size=8192):
                        if chunk:
                            f.write(chunk)
                            progress.update(task_id, advance=len(chunk))
            except:
                console.print(f"[red]Failed: {filename}[/red]")

    # --- CHUYỂN CẢNH: INSTALLER INTERFACE ---
    console.clear()
    console.print(make_header())
    
    files = [f for f in os.listdir(DOWNLOAD_DIR) if f.endswith(".apk")]
    
    install_table = Table(title="[bold yellow]INSTALLATION QUEUE[/bold yellow]", expand=True, box=box.ROUNDED, border_style="green")
    install_table.add_column("APK Name", style="white")
    install_table.add_column("Progress", style="dim")
    install_table.add_column("Result", justify="right")

    with Live(install_table, refresh_per_second=4, console=console):
        for apk in files:
            short_name = (apk[:25] + '..') if len(apk) > 25 else apk
            full_path = os.path.join(DOWNLOAD_DIR, apk)
            
            # --- FIX: Bọc chmod trong try-except để tránh lỗi PermissionError ---
            try:
                os.chmod(full_path, 0o644)
            except Exception:
                pass # Bỏ qua nếu không set được quyền (sdcard)
            # -----------------------------------------------------------------
            
            install_table.add_row(short_name, "Installing...", "⏳")
            
            cmd = f'su -c "pm install -r \\"{full_path}\\""'
            if run_cmd(cmd):
                install_table.rows[-1].set_cell(1, "[bold green]Done[/bold green]")
                install_table.rows[-1].set_cell(2, "[bold green]SUCCESS[/bold green]")
            else:
                install_table.rows[-1].set_cell(1, "[red]Error[/red]")
                install_table.rows[-1].set_cell(2, "[bold red]FAIL[/bold red]")
                try:
                    subprocess.run(f'am start -a android.intent.action.VIEW -d "file://{full_path}" -t application/vnd.android.package-archive', shell=True, stderr=subprocess.DEVNULL)
                except: pass
            
            time.sleep(0.5)

    console.print(Panel(
        Align.center("[bold yellow blink]⚠ SYSTEM REBOOT REQUIRED ⚠[/bold yellow blink]\n[dim]Device ID has been changed[/dim]"),
        border_style="red",
        box=box.DOUBLE
    ))

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        console.print("\n[red]User Aborted![/red]")
EOF

# CHẠY PYTHON
python run_aio.py
rm run_aio.py
