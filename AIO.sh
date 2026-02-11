#!/data/data/com.termux/files/usr/bin/bash

# ==============================================================================
# BOOTLOADER: INIT
# ==============================================================================
stty sane
clear
echo -e "\033[1;36m[>] Initializing UGPHONE v8.2 (Static Install)...\033[0m"

if ! command -v python >/dev/null 2>&1; then
    pkg install python -y >/dev/null 2>&1
fi
pip install rich requests psutil prettytable pytz --no-cache-dir --quiet >/dev/null 2>&1

# ==============================================================================
# MAIN PYTHON SCRIPT (v8.2 MANUAL REFRESH)
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
def run_cmd(command, timeout=60):
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
# UI COMPONENTS
# ==============================================================================
def make_layout():
    layout = Layout()
    layout.split(
        Layout(name="header", size=3),
        Layout(name="info", size=6),
        Layout(name="body")
    )
    # Khởi tạo tĩnh
    layout["header"].update(Panel(Align.center("[bold magenta]UGPHONE AIO v8.2 (Static Refresh)[/bold magenta]"), style="magenta", box=box.HEAVY))
    layout["info"].update(Panel(Align.center("Loading..."), border_style="blue"))
    layout["body"].update(Panel(Align.center("[yellow]Please Wait...[/yellow]"), border_style="white"))
    return layout

def update_info_panel(layout):
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
    layout = make_layout()
    
    # QUAN TRỌNG: auto_refresh=False để tắt hoàn toàn việc tự vẽ lại
    # Chúng ta sẽ gọi live.refresh() thủ công khi cần.
    with Live(layout, auto_refresh=False, screen=True) as live:
        
        update_info_panel(layout)
        live.refresh() # Vẽ lần 1
        
        # --- PHASE 1: INIT ---
        tasks = [
            {"name": "Check Root", "cmd": 'su -c "id"', "status": "Pending"},
            {"name": "Spoof ID", "cmd": 'su -c "settings put secure android_id f43f5764ee3f616a"', "status": "Pending"},
            {"name": "Density 200", "cmd": 'su -c "wm density 200"', "status": "Pending"},
            {"name": "Init Dir", "cmd": f"mkdir -p {DOWNLOAD_DIR}", "status": "Pending"},
            {"name": "Get Tool", "action": "dl_tool", "status": "Pending"}
        ]
        
        for i, task in enumerate(tasks):
            tasks[i]["status"] = "[yellow]Running...[/yellow]"
            rows = [[t["name"], t["status"]] for t in tasks]
            layout["body"].update(generate_table("SYSTEM PREP", ["Task", "Status"], rows))
            live.refresh() # Cập nhật UI
            
            if task.get("action") == "dl_tool":
                if download_file_simple(TOOL_URL, TOOL_PATH):
                    tasks[i]["status"] = "[green]OK ✅[/green]"
                else:
                    tasks[i]["status"] = "[red]Fail ❌[/red]"
            else:
                run_cmd(task["cmd"], timeout=5)
                tasks[i]["status"] = "[green]OK ✅[/green]"
            
            rows = [[t["name"], t["status"]] for t in tasks]
            layout["body"].update(generate_table("SYSTEM PREP", ["Task", "Status"], rows))
            live.refresh() # Cập nhật UI sau khi xong
            time.sleep(0.2)
        
        time.sleep(1)

        # --- PHASE 2: CHECK FILES ---
        file_map = []
        for idx, url in enumerate(TARGET_LINKS):
            fname = f"Delta_Clone_ByCherry_{idx+1}.apk"
            exists, size = get_file_status(fname)
            file_map.append({"url": url, "name": fname, "path": os.path.join(DOWNLOAD_DIR, fname), "exists": exists, "size": size})

        check_rows = [[x["name"], x["size"], "[green]Ready[/green]" if x["exists"] else "[red]Missing[/red]"] for x in file_map]
        layout["body"].update(generate_table("FILE CHECK", ["File", "Size", "Status"], check_rows))
        live.refresh()
        time.sleep(2)

        # --- PHASE 3: DOWNLOAD ---
        to_download = [x for x in file_map if not x["exists"]]
        if to_download:
            # Riêng phần Download bật auto_refresh tạm thời để thanh loading chạy mượt
            live.auto_refresh = True 
            
            prog = Progress(
                SpinnerColumn(), TextColumn("[bold blue]{task.fields[filename]}"), 
                BarColumn(style="dim", complete_style="green"), 
                "[progress.percentage]{task.percentage:>3.0f}%", FileSizeColumn(), TransferSpeedColumn()
            )
            layout["body"].update(Panel(prog, title="[yellow]DOWNLOADING[/yellow]", border_style="cyan"))
            
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
                except: pass
            
            live.auto_refresh = False # Tắt lại auto_refresh trước khi vào Install
        else:
            layout["body"].update(Panel(Align.center("[bold green]ALL FILES CACHED[/bold green]"), border_style="green"))
            live.refresh()
            time.sleep(1)

        # --- PHASE 4: INSTALLATION (NO FLICKER ZONE) ---
        inst_states = [{"name": x["name"], "act": "Waiting", "res": "..."} for x in file_map]
        
        def render_inst():
            rows = [[s["name"], s["act"], s["res"]] for s in inst_states]
            layout["body"].update(generate_table("INSTALLATION QUEUE", ["APK", "Action", "Result"], rows))
            live.refresh() # Chỉ vẽ lại khi gọi hàm này

        render_inst()

        for i, item in enumerate(file_map):
            tmp_path = "/data/data/com.termux/files/home/temp_inst.apk"
            
            # 1. Copy
            inst_states[i]["act"] = "[yellow]Cloning...[/yellow]"
            render_inst() # Vẽ lại UI
            
            try: shutil.copyfile(item["path"], tmp_path)
            except: 
                inst_states[i]["act"] = "[red]Error[/red]"
                render_inst()
                continue

            # 2. Install
            inst_states[i]["act"] = "[magenta]Installing...[/magenta]"
            render_inst() # Vẽ lại UI và ĐỨNG IM ở đây cho đến khi cài xong
            
            res = run_cmd(f'su -c "pm install -r {tmp_path}"', timeout=60)
            
            # 3. Result
            if res and ("Success" in res.stdout or "Success" in res.stderr):
                inst_states[i]["act"] = "[green]Done[/green]"
                inst_states[i]["res"] = "[bold green]SUCCESS[/bold green]"
            else:
                inst_states[i]["act"] = "[red]Fail[/red]"
                inst_states[i]["res"] = "[bold red]FAIL[/bold red]"
            
            if os.path.exists(tmp_path): os.remove(tmp_path)
            render_inst() # Vẽ lại kết quả
            time.sleep(0.5)

    console.clear()
    console.print(layout["header"])
    console.print(Panel(Align.center("[bold green]DONE. REBOOT NOW.[/bold green]"), border_style="green"))

if __name__ == "__main__":
    try: main()
    except: pass
    finally: os.system("stty sane")
EOF

python run_aio.py
rm run_aio.py
os.system("stty sane")
