#!/data/data/com.termux/files/usr/bin/bash

# ==============================================================================
# BOOTLOADER: KHÔI PHỤC TERMINAL & CÀI ĐẶT
# ==============================================================================
stty sane
clear
echo -e "\033[1;33m[>] Initializing UGPHONE v8.1 (Lag-Proof)...\033[0m"

if ! command -v python >/dev/null 2>&1; then
    pkg install python -y >/dev/null 2>&1
fi
pip install rich requests psutil prettytable pytz --no-cache-dir --quiet >/dev/null 2>&1

# ==============================================================================
# MAIN PYTHON SCRIPT (v8.1 STABLE LOW-REFRESH)
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

# RICH IMPORTS
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

TARGET_LINKS = [
    "https://pixeldrain.com/api/file/qTMZ8NVA?download",
    "https://pixeldrain.com/api/file/bcccMBDy?download",
    "https://pixeldrain.com/api/file/eohaWnEh?download"
]

# ==============================================================================
# HÀM HỆ THỐNG
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
    return False, "Missing"

def download_file_simple(url, path):
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
# UI GENERATORS (STATIC - NO FLICKER)
# ==============================================================================

def make_layout():
    """Tạo bộ khung Layout cố định"""
    layout = Layout()
    layout.split(
        Layout(name="header", size=3),
        Layout(name="info", size=6),
        Layout(name="body")
    )
    # Khởi tạo nội dung mặc định ngay lập tức để tránh hiện chữ 'Layout'
    layout["header"].update(Panel(Align.center("[bold magenta]UGPHONE AIO v8.1 (Lag-Proof)[/bold magenta]"), style="magenta", box=box.HEAVY))
    layout["info"].update(Panel(Align.center("Loading System Info..."), border_style="blue"))
    layout["body"].update(Panel(Align.center("[yellow]Please Wait...[/yellow]"), border_style="white"))
    return layout

def update_info_panel(layout):
    """Cập nhật bảng Info 1 lần duy nhất"""
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
    
    layout["info"].update(Panel(grid, title="[yellow]SYSTEM DIAGNOSTICS[/yellow]", border_style="blue"))

def generate_table(title, headers, data):
    table = Table(title=f"[bold yellow]{title}[/bold yellow]", expand=True, box=box.ROUNDED, border_style="green")
    for h in headers: table.add_column(h)
    for row in data: table.add_row(*row)
    return table

# ==============================================================================
# MAIN LOGIC
# ==============================================================================
def main():
    # Không dùng console.clear() ở đây để tránh chớp màn hình đen
    layout = make_layout()
    
    # REFRESH RATE = 2 (Cập nhật 2 lần/giây - Rất chậm để tránh Lag)
    with Live(layout, refresh_per_second=2, screen=True):
        
        # Cập nhật Info Panel lần đầu
        update_info_panel(layout)
        
        # ==================================
        # PHASE 1: SYSTEM PREP
        # ==================================
        tasks = [
            {"name": "Check Root Access", "cmd": 'su -c "id"', "status": "Pending"},
            {"name": "Spoof Device ID", "cmd": 'su -c "settings put secure android_id f43f5764ee3f616a"', "status": "Pending"},
            {"name": "Set Density 200", "cmd": 'su -c "wm density 200"', "status": "Pending"},
            {"name": "Init Directory", "cmd": f"mkdir -p {DOWNLOAD_DIR}", "status": "Pending"},
            {"name": "Get OldShouko.py", "action": "dl_tool", "status": "Pending"}
        ]
        
        for i, task in enumerate(tasks):
            tasks[i]["status"] = "[yellow]Running...[/yellow]"
            
            # Cập nhật UI
            rows = [[t["name"], t["status"]] for t in tasks]
            layout["body"].update(generate_table("SYSTEM INITIALIZATION", ["Task", "Status"], rows))
            
            # Logic
            if task.get("action") == "dl_tool":
                if download_file_simple(TOOL_URL, TOOL_PATH):
                    tasks[i]["status"] = "[green]Saved ✅[/green]"
                else:
                    tasks[i]["status"] = "[red]Failed ❌[/red]"
            else:
                run_cmd(task["cmd"], timeout=5)
                tasks[i]["status"] = "[green]Done ✅[/green]"
            
            time.sleep(0.5) # Sleep lâu hơn để mắt kịp nhìn và mạng kịp tải
        
        time.sleep(1)

        # ==================================
        # PHASE 2: FILE CHECK
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

        check_rows = [[x["name"], x["size_str"], "[green]Ready[/green]" if x["exists"] else "[red]Missing[/red]"] for x in file_map]
        layout["body"].update(generate_table("FILE INTEGRITY CHECK", ["File", "Size", "Status"], check_rows))
        time.sleep(3)

        # ==================================
        # PHASE 3: DOWNLOAD
        # ==================================
        to_download = [x for x in file_map if not x["exists"]]
        
        if to_download:
            prog = Progress(
                SpinnerColumn(), TextColumn("[bold blue]{task.fields[filename]}"), 
                BarColumn(bar_width=None, style="dim", complete_style="green"), 
                "[progress.percentage]{task.percentage:>3.0f}%", FileSizeColumn(), TransferSpeedColumn()
            )
            
            layout["body"].update(Panel(prog, title="[yellow]DOWNLOADING FROM PIXELDRAIN[/yellow]", border_style="cyan"))
            
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
            time.sleep(2)

        # ==================================
        # PHASE 4: INSTALLATION
        # ==================================
        inst_states = [{"name": x["name"], "act": "Waiting", "res": "..."} for x in file_map]
        
        def render_inst():
            rows = [[s["name"], s["act"], s["res"]] for s in inst_states]
            return generate_table("INSTALLATION QUEUE", ["APK Package", "Action", "Result"], rows)

        layout["body"].update(render_inst())

        for i, item in enumerate(file_map):
            tmp_path = "/data/data/com.termux/files/home/temp_inst.apk"
            
            inst_states[i]["act"] = "[yellow]Cloning...[/yellow]"
            layout["body"].update(render_inst())
            
            try: shutil.copyfile(item["path"], tmp_path)
            except: 
                inst_states[i]["act"] = "[red]Error[/red]"
                continue

            inst_states[i]["act"] = "[magenta]Installing...[/magenta]"
            layout["body"].update(render_inst())
            
            res = run_cmd(f'su -c "pm install -r {tmp_path}"', timeout=60)
            
            if res and ("Success" in res.stdout or "Success" in res.stderr):
                inst_states[i]["act"] = "[green]Done[/green]"
                inst_states[i]["res"] = "[bold green]SUCCESS ✅[/bold green]"
            else:
                inst_states[i]["act"] = "[red]Fail[/red]"
                inst_states[i]["res"] = "[bold red]ERROR ❌[/bold red]"
            
            if os.path.exists(tmp_path): os.remove(tmp_path)
            
            layout["body"].update(render_inst())
            time.sleep(1) # Sleep 1s mỗi lần cài xong để không bị nhảy

    # Exit
    console.clear()
    console.print(layout["header"])
    console.print(Panel(Align.center("[bold green]ALL DONE. REBOOT NOW.[/bold green]"), border_style="green"))

if __name__ == "__main__":
    try: main()
    except: pass
    finally: os.system("stty sane")
EOF

python run_aio.py
rm run_aio.py
os.system("stty sane")
