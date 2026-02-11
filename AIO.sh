#!/data/data/com.termux/files/usr/bin/bash

# ==============================================================================
# BOOTLOADER: KHỞI TẠO MÔI TRƯỜNG
# ==============================================================================
clear
echo -e "\033[1;36m[>] Booting Dashboard UI v7.1...\033[0m"

if ! command -v python >/dev/null 2>&1; then
    echo " -> Installing Python..."
    pkg install python -y >/dev/null 2>&1
fi
pip install rich requests psutil pyfiglet --no-cache-dir --quiet >/dev/null 2>&1

# ==============================================================================
# MAIN PYTHON SCRIPT (v7.1 DASHBOARD EDITION)
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
from rich.layout import Layout
from rich.live import Live
from rich.table import Table
from rich.align import Align
from rich.progress import Progress, SpinnerColumn, BarColumn, TextColumn, TransferSpeedColumn, TimeRemainingColumn, FileSizeColumn
from rich import box
from rich.style import Style

# --- CẤU HÌNH ---
console = Console()
DOWNLOAD_DIR = "/sdcard/Download/auto_apk_root"
TERMUX_HOME = os.environ["HOME"] 
TOOL_URL = "https://raw.githubusercontent.com/FuzyTVSadBoy/setup/refs/heads/main/OldShouko.py"

# LINK MEDIAFIRE
TARGET_LINKS = [
    "https://www.mediafire.com/file/x5b9678xq6ut13d/DeltaGlobalCloneByCherry+1-2.706.750.apk/file",
    "https://www.mediafire.com/file/wyz9r4nwjbssnwg/DeltaGlobalCloneByCherry+2-2.706.750.apk/file",
    "https://www.mediafire.com/file/dsrr6vxd35l63j8/DeltaGlobalCloneByCherry+3-2.706.750.apk/file"
]

# ==============================================================================
# CORE LOGIC
# ==============================================================================

def run_cmd(command, timeout=15):
    try:
        result = subprocess.run(command, shell=True, capture_output=True, text=True, timeout=timeout)
        return result
    except: return None

def get_mediafire_direct(url):
    try:
        headers = {'User-Agent': 'Mozilla/5.0'}
        res = requests.get(url, headers=headers, timeout=10)
        match = re.search(r'href="((http|https)://download[^"]+)', res.text)
        return match.group(1) if match else None
    except: return None

def get_file_status(filename):
    """Kiểm tra file có tồn tại và hợp lệ không"""
    path = os.path.join(DOWNLOAD_DIR, filename)
    if os.path.exists(path):
        size_mb = os.path.getsize(path) / (1024 * 1024)
        if size_mb > 20: # File > 20MB mới coi là APK game chuẩn
            return True, f"{size_mb:.1f} MB"
    return False, "Missing"

# ==============================================================================
# UI COMPONENTS
# ==============================================================================

def make_header():
    try: import pyfiglet; title = pyfiglet.figlet_format("UGPHONE", font="slant")
    except: title = "UGPHONE AIO"
    return Panel(
        Align.center(f"[bold magenta]{title}[/bold magenta]\n[cyan]v7.1 Dashboard Edition[/cyan]"),
        box=box.HEAVY, border_style="magenta"
    )

def get_sys_info():
    uname = platform.uname()
    ram = psutil.virtual_memory()
    grid = Table.grid(expand=True)
    grid.add_column(style="cyan"); grid.add_column(justify="right", style="white")
    grid.add_row("Device:", f"{uname.machine}")
    grid.add_row("Memory:", f"{ram.percent}% Used")
    return Panel(grid, title="[bold yellow]INFO[/bold yellow]", border_style="blue")

def build_inventory_table(file_map):
    """Tạo bảng kiểm kê file"""
    table = Table(expand=True, box=box.SIMPLE_HEAD, title="[bold yellow]FILE INTEGRITY CHECK[/bold yellow]")
    table.add_column("APK Name", style="white")
    table.add_column("Local Status", justify="center")
    table.add_column("Action", justify="right")
    
    for item in file_map:
        if item['exists']:
            status = f"[green]FOUND ({item['size']})[/green]"
            action = "[dim]Install Only[/dim]"
        else:
            status = "[red]MISSING[/red]"
            action = "[bold cyan]Download Required[/bold cyan]"
        table.add_row(item['name'], status, action)
    return table

def build_install_table(install_states):
    """Tạo bảng cài đặt cập nhật realtime"""
    table = Table(expand=True, box=box.ROUNDED, border_style="green", title="[bold yellow]INSTALLATION PROCESS[/bold yellow]")
    table.add_column("Package Name", style="white")
    table.add_column("Stage 1: Cloning", justify="center")
    table.add_column("Stage 2: Installing", justify="center")
    table.add_column("Result", justify="right")
    
    for state in install_states:
        # Stage 1 UI
        if state['stage'] == 0: s1 = "[dim]-[/dim]"
        elif state['stage'] == 1: s1 = "[yellow]Copying..[/yellow]"
        else: s1 = "[green]Done[/green]"
        
        # Stage 2 UI
        if state['stage'] < 2: s2 = "[dim]-[/dim]"
        elif state['stage'] == 2: s2 = "[yellow]Running..[/yellow]"
        else: s2 = "[green]Done[/green]"
        
        # Result UI
        if state['result'] == "pending": res = "⏳"
        elif state['result'] == "success": res = "[bold green]SUCCESS ✅[/bold green]"
        else: res = "[bold red]FAILED ❌[/bold red]"
        
        table.add_row(state['name'], s1, s2, res)
    return table

# ==============================================================================
# MAIN LOGIC
# ==============================================================================
def main():
    console.clear()
    
    # --- LAYOUT SETUP ---
    layout = Layout()
    layout.split(
        Layout(name="header", size=8),
        Layout(name="info", size=5),
        Layout(name="body")
    )
    layout["header"].update(make_header())
    layout["info"].update(get_sys_info())
    
    console.print(layout["header"])
    console.print(layout["info"])

    # --- PHASE 1: CONFIGURATION ---
    with console.status("[bold yellow]Configuring System (Root/Storage)...[/bold yellow]", spinner="dots"):
        if not os.path.exists(DOWNLOAD_DIR): os.makedirs(DOWNLOAD_DIR)
        run_cmd('su -c "settings put secure android_id f43f5764ee3f616a"', 3)
        run_cmd('su -c "wm density 200"', 3)
        # Fix storage permission silently
        if not os.path.exists("/data/data/com.termux/files/home/storage"):
            run_cmd("termux-setup-storage", 5)

    # --- PHASE 2: INVENTORY CHECK (SMART DETECT) ---
    file_map = []
    # Pre-scan links to get filenames
    for url in TARGET_LINKS:
        fake_name = url.split('/')[-2]
        if not fake_name.endswith(".apk"): fake_name += ".apk"
        exists, size_str = get_file_status(fake_name)
        file_map.append({
            "url": url, 
            "name": fake_name, 
            "exists": exists, 
            "size": size_str,
            "path": os.path.join(DOWNLOAD_DIR, fake_name)
        })
    
    console.print(build_inventory_table(file_map))
    time.sleep(2) # Cho người dùng đọc bảng

    # --- PHASE 3: DOWNLOAD MANAGER ---
    # Chỉ tải những file Missing
    download_needed = [f for f in file_map if not f['exists']]
    
    if download_needed:
        console.print("\n[bold cyan]📡 STARTING DOWNLOADS[/bold cyan]")
        progress = Progress(
            SpinnerColumn(), TextColumn("[bold blue]{task.fields[filename]}"), 
            BarColumn(bar_width=None, style="dim", complete_style="bold green"), 
            "[progress.percentage]{task.percentage:>3.0f}%", 
            FileSizeColumn(), TransferSpeedColumn(), console=console
        )
        
        with progress:
            tasks = []
            # Create tasks
            for item in download_needed:
                tid = progress.add_task("dl", filename=item['name'], total=None)
                tasks.append((tid, item))
            
            # Execute tasks
            for tid, item in tasks:
                progress.update(tid, description="Getting Key...")
                direct = get_mediafire_direct(item['url'])
                
                if direct:
                    try:
                        res = requests.get(direct, stream=True, timeout=20)
                        size = int(res.headers.get('content-length', 0))
                        progress.update(tid, total=size)
                        with open(item['path'], 'wb') as f:
                            for chunk in res.iter_content(32768):
                                f.write(chunk)
                                progress.update(tid, advance=len(chunk))
                    except:
                        progress.update(tid, description="[red]Error[/red]")
                else:
                    progress.update(tid, description="[red]Link Die[/red]")
    else:
        console.print("\n[green]✓ All files are present. Skipping download.[/green]")

    # --- PHASE 4: INSTALLATION DASHBOARD (TABLE UI) ---
    console.print("\n")
    
    # Khởi tạo trạng thái cài đặt
    install_states = []
    for item in file_map:
        install_states.append({
            "name": (item['name'][:20] + '..'),
            "full_path": item['path'],
            "stage": 0, # 0: Pending, 1: Copying, 2: Installing, 3: Done
            "result": "pending"
        })

    # Chạy vòng lặp cài đặt với Live Table
    with Live(build_install_table(install_states), refresh_per_second=4, console=console) as live:
        
        for i, state in enumerate(install_states):
            tmp_path = os.path.join(TERMUX_HOME, f"install_{i}.apk")
            
            # STAGE 1: COPY
            install_states[i]['stage'] = 1
            live.update(build_install_table(install_states))
            
            try:
                shutil.copyfile(state['full_path'], tmp_path)
            except:
                install_states[i]['result'] = "error"
                live.update(build_install_table(install_states))
                continue

            # STAGE 2: INSTALL
            install_states[i]['stage'] = 2
            live.update(build_install_table(install_states))
            
            cmd = f'su -c "pm install -r {tmp_path}"'
            res = run_cmd(cmd, timeout=45) # Tăng timeout cài đặt lên 45s
            
            # RESULT
            install_states[i]['stage'] = 3
            if res and ("Success" in res.stdout or "Success" in res.stderr):
                install_states[i]['result'] = "success"
            else:
                install_states[i]['result'] = "error"
            
            # Cleanup
            if os.path.exists(tmp_path): os.remove(tmp_path)
            
            live.update(build_install_table(install_states))
            time.sleep(0.5)

    console.print(Panel("[bold green blink]ALL TASKS COMPLETED! REBOOT NOW.[/bold green blink]", border_style="green"))

if __name__ == "__main__":
    try: main()
    except KeyboardInterrupt: pass
EOF

python run_aio.py
rm run_aio.py
