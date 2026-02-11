#!/data/data/com.termux/files/usr/bin/bash

# ==============================================================================
# BOOTLOADER: KHỞI TẠO MÔI TRƯỜNG
# ==============================================================================
clear
echo -e "\033[1;36m[>] Booting Dynamic Dashboard v7.2...\033[0m"

if ! command -v python >/dev/null 2>&1; then
    echo " -> Installing Python..."
    pkg install python -y >/dev/null 2>&1
fi
pip install rich requests psutil pyfiglet --no-cache-dir --quiet >/dev/null 2>&1

# ==============================================================================
# MAIN PYTHON SCRIPT (v7.2 DYNAMIC LAYOUT)
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
import socket
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
    path = os.path.join(DOWNLOAD_DIR, filename)
    if os.path.exists(path):
        size_mb = os.path.getsize(path) / (1024 * 1024)
        if size_mb > 20: 
            return True, f"{size_mb:.1f} MB"
    return False, "0 MB"

def get_ip_address():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except: return "127.0.0.1"

# ==============================================================================
# UI COMPONENTS
# ==============================================================================

def make_header():
    try: import pyfiglet; title = pyfiglet.figlet_format("UGPHONE", font="slant")
    except: title = "UGPHONE AIO"
    return Panel(
        Align.center(f"[bold magenta]{title}[/bold magenta]\n[cyan]v7.2 Dynamic Dashboard[/cyan]"),
        box=box.HEAVY, border_style="magenta"
    )

def make_info_panel():
    """Tạo bảng Info gọn gàng, 2 cột để không bị trống"""
    uname = platform.uname()
    ram = psutil.virtual_memory()
    disk = psutil.disk_usage('/')
    
    # Grid 2 cột
    grid = Table.grid(expand=True, padding=(0, 2))
    grid.add_column(justify="right", style="cyan")
    grid.add_column(justify="left", style="white")
    grid.add_column(justify="right", style="cyan")
    grid.add_column(justify="left", style="white")
    
    # Dòng 1
    grid.add_row("System:", f"Android {uname.release}", "IP Addr:", get_ip_address())
    # Dòng 2
    grid.add_row("Arch:", f"{uname.machine}", "Storage:", f"{disk.percent}% Free")
    # Dòng 3
    grid.add_row("Memory:", f"{ram.percent}% Used", "Root:", "Checked" if os.getuid() == 0 else "Unchecked")

    return Panel(grid, title="[bold yellow]SYSTEM INFO[/bold yellow]", border_style="blue", padding=(0,1))

def create_table_ui(title, columns, data):
    """Hàm tạo bảng chung cho mọi tác vụ"""
    table = Table(expand=True, box=box.ROUNDED, border_style="green", title=f"[bold yellow]{title}[/bold yellow]")
    for col_name, style, justify in columns:
        table.add_column(col_name, style=style, justify=justify)
    
    for row in data:
        table.add_row(*row)
    return table

# ==============================================================================
# MAIN LOGIC
# ==============================================================================
def main():
    console.clear()
    
    # --- LAYOUT SETUP ---
    # Header và Info cố định, Body thay đổi
    layout = Layout()
    layout.split(
        Layout(name="header", size=8),
        Layout(name="info", size=5), # Thu nhỏ lại cho gọn
        Layout(name="body")
    )
    
    layout["header"].update(make_header())
    layout["info"].update(make_info_panel())

    # Bắt đầu Live Render
    with Live(layout, refresh_per_second=10, screen=True):
        
        # ---------------------------------------------------------
        # PHASE 1: SYSTEM INIT (TABLE)
        # ---------------------------------------------------------
        init_steps = [
            {"name": "Root Permission", "cmd": 'su -c "id"', "status": "Pending"},
            {"name": "Spoof Device ID", "cmd": 'su -c "settings put secure android_id f43f5764ee3f616a"', "status": "Pending"},
            {"name": "Set Density 200", "cmd": 'su -c "wm density 200"', "status": "Pending"},
            {"name": "Init Storage", "cmd": f"mkdir -p {DOWNLOAD_DIR}", "status": "Pending"},
        ]
        
        # Định nghĩa cột cho bảng Init
        init_cols = [("Task Name", "white", "left"), ("Status", "right", "right")]

        for i, step in enumerate(init_steps):
            # Render bảng hiện tại
            rows = [[s["name"], s["status"]] for s in init_steps]
            layout["body"].update(create_table_ui("SYSTEM INITIALIZATION", init_cols, rows))
            
            # Chạy lệnh
            init_steps[i]["status"] = "[yellow]Running...[/yellow]"
            rows = [[s["name"], s["status"]] for s in init_steps]
            layout["body"].update(create_table_ui("SYSTEM INITIALIZATION", init_cols, rows))
            
            run_cmd(step["cmd"], timeout=3)
            
            # Cập nhật xong
            init_steps[i]["status"] = "[bold green]DONE ✅[/bold green]"
            time.sleep(0.2)
        
        time.sleep(1) # Dừng 1 xíu để người dùng thấy Done hết

        # ---------------------------------------------------------
        # PHASE 2: FILE CHECK (TABLE) - Bảng cũ tự mất do update layout
        # ---------------------------------------------------------
        file_map = []
        for url in TARGET_LINKS:
            fake_name = url.split('/')[-2]
            if not fake_name.endswith(".apk"): fake_name += ".apk"
            exists, size_str = get_file_status(fake_name)
            file_map.append({"url": url, "name": fake_name, "exists": exists, "size": size_str, "path": os.path.join(DOWNLOAD_DIR, fake_name)})

        # Tạo dữ liệu bảng Check
        check_cols = [("APK File", "white", "left"), ("Size", "cyan", "center"), ("Status", "bold", "right")]
        check_rows = []
        for item in file_map:
            status = "[green]Ready[/green]" if item["exists"] else "[red]Missing[/red]"
            check_rows.append([item["name"], item["size"], status])
        
        layout["body"].update(create_table_ui("FILE INTEGRITY CHECK", check_cols, check_rows))
        time.sleep(2) # Cho người dùng đọc kết quả check

        # ---------------------------------------------------------
        # PHASE 3: DOWNLOAD (TABLE + PROGRESS)
        # ---------------------------------------------------------
        to_download = [x for x in file_map if not x["exists"]]
        
        if to_download:
            # Tạo Progress Bar tùy chỉnh
            progress = Progress(
                SpinnerColumn(), 
                TextColumn("[bold blue]{task.fields[filename]}"), 
                BarColumn(bar_width=None, style="dim", complete_style="bold green"), 
                "[progress.percentage]{task.percentage:>3.0f}%", 
                TransferSpeedColumn(), 
                expand=True
            )
            
            # Nhúng Progress Bar vào một Panel để trông giống Table
            dl_panel = Panel(progress, title="[bold yellow]DOWNLOADING ASSETS[/bold yellow]", border_style="cyan")
            layout["body"].update(dl_panel) # Thay thế bảng Check bằng bảng Download
            
            dl_tasks = []
            for item in to_download:
                tid = progress.add_task("dl", filename=item["name"], total=None)
                dl_tasks.append((tid, item))
            
            for tid, item in dl_tasks:
                direct = get_mediafire_direct(item["url"])
                if direct:
                    try:
                        res = requests.get(direct, stream=True, timeout=20)
                        total = int(res.headers.get('content-length', 0))
                        progress.update(tid, total=total)
                        with open(item["path"], 'wb') as f:
                            for chunk in res.iter_content(32768):
                                f.write(chunk)
                                progress.update(tid, advance=len(chunk))
                    except: progress.console.log(f"Error downloading {item['name']}")
                else:
                    progress.console.log(f"Link expired: {item['name']}")

        # ---------------------------------------------------------
        # PHASE 4: INSTALL (TABLE REALTIME UPDATE)
        # ---------------------------------------------------------
        # Khởi tạo state
        inst_states = []
        for item in file_map:
            inst_states.append({"name": item["name"][:25]+"..", "stage": "Waiting", "res": "..."})
        
        inst_cols = [("Package", "white", "left"), ("Action", "yellow", "center"), ("Result", "right", "right")]
        
        def render_inst_table():
            rows = [[s["name"], s["stage"], s["res"]] for s in inst_states]
            return create_table_ui("INSTALLATION QUEUE", inst_cols, rows)

        layout["body"].update(render_inst_table()) # Thay thế bảng Download bằng bảng Install

        for i, item in enumerate(file_map):
            src = item["path"]
            tmp = os.path.join(TERMUX_HOME, "inst.apk")
            
            # Step 1: Clone
            inst_states[i]["stage"] = "Cloning..."
            layout["body"].update(render_inst_table())
            try: shutil.copyfile(src, tmp)
            except: pass
            
            # Step 2: Install
            inst_states[i]["stage"] = "Installing..."
            layout["body"].update(render_inst_table())
            
            res = run_cmd(f'su -c "pm install -r {tmp}"', timeout=45)
            
            # Step 3: Result
            inst_states[i]["stage"] = "Finished"
            if res and "Success" in (res.stdout + res.stderr):
                inst_states[i]["res"] = "[bold green]SUCCESS ✅[/bold green]"
            else:
                inst_states[i]["res"] = "[bold red]FAILED ❌[/bold red]"
            
            if os.path.exists(tmp): os.remove(tmp)
            layout["body"].update(render_inst_table())
            time.sleep(0.5)

    # --- FINAL SCREEN ---
    console.clear()
    console.print(make_header())
    console.print(make_info_panel())
    console.print(Panel(Align.center("[bold green blink]ALL TASKS COMPLETED SUCCESSFULLY![/bold green blink]"), border_style="green"))
    console.print(Align.center("[dim]You may restart your device now.[/dim]"))

if __name__ == "__main__":
    try: main()
    except KeyboardInterrupt: pass
EOF

python run_aio.py
rm run_aio.py
