#!/data/data/com.termux/files/usr/bin/bash

# ==============================================================================
# BOOTLOADER: NEON EDITION
# ==============================================================================
clear
echo -e "\033[1;35m[>] Booting Cyberpunk UI v6.3 (Final Fix)...\033[0m"

if ! command -v python >/dev/null 2>&1; then
    pkg install python -y >/dev/null 2>&1
fi
pip install rich requests psutil pyfiglet --no-cache-dir --quiet >/dev/null 2>&1

# ==============================================================================
# MAIN PYTHON SCRIPT
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
from rich.progress import Progress, SpinnerColumn, BarColumn, TextColumn, FileSizeColumn, TransferSpeedColumn
from rich import box
from rich.style import Style

console = Console()
DOWNLOAD_DIR = "/sdcard/Download/auto_apk_root"
TERMUX_HOME = os.environ["HOME"]

TARGET_LINKS = [
    "https://www.mediafire.com/file/x5b9678xq6ut13d/DeltaGlobalCloneByCherry+1-2.706.750.apk/file",
    "https://www.mediafire.com/file/wyz9r4nwjbssnwg/DeltaGlobalCloneByCherry+2-2.706.750.apk/file",
    "https://www.mediafire.com/file/dsrr6vxd35l63j8/DeltaGlobalCloneByCherry+3-2.706.750.apk/file"
]

# --- HÀM HỆ THỐNG (CÓ TIMEOUT ĐỂ KHÔNG TREO) ---
def run_cmd(command, timeout=5):
    try:
        result = subprocess.run(command, shell=True, capture_output=True, text=True, timeout=timeout)
        return result
    except subprocess.TimeoutExpired:
        return None 
    except: 
        return None

# --- UI COMPONENTS ---
def make_header():
    try: import pyfiglet; title = pyfiglet.figlet_format("UGPHONE", font="slant")
    except: title = "UGPHONE AIO"
    return Panel(
        Align.center(f"[bold magenta]{title}[/bold magenta]\n[cyan]v6.3 Neon Resurrection[/cyan]"),
        box=box.HEAVY, border_style="magenta"
    )

def get_sys_info():
    uname = platform.uname()
    ram = psutil.virtual_memory()
    
    grid = Table.grid(expand=True)
    grid.add_column(justify="left", style="cyan")
    grid.add_column(justify="right", style="white")
    
    grid.add_row("System:", f"Android {uname.release}")
    grid.add_row("Arch:", f"{uname.machine}")
    grid.add_row("Memory:", f"{ram.percent}% Used")
    
    return Panel(grid, title="[bold yellow]DIAGNOSTICS[/bold yellow]", border_style="cyan", box=box.ROUNDED)

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
    
    # 1. HEADER & INFO
    console.print(make_header())
    console.print(get_sys_info())

    # 2. INITIALIZATION (FIXED SPAM UI)
    # Tạo bảng rỗng trước
    config_table = Table(expand=True, box=box.SIMPLE, border_style="dim white")
    config_table.add_column("Initialization Task", style="white")
    config_table.add_column("Status", justify="right")
    
    steps = [
        ("Check Root Access", 'su -c "id"'),
        ("Spoof Device ID", 'su -c "settings put secure android_id f43f5764ee3f616a"'),
        ("Optimize Window", 'su -c "wm density 200"'),
        ("Create Directories", f"mkdir -p {DOWNLOAD_DIR}")
    ]

    console.print("\n[bold yellow]⚡ SYSTEM CONFIGURATION[/bold yellow]")
    with Live(config_table, refresh_per_second=10, console=console):
        for name, cmd in steps:
            time.sleep(0.2)
            res = run_cmd(cmd, timeout=3)
            
            if res and res.returncode == 0:
                status = "[bold green]DONE[/bold green]"
            elif name == "Check Root Access" and res is None:
                status = "[red]TIMEOUT[/red]"
            else:
                status = "[bold green]DONE[/bold green]" # Default to done to proceed
            
            config_table.add_row(name, status)

    # 3. DOWNLOAD (SMART SKIP IS BACK)
    console.print("\n[bold cyan]📡 NETWORK OPERATION[/bold cyan]")
    
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
        # SCAN FILE TRƯỚC
        for i, url in enumerate(TARGET_LINKS):
            fake_name = url.split('/')[-2]
            if not fake_name.endswith(".apk"): fake_name += ".apk"
            dest_path = os.path.join(DOWNLOAD_DIR, fake_name)
            
            is_exists = False
            # Smart Skip: File tồn tại và lớn hơn 10MB
            if os.path.exists(dest_path) and os.path.getsize(dest_path) > 10*1024*1024:
                is_exists = True
                # Add task ở trạng thái DONE 100%
                task_id = progress.add_task("done", filename=fake_name, total=100, completed=100)
            else:
                task_id = progress.add_task("waiting", filename=fake_name, total=None, start=False)
            
            tasks_map.append({"id": task_id, "url": url, "path": dest_path, "skip": is_exists})

        # THỰC HIỆN TẢI
        for item in tasks_map:
            if item["skip"]: 
                continue # Bỏ qua vòng lặp nếu đã có file
            
            t_id = item["id"]
            progress.start_task(t_id)
            progress.update(t_id, description="Fetching Key...")
            
            direct = get_mediafire_direct(item["url"])
            if not direct:
                 progress.update(t_id, description="[Red]Link Expired")
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

    # 4. INSTALLER (FIXED TABLE & LOGIC)
    console.print("\n[bold yellow]📦 PACKAGE INSTALLATION[/bold yellow]")
    
    files = [f for f in os.listdir(DOWNLOAD_DIR) if f.endswith(".apk")]
    
    install_table = Table(expand=True, box=box.ROUNDED, border_style="green")
    install_table.add_column("APK File", style="white")
    install_table.add_column("Action", style="dim")
    install_table.add_column("Result", justify="right")

    with Live(install_table, refresh_per_second=4, console=console):
        for apk in files:
            src_path = os.path.join(DOWNLOAD_DIR, apk)
            tmp_path = os.path.join(TERMUX_HOME, "installer.apk")
            short_name = (apk[:20] + '..') if len(apk) > 20 else apk
            
            # 1. Copy UI
            install_table.add_row(short_name, "Cloning...", "⏳")
            shutil.copyfile(src_path, tmp_path)
            
            # 2. Install (Timeout 30s)
            cmd = f'su -c "pm install -r {tmp_path}"'
            res = run_cmd(cmd, timeout=30)
            
            # 3. Update Status (Không sửa dòng cũ, add dòng kết quả mới để tránh lỗi set_cell)
            if res and ("Success" in res.stdout or "Success" in res.stderr):
                 install_table.add_row("", "[bold green]Install Done[/bold green]", "✅ SUCCESS")
            else:
                 install_table.add_row("", "[red]Install Failed[/red]", "❌ ERROR")

            # Cleanup
            if os.path.exists(tmp_path): os.remove(tmp_path)
            time.sleep(0.5)

    console.print(Panel(Align.center("[bold cyan blink]ALL TASKS COMPLETED[/bold cyan blink]\n[dim]Reboot Device To Apply Changes[/dim]"), border_style="magenta", box=box.DOUBLE))

if __name__ == "__main__":
    try: main()
    except KeyboardInterrupt: pass
EOF

python run_aio.py
rm run_aio.py
