#!/data/data/com.termux/files/usr/bin/bash

# ==============================================================================
# BOOTLOADER: KHỞI TẠO & SỬA LỖI TERMINAL
# ==============================================================================
# Reset terminal ngay lập tức để fix lỗi mất chữ nếu lần trước bị crash
stty sane 
clear
echo -e "\033[1;32m[>] Initializing UGPHONE SYSTEM v7.5 (Repair)...\033[0m"

if ! command -v python >/dev/null 2>&1; then
    echo " -> Installing Python..."
    pkg install python -y >/dev/null 2>&1
fi
pip install rich requests psutil --no-cache-dir --quiet >/dev/null 2>&1

# ==============================================================================
# MAIN PYTHON SCRIPT (v7.5 FIXED)
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
import socket
from datetime import datetime

# RICH UI IMPORTS
from rich.console import Console, Group
from rich.panel import Panel
from rich.layout import Layout
from rich.live import Live
from rich.table import Table
from rich.align import Align
from rich.progress import Progress, SpinnerColumn, BarColumn, TextColumn, TransferSpeedColumn, FileSizeColumn
from rich import box
from rich.style import Style

# --- CẤU HÌNH ---
console = Console()
DOWNLOAD_DIR = "/sdcard/Download/auto_apk_root"
TOOL_PATH = "/sdcard/Download/OldShouko.py"
TOOL_URL = "https://raw.githubusercontent.com/FuzyTVSadBoy/setup/refs/heads/main/OldShouko.py"

# LINKS PIXELDRAIN
TARGET_LINKS = [
    "https://pixeldrain.com/api/file/qTMZ8NVA?download",
    "https://pixeldrain.com/api/file/bcccMBDy?download",
    "https://pixeldrain.com/api/file/eohaWnEh?download"
]

# ==============================================================================
# SYSTEM FUNCTIONS
# ==============================================================================

def run_cmd(command, timeout=20):
    try:
        result = subprocess.run(command, shell=True, capture_output=True, text=True, timeout=timeout)
        return result
    except: return None

def get_file_status(filename):
    path = os.path.join(DOWNLOAD_DIR, filename)
    if os.path.exists(path):
        size_mb = os.path.getsize(path) / (1024 * 1024)
        if size_mb > 20: 
            return True, f"{size_mb:.2f} MB"
        return False, f"{size_mb:.2f} MB (Error)"
    return False, "Missing"

def download_file(url, path):
    try:
        r = requests.get(url, timeout=15)
        with open(path, 'wb') as f:
            f.write(r.content)
        return True
    except: return False

# ==============================================================================
# UI HELPERS (SIMPLE & CLEAN - NO BREAKING)
# ==============================================================================

def make_header():
    # Dùng text thường thay vì Pyfiglet để tránh vỡ giao diện trên điện thoại
    grid = Table.grid(expand=True)
    grid.add_column(justify="center", ratio=1)
    grid.add_row("[bold magenta]UGPHONE AIO ULTIMATE[/bold magenta]")
    grid.add_row("[cyan]v7.5 Repair Edition (Pixeldrain)[/cyan]")
    return Panel(grid, style="magenta", box=box.HEAVY)

def make_info():
    uname = platform.uname()
    ram = psutil.virtual_memory()
    
    # Bảng Info nhỏ gọn 2 dòng
    text = f"[bold]OS:[/bold] Android {uname.release} | [bold]Arch:[/bold] {uname.machine}\n"
    text += f"[bold]RAM:[/bold] {ram.percent}% Used | [bold]Root:[/bold] {'YES' if os.getuid()==0 else 'NO'}"
    
    return Panel(Align.center(text), title="[yellow]SYSTEM INFO[/yellow]", border_style="blue", padding=(0,1))

def create_table(title, headers, rows):
    table = Table(title=f"[bold yellow]{title}[/bold yellow]", expand=True, box=box.ROUNDED, border_style="green")
    for h in headers: table.add_column(h)
    for r in rows: table.add_row(*r)
    return table

# ==============================================================================
# MAIN LOGIC
# ==============================================================================
def main():
    console.clear()
    
    # SETUP LAYOUT
    layout = Layout()
    layout.split(
        Layout(name="header", size=5),
        Layout(name="info", size=4),
        Layout(name="body")
    )
    
    layout["header"].update(make_header())
    layout["info"].update(make_info())
    layout["body"].update(Panel(Align.center("Initializing...")))

    with Live(layout, refresh_per_second=10, screen=True):
        
        # --- PHASE 1: SYSTEM PREP (Added Tool Download) ---
        tasks = [
            {"name": "Check Root", "cmd": 'su -c "id"', "status": "Pending"},
            {"name": "Spoof ID", "cmd": 'su -c "settings put secure android_id f43f5764ee3f616a"', "status": "Pending"},
            {"name": "Set Density", "cmd": 'su -c "wm density 200"', "status": "Pending"},
            {"name": "Create Dir", "cmd": f"mkdir -p {DOWNLOAD_DIR}", "status": "Pending"},
            {"name": "Download OldShouko.py", "action": "dl_tool", "status": "Pending"} # Đã thêm lại
        ]
        
        for i, task in enumerate(tasks):
            tasks[i]["status"] = "[yellow]Running...[/yellow]"
            # Render Table
            rows = [[t["name"], t["status"]] for t in tasks]
            layout["body"].update(create_table("SYSTEM INITIALIZATION", ["Task", "Status"], rows))
            
            # Logic
            if task.get("action") == "dl_tool":
                if download_file(TOOL_URL, TOOL_PATH):
                    tasks[i]["status"] = "[green]Saved ✅[/green]"
                else:
                    tasks[i]["status"] = "[red]Failed ❌[/red]"
            else:
                run_cmd(task["cmd"], timeout=5)
                tasks[i]["status"] = "[green]Done ✅[/green]"
            
            time.sleep(0.2)
        
        time.sleep(1)

        # --- PHASE 2: FILE CHECK & DOWNLOAD ---
        file_map = []
        for idx, url in enumerate(TARGET_LINKS):
            fname = f"Delta_Clone_ByCherry_{idx+1}.apk"
            exists, size = get_file_status(fname)
            file_map.append({"url": url, "name": fname, "path": os.path.join(DOWNLOAD_DIR, fname), "exists": exists, "size": size})

        # Check Table
        rows = [[item["name"], item["size"], "[green]Ready[/green]" if item["exists"] else "[red]Missing[/red]"] for item in file_map]
        layout["body"].update(create_table("FILE INTEGRITY CHECK", ["File", "Size", "Status"], rows))
        time.sleep(2)

        # Download Process
        to_dl = [x for x in file_map if not x["exists"]]
        if to_dl:
            prog = Progress(
                SpinnerColumn(), TextColumn("[bold blue]{task.fields[filename]}"), 
                BarColumn(style="dim", complete_style="green"), "[progress.percentage]{task.percentage:>3.0f}%", 
                TransferSpeedColumn()
            )
            layout["body"].update(Panel(prog, title="[yellow]DOWNLOADING[/yellow]", border_style="cyan"))
            
            dl_tasks = []
            for item in to_dl:
                tid = prog.add_task("dl", filename=item["name"], total=None)
                dl_tasks.append((tid, item))
            
            for tid, item in dl_tasks:
                try:
                    res = requests.get(item["url"], stream=True, timeout=30)
                    total = int(res.headers.get('content-length', 0))
                    prog.update(tid, total=total)
                    with open(item["path"], 'wb') as f:
                        for chunk in res.iter_content(32768):
                            f.write(chunk)
                            prog.update(tid, advance=len(chunk))
                except: pass
        else:
            layout["body"].update(Panel(Align.center("[green]Files Cached. Skipping Download.[/green]"), border_style="green"))
            time.sleep(1)

        # --- PHASE 3: INSTALL ---
        inst_states = [{"name": x["name"], "act": "Waiting", "res": "..."} for x in file_map]
        
        def render_inst():
            r = [[s["name"], s["act"], s["res"]] for s in inst_states]
            return create_table("INSTALLATION QUEUE", ["APK", "Action", "Result"], r)

        layout["body"].update(render_inst())

        for i, item in enumerate(file_map):
            tmp = "/data/data/com.termux/files/home/inst_tmp.apk"
            
            # Copy
            inst_states[i]["act"] = "[yellow]Cloning...[/yellow]"
            layout["body"].update(render_inst())
            try: shutil.copyfile(item["path"], tmp)
            except: 
                inst_states[i]["res"] = "[red]Copy Fail[/red]"
                continue

            # Install
            inst_states[i]["act"] = "[magenta]Installing...[/magenta]"
            layout["body"].update(render_inst())
            
            res = run_cmd(f'su -c "pm install -r {tmp}"', timeout=60)
            if res and "Success" in (res.stdout + res.stderr):
                inst_states[i]["act"] = "[green]Done[/green]"
                inst_states[i]["res"] = "[bold green]SUCCESS[/bold green]"
            else:
                inst_states[i]["act"] = "[red]Fail[/red]"
                inst_states[i]["res"] = "[bold red]ERROR[/bold red]"
            
            if os.path.exists(tmp): os.remove(tmp)
            layout["body"].update(render_inst())
            time.sleep(0.5)

    console.print("[bold green]ALL TASKS COMPLETED. SCRIPT EXITING.[/bold green]")

if __name__ == "__main__":
    try:
        main()
    except:
        pass
    finally:
        # CỰC KỲ QUAN TRỌNG: KHÔI PHỤC TERMINAL SAU KHI THOÁT
        # Đây là lệnh fix lỗi không hiện chữ khi gõ phím
        os.system("stty sane")
        os.system("stty echo")
        print("\033[?25h") # Hiện lại con trỏ chuột
EOF

# CHẠY SCRIPT
python run_aio.py

# Xóa file chạy xong để dọn dẹp (Tùy chọn)
# rm run_aio.py

# Đảm bảo reset lại terminal lần nữa ở cấp độ Bash
stty sane
