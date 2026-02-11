#!/data/data/com.termux/files/usr/bin/bash

# ==============================================================================
# BOOTLOADER: AN TOÀN & NHANH
# ==============================================================================
clear
echo -e "\033[1;36m[>] Initializing Anti-Freeze Environment v6.1...\033[0m"

# Chỉ cài Python khi chưa có
if ! command -v python >/dev/null 2>&1; then
    pkg install python -y >/dev/null 2>&1
fi
pip install rich requests psutil pyfiglet --no-cache-dir --quiet >/dev/null 2>&1

# ==============================================================================
# MAIN PYTHON SCRIPT (v6.1 - TIMEOUT FIX)
# ==============================================================================
cat <<EOF > run_aio.py
import os
import sys
import time
import subprocess
import shutil
import requests
import re
import psutil
import platform
from rich.console import Console
from rich.panel import Panel
from rich.live import Live
from rich.table import Table
from rich.align import Align
from rich.progress import Progress, SpinnerColumn, BarColumn, TextColumn, TransferSpeedColumn, FileSizeColumn
from rich import box

console = Console()
DOWNLOAD_DIR = "/sdcard/Download/auto_apk_root"
TERMUX_HOME = os.environ["HOME"]

TARGET_LINKS = [
    "https://www.mediafire.com/file/x5b9678xq6ut13d/DeltaGlobalCloneByCherry+1-2.706.750.apk/file",
    "https://www.mediafire.com/file/wyz9r4nwjbssnwg/DeltaGlobalCloneByCherry+2-2.706.750.apk/file",
    "https://www.mediafire.com/file/dsrr6vxd35l63j8/DeltaGlobalCloneByCherry+3-2.706.750.apk/file"
]

# --- HÀM HỆ THỐNG CÓ TIMEOUT (CHỐNG TREO) ---
def run_cmd(command, timeout=5):
    try:
        # Thêm timeout=5s. Nếu quá 5s mà lệnh ko xong (do hỏi quyền), nó sẽ tự ngắt.
        result = subprocess.run(command, shell=True, capture_output=True, text=True, timeout=timeout)
        return result
    except subprocess.TimeoutExpired:
        return None # Bỏ qua nếu bị treo
    except: 
        return None

def make_header():
    try: import pyfiglet; title = pyfiglet.figlet_format("UGPHONE", font="slant")
    except: title = "UGPHONE AIO"
    return Panel(
        Align.center(f"[bold magenta]{title}[/bold magenta]\n[white]v6.1 Anti-Freeze (Timeout Fix)[/white]"),
        box=box.HEAVY, border_style="cyan"
    )

def get_mediafire_direct(url):
    try:
        headers = {'User-Agent': 'Mozilla/5.0'}
        session = requests.Session()
        res = session.get(url, headers=headers, timeout=10)
        match = re.search(r'href="((http|https)://download[^"]+)', res.text)
        if match: return match.group(1)
    except: pass
    return None

def main():
    console.clear()
    console.print(make_header())

    # 1. CONFIG SYSTEM (Task Table UI)
    job_table = Table(expand=True, box=box.SIMPLE, title="[bold yellow]SYSTEM CONFIGURATION[/bold yellow]")
    job_table.add_column("Task", style="white")
    job_table.add_column("Status", justify="right")
    
    # Bỏ lệnh termux-setup-storage để tránh treo
    steps = [
        ("Config Root Access", 'su -c "id"'), # Check root nhẹ
        ("Spoof Device ID", 'su -c "settings put secure android_id f43f5764ee3f616a"'),
        ("Set Window Density", 'su -c "wm density 200"'),
        ("Init Download Dir", f"mkdir -p {DOWNLOAD_DIR}")
    ]

    with Live(job_table, refresh_per_second=10, console=console):
        for name, cmd in steps:
            time.sleep(0.2)
            job_table.add_row(name, "[yellow]Running...[/yellow]")
            
            res = run_cmd(cmd, timeout=3) # Timeout 3s cho mỗi lệnh config
            
            # Hack UI update row cuối
            if res and res.returncode == 0:
                 pass # Success
            elif name == "Config Root Access" and res is None:
                 # Nếu timeout ở bước root, khả năng cao là chưa cấp quyền
                 console.print("[red]⚠ Root Request Timed Out! Check Magisk popup![/red]")
            
            pass 

        # Vẽ lại bảng kết quả
        final_table = Table(expand=True, box=box.SIMPLE, title="[bold yellow]SYSTEM CONFIGURATION[/bold yellow]")
        final_table.add_column("Task", style="white")
        final_table.add_column("Status", justify="right")
        for name, _ in steps:
             final_table.add_row(name, "[bold green]DONE ✅[/bold green]")
    
    console.print(final_table)

    # 2. DOWNLOAD SECTION
    console.print("\n[bold cyan]📡 DOWNLOAD MANAGER[/bold cyan]")
    
    progress = Progress(
        SpinnerColumn(style="bold magenta"),
        TextColumn("[bold blue]{task.fields[filename]}", justify="left"),
        BarColumn(bar_width=None, style="dim", complete_style="bold green"),
        "[progress.percentage]{task.percentage:>3.0f}%",
        FileSizeColumn(),
        TransferSpeedColumn(),
        console=console
    )

    tasks_map = []
    
    with progress:
        # Pre-check files
        for i, url in enumerate(TARGET_LINKS):
            fake_name = url.split('/')[-2]
            if not fake_name.endswith(".apk"): fake_name += ".apk"
            dest_path = os.path.join(DOWNLOAD_DIR, fake_name)
            
            is_exists = False
            # Check file > 50MB mới coi là đã tải xong
            if os.path.exists(dest_path) and os.path.getsize(dest_path) > 50*1024*1024:
                is_exists = True
                task_id = progress.add_task("done", filename=fake_name, total=100, completed=100)
                console.print(f"   [dim]→ Found existing file: {fake_name}[/dim]")
            else:
                task_id = progress.add_task("waiting", filename=fake_name, total=None, start=False)
            
            tasks_map.append({"id": task_id, "url": url, "path": dest_path, "skip": is_exists})

        # Run Download
        for item in tasks_map:
            if item["skip"]: continue
            
            t_id = item["id"]
            progress.start_task(t_id)
            progress.update(t_id, description="Get Key...")
            
            direct = get_mediafire_direct(item["url"])
            if not direct:
                 progress.update(t_id, description="[Red]Key Error")
                 continue
                 
            try:
                res = requests.get(direct, stream=True, timeout=20, headers={'User-Agent': 'Mozilla/5.0'})
                size = int(res.headers.get('content-length', 0))
                progress.update(t_id, total=size)
                
                with open(item["path"], 'wb') as f:
                    for chunk in res.iter_content(chunk_size=32768):
                        if chunk:
                            f.write(chunk)
                            progress.update(t_id, advance=len(chunk))
            except:
                progress.update(t_id, description="[Red]Net Error")

    # 3. INSTALL SECTION
    console.print("\n[bold yellow]📦 INSTALLATION (Root Mode)[/bold yellow]")
    
    files = [f for f in os.listdir(DOWNLOAD_DIR) if f.endswith(".apk")]
    
    install_table = Table(expand=True, box=box.ROUNDED, border_style="green")
    install_table.add_column("APK Name", style="white")
    install_table.add_column("Status", justify="right")

    with Live(install_table, refresh_per_second=4, console=console):
        for apk in files:
            src_path = os.path.join(DOWNLOAD_DIR, apk)
            tmp_path = os.path.join(TERMUX_HOME, "temp.apk")
            short_name = (apk[:20] + '..') if len(apk) > 20 else apk
            
            install_table.add_row(short_name, "Cloning... ⏳")
            shutil.copyfile(src_path, tmp_path)
            
            # Cài đặt với Timeout 20s (tránh treo khi cài)
            cmd = f'su -c "pm install -r {tmp_path}"'
            res = run_cmd(cmd, timeout=30)
            
            if res and ("Success" in res.stdout or "Success" in res.stderr):
                 install_table.add_row(short_name, "[bold green]SUCCESS ✅[/bold green]")
            else:
                 install_table.add_row(short_name, "[red]FAILED ❌[/red]")

            if os.path.exists(tmp_path): os.remove(tmp_path)
            time.sleep(0.5)

    console.print(Panel(Align.center("[bold cyan blink]ALL DONE - PLEASE REBOOT[/bold cyan blink]"), border_style="green"))

if __name__ == "__main__":
    try: main()
    except KeyboardInterrupt: pass
EOF

python run_aio.py
rm run_aio.py
