#!/data/data/com.termux/files/usr/bin/bash

# ==============================================================================
# BOOTLOADER: RESET TERMINAL & INIT
# ==============================================================================
stty sane
clear
echo -e "\033[1;32m[>] Initializing UGPHONE STABLE v8.0...\033[0m"

# Cài đặt Python và Thư viện
if ! command -v python >/dev/null 2>&1; then
    pkg install python -y >/dev/null 2>&1
fi
pip install rich requests psutil prettytable --no-cache-dir --quiet >/dev/null 2>&1

# ==============================================================================
# MAIN PYTHON SCRIPT (v8.0 STABLE BUFFER)
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
from rich.console import Console
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
# HÀM HỆ THỐNG
# ==============================================================================

def run_cmd(command, timeout=20):
    """Chạy lệnh shell an toàn với timeout"""
    try:
        result = subprocess.run(command, shell=True, capture_output=True, text=True, timeout=timeout)
        return result
    except: return None

def get_file_status(filename):
    """Kiểm tra file đã tải chưa"""
    path = os.path.join(DOWNLOAD_DIR, filename)
    if os.path.exists(path):
        size_mb = os.path.getsize(path) / (1024 * 1024)
        if size_mb > 20: 
            return True, f"{size_mb:.2f} MB"
    return False, "Missing"

def download_file_simple(url, path):
    """Tải file đơn giản (dùng cho OldShouko.py)"""
    try:
        r = requests.get(url, timeout=15)
        with open(path, 'wb') as f:
            f.write(r.content)
        return True
    except: return False

def get_ip():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except: return "Unknown"

# ==============================================================================
# UI GENERATORS (HÀM VẼ GIAO DIỆN)
# ==============================================================================

def make_layout():
    """Tạo khung xương giao diện"""
    layout = Layout()
    layout.split(
        Layout(name="header", size=3),
        Layout(name="info", size=6),
        Layout(name="body")
    )
    return layout

def get_header():
    """Header đơn giản, không vỡ"""
    return Panel(Align.center("[bold magenta]UGPHONE AIO v8.0 (Stable Buffer)[/bold magenta]"), style="magenta", box=box.HEAVY)

def get_info():
    """Bảng thông tin hệ thống"""
    uname = platform.uname()
    ram = psutil.virtual_memory()
    disk = psutil.disk_usage('/')
    
    grid = Table.grid(expand=True, padding=(0, 2))
    grid.add_column(style="cyan", justify="right")
    grid.add_column(style="white")
    grid.add_column(style="cyan", justify="right")
    grid.add_column(style="white")
    
    grid.add_row("Device:", uname.machine, "IP:", get_ip())
    grid.add_row("Android:", uname.release, "Storage:", f"{disk.percent}% Free")
    grid.add_row("RAM:", f"{ram.percent}% Used", "Root:", "YES" if os.getuid()==0 else "NO")
    
    return Panel(grid, title="[yellow]SYSTEM DIAGNOSTICS[/yellow]", border_style="blue")

def generate_table(title, headers, data):
    """Hàm tạo bảng dữ liệu"""
    table = Table(title=f"[bold yellow]{title}[/bold yellow]", expand=True, box=box.ROUNDED, border_style="green")
    for h in headers: table.add_column(h)
    for row in data: table.add_row(*row)
    return table

# ==============================================================================
# MAIN LOGIC
# ==============================================================================
def main():
    layout = make_layout()
    layout["header"].update(get_header())
    layout["info"].update(get_info())
    layout["body"].update(Panel(Align.center("Starting...")))

    # --- KHẮC PHỤC LỖI NHẤP NHÁY: DÙNG SCREEN=TRUE ---
    with Live(layout, refresh_per_second=4, screen=True):
        
        # ==================================
        # PHASE 1: SYSTEM PREP & TOOL DL
        # ==================================
        tasks = [
            {"name": "Check Root Access", "cmd": 'su -c "id"', "status": "Pending"},
            {"name": "Spoof Device ID", "cmd": 'su -c "settings put secure android_id f43f5764ee3f616a"', "status": "Pending"},
            {"name": "Set Density 200", "cmd": 'su -c "wm density 200"', "status": "Pending"},
            {"name": "Init Directory", "cmd": f"mkdir -p {DOWNLOAD_DIR}", "status": "Pending"},
            {"name": "Get OldShouko.py", "action": "dl_tool", "status": "Pending"}
        ]
        
        for i, task in enumerate(tasks):
            tasks[i]["status"] = "[yellow]Processing...[/yellow]"
            
            # Cập nhật bảng UI
            rows = [[t["name"], t["status"]] for t in tasks]
            layout["body"].update(generate_table("SYSTEM INITIALIZATION", ["Task", "Status"], rows))
            
            # Thực thi logic
            if task.get("action") == "dl_tool":
                if download_file_simple(TOOL_URL, TOOL_PATH):
                    tasks[i]["status"] = "[green]Saved ✅[/green]"
                else:
                    tasks[i]["status"] = "[red]Failed ❌[/red]"
            else:
                run_cmd(task["cmd"], timeout=5)
                tasks[i]["status"] = "[green]Done ✅[/green]"
            
            time.sleep(0.2)
        
        time.sleep(1)

        # ==================================
        # PHASE 2: FILE CHECK & DOWNLOAD
        # ==================================
        file_map = []
        for idx, url in enumerate(TARGET_LINKS):
            fname = f"Delta_Clone_ByCherry_{idx+1}.apk"
            exists, size = get_file_status(fname)
            file_map.append({
                "url": url, 
                "name": fname, 
                "path": os.path.join(DOWNLOAD_DIR, fname), 
                "exists": exists, 
                "size_str": size
            })

        # Hiện bảng Check
        check_rows = [[x["name"], x["size_str"], "[green]Ready[/green]" if x["exists"] else "[red]Missing[/red]"] for x in file_map]
        layout["body"].update(generate_table("FILE INTEGRITY CHECK", ["File", "Size", "Status"], check_rows))
        time.sleep(2)

        # Bắt đầu tải (nếu thiếu)
        to_download = [x for x in file_map if not x["exists"]]
        
        if to_download:
            # Tạo Progress Bar
            prog = Progress(
                SpinnerColumn(), TextColumn("[bold blue]{task.fields[filename]}"), 
                BarColumn(bar_width=None, style="dim", complete_style="green"), 
                "[progress.percentage]{task.percentage:>3.0f}%", FileSizeColumn(), TransferSpeedColumn()
            )
            
            # Gán Progress Bar vào layout body
            layout["body"].update(Panel(prog, title="[yellow]DOWNLOADING ASSETS[/yellow]", border_style="cyan"))
            
            dl_tasks = []
            for item in to_download:
                tid = prog.add_task("dl", filename=item["name"], total=None)
                dl_tasks.append((tid, item))
            
            for tid, item in dl_tasks:
                try:
                    res = requests.get(item["url"], stream=True, timeout=30)
                    total = int(res.headers.get('content-length', 0))
                    prog.update(tid, total=total)
                    
                    with open(item["path"], 'wb') as f:
                        for chunk in res.iter_content(32768):
                            if chunk:
                                f.write(chunk)
                                prog.update(tid, advance=len(chunk))
                except:
                    prog.console.print(f"[red]Failed: {item['name']}[/red]")
        else:
            layout["body"].update(Panel(Align.center("[bold green]ALL FILES CACHED. SKIPPING DOWNLOAD.[/bold green]"), border_style="green"))
            time.sleep(1)

        # ==================================
        # PHASE 3: INSTALLATION TABLE
        # ==================================
        # Khởi tạo trạng thái
        inst_states = [{"name": x["name"], "act": "Waiting", "res": "..."} for x in file_map]
        
        def render_inst():
            rows = [[s["name"], s["act"], s["res"]] for s in inst_states]
            return generate_table("INSTALLATION QUEUE", ["APK Package", "Current Action", "Result"], rows)

        layout["body"].update(render_inst())

        for i, item in enumerate(file_map):
            tmp_path = "/data/data/com.termux/files/home/temp_inst.apk"
            
            # Action 1: Clone
            inst_states[i]["act"] = "[yellow]Cloning to Internal...[/yellow]"
            layout["body"].update(render_inst())
            
            try:
                shutil.copyfile(item["path"], tmp_path)
            except:
                inst_states[i]["act"] = "[red]Copy Error[/red]"
                continue

            # Action 2: Install
            inst_states[i]["act"] = "[magenta]Installing...[/magenta]"
            layout["body"].update(render_inst())
            
            res = run_cmd(f'su -c "pm install -r {tmp_path}"', timeout=60)
            
            # Result
            if res and ("Success" in res.stdout or "Success" in res.stderr):
                inst_states[i]["act"] = "[green]Finished[/green]"
                inst_states[i]["res"] = "[bold green]SUCCESS ✅[/bold green]"
            else:
                inst_states[i]["act"] = "[red]Failed[/red]"
                inst_states[i]["res"] = "[bold red]ERROR ❌[/bold red]"
            
            if os.path.exists(tmp_path): os.remove(tmp_path)
            
            layout["body"].update(render_inst())
            time.sleep(0.5)

    # ==================================
    # EXIT SCREEN
    # ==================================
    console.clear()
    console.print(get_header())
    console.print(Panel(Align.center("[bold green]ALL TASKS COMPLETED![/bold green]\n[dim]Reboot your device to apply changes.[/dim]"), border_style="green"))

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        pass
    finally:
        # FIX LỖI MẤT CHỮ TRONG TERMINAL
        os.system("stty sane")
EOF

# CHẠY SCRIPT
python run_aio.py

# Dọn dẹp
rm run_aio.py

# Fix terminal lần cuối
stty sane
