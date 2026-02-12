#!/data/data/com.termux/files/usr/bin/bash

# ==============================================================================
# BOOTLOADER v8.6: CÀI ĐẶT ĐẦY ĐỦ THƯ VIỆN CHO OLDSHOUKO
# ==============================================================================
shopt -s checkwinsize
stty sane
clear

echo -e "\033[1;33m[>] Initializing UGPHONE v8.6 (Full Deps)...\033[0m"

# 1. KIỂM TRA MẠNG & UPDATE NHẸ
if ! ping -c 1 google.com >/dev/null 2>&1; then
    echo -e "\033[1;31m[!] No Internet Connection!\033[0m"
else
    echo -e "\033[1;36m[+] Updating package lists...\033[0m"
    apt-get update -qq
fi

# 2. CÀI PYTHON
if ! command -v python >/dev/null 2>&1; then
    echo -e "\033[1;36m[+] Installing Python...\033[0m"
    apt-get install python -y
fi

# 3. CÀI FULL THƯ VIỆN (Rich, Requests, Psutil, PrettyTable, Pytz)
# OldShouko.py cần: prettytable, pytz
echo -e "\033[1;36m[+] Installing Python Libraries (This may take a while)...\033[0m"
pip install rich requests psutil prettytable pytz --break-system-packages --quiet || pip install rich requests psutil prettytable pytz --quiet

echo -e "\033[1;32m[OK] Environment Ready. Launching...\033[0m"
sleep 1

# ==============================================================================
# MAIN PYTHON SCRIPT (v8.6 STABLE)
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
import signal

from rich.console import Console
from rich.panel import Panel
from rich.layout import Layout
from rich.live import Live
from rich.table import Table
from rich.align import Align
from rich.progress import Progress, SpinnerColumn, BarColumn, TextColumn, TransferSpeedColumn, FileSizeColumn
from rich import box

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

# --- HỆ THỐNG ---
def handle_resize(signum, frame): pass
signal.signal(signal.SIGWINCH, handle_resize)

def run_cmd(command, timeout=60):
    try:
        return subprocess.run(command, shell=True, capture_output=True, text=True, timeout=timeout)
    except: return None

def get_file_status(filename):
    path = os.path.join(DOWNLOAD_DIR, filename)
    if os.path.exists(path):
        size_mb = os.path.getsize(path) / (1024 * 1024)
        if size_mb > 20: return True, f"{size_mb:.2f} MB"
    return False, "Missing"

def download_file_simple(url, path):
    try:
        r = requests.get(url, timeout=15)
        with open(path, 'wb') as f: f.write(r.content)
        return True
    except: return False

def get_ip():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80)); ip = s.getsockname()[0]; s.close()
        return ip
    except: return "Unknown"

# --- UI ---
def make_layout():
    layout = Layout()
    layout.split(
        Layout(name="header", size=3),
        Layout(name="info", size=7),
        Layout(name="body", ratio=1)
    )
    layout["header"].update(Panel(Align.center("[bold magenta]UGPHONE AIO v8.6 (Full Deps)[/bold magenta]"), style="magenta", box=box.HEAVY))
    layout["info"].update(Panel(Align.center("Loading..."), border_style="blue"))
    layout["body"].update(Panel(Align.center("[yellow]Starting...[/yellow]"), border_style="white"))
    return layout

def update_info_panel(layout):
    uname = platform.uname(); ram = psutil.virtual_memory(); disk = psutil.disk_usage('/')
    grid = Table.grid(expand=True, padding=(0, 1))
    grid.add_column(style="cyan", justify="right"); grid.add_column(style="white")
    grid.add_column(style="cyan", justify="right"); grid.add_column(style="white")
    grid.add_row("Dev:", uname.machine, "IP:", get_ip())
    grid.add_row("OS:", uname.release, "Space:", f"{disk.percent}% Free")
    grid.add_row("RAM:", f"{ram.percent}% Used", "Root:", "YES" if os.getuid()==0 else "NO")
    layout["info"].update(Panel(grid, title="[yellow]SYSTEM INFO[/yellow]", border_style="blue"))

def generate_table(title, headers, data):
    table = Table(title=f"[bold yellow]{title}[/bold yellow]", expand=True, box=box.ROUNDED, border_style="green")
    for h in headers: table.add_column(h)
    for row in data: table.add_row(*row)
    return table

# --- MAIN ---
def main():
    layout = make_layout()
    with Live(layout, auto_refresh=False, screen=True) as live:
        update_info_panel(layout); live.refresh()
        
        # PHASE 1: INIT
        tasks = [
            {"name": "Check Root", "cmd": 'su -c "id"', "status": "Pending"},
            {"name": "Spoof ID", "cmd": 'su -c "settings put secure android_id f43f5764ee3f616a"', "status": "Pending"},
            {"name": "Density 200", "cmd": 'su -c "wm density 200"', "status": "Pending"},
            {"name": "Init Dir", "cmd": f"mkdir -p {DOWNLOAD_DIR}", "status": "Pending"},
            {"name": "Get OldShouko.py", "action": "dl_tool", "status": "Pending"}
        ]
        
        for i, task in enumerate(tasks):
            tasks[i]["status"] = "[yellow]...[/yellow]"
            layout["body"].update(generate_table("SYSTEM PREP", ["Task", "Status"], [[t["name"], t["status"]] for t in tasks]))
            live.refresh()
            
            if task.get("action") == "dl_tool":
                if download_file_simple(TOOL_URL, TOOL_PATH): tasks[i]["status"] = "[green]OK[/green]"
                else: tasks[i]["status"] = "[red]Fail[/red]"
            else:
                run_cmd(task["cmd"], timeout=5)
                tasks[i]["status"] = "[green]OK[/green]"
            
            layout["body"].update(generate_table("SYSTEM PREP", ["Task", "Status"], [[t["name"], t["status"]] for t in tasks]))
            live.refresh(); time.sleep(0.1)
        
        time.sleep(0.5)

        # PHASE 2: CHECK
        file_map = []
        for idx, url in enumerate(TARGET_LINKS):
            fname = f"Delta_Clone_ByCherry_{idx+1}.apk"
            exists, size = get_file_status(fname)
            file_map.append({"url": url, "name": fname, "path": os.path.join(DOWNLOAD_DIR, fname), "exists": exists, "size": size})

        layout["body"].update(generate_table("FILE CHECK", ["File", "Size", "Status"], [[x["name"], x["size"], "[green]Ready[/green]" if x["exists"] else "[red]Missing[/red]"] for x in file_map]))
        live.refresh(); time.sleep(2)

        # PHASE 3: DOWNLOAD
        to_download = [x for x in file_map if not x["exists"]]
        if to_download:
            live.auto_refresh = True
            prog = Progress(SpinnerColumn(), TextColumn("[bold blue]{task.fields[filename]}"), BarColumn(style="dim", complete_style="green"), "[progress.percentage]{task.percentage:>3.0f}%", FileSizeColumn(), TransferSpeedColumn())
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
                            if chunk: f.write(chunk); prog.update(tid, advance=len(chunk))
                except: pass
            live.auto_refresh = False
        else:
            layout["body"].update(Panel(Align.center("[bold green]ALL FILES CACHED[/bold green]"), border_style="green")); live.refresh(); time.sleep(1)

        # PHASE 4: INSTALL
        inst_states = [{"name": x["name"], "act": "Waiting", "res": "..."} for x in file_map]
        def render_inst():
            layout["body"].update(generate_table("INSTALLATION QUEUE", ["APK", "Action", "Result"], [[s["name"], s["act"], s["res"]] for s in inst_states]))
            live.refresh()
        render_inst()

        for i, item in enumerate(file_map):
            tmp_path = "/data/data/com.termux/files/home/temp_inst.apk"
            inst_states[i]["act"] = "[yellow]Cloning...[/yellow]"; render_inst()
            try: shutil.copyfile(item["path"], tmp_path)
            except: inst_states[i]["act"] = "[red]Error[/red]"; render_inst(); continue

            inst_states[i]["act"] = "[magenta]Installing...[/magenta]"; render_inst()
            res = run_cmd(f'su -c "pm install -r {tmp_path}"', timeout=60)
            
            if res and ("Success" in res.stdout or "Success" in res.stderr):
                inst_states[i]["act"] = "[green]Done[/green]"; inst_states[i]["res"] = "[bold green]SUCCESS[/bold green]"
            else:
                inst_states[i]["act"] = "[red]Fail[/red]"; inst_states[i]["res"] = "[bold red]FAIL[/bold red]"
            
            if os.path.exists(tmp_path): os.remove(tmp_path)
            render_inst(); time.sleep(0.5)

    console.clear(); console.print(layout["header"])
    console.print(Panel(Align.center("[bold green]DONE. REBOOT NOW.[/bold green]"), border_style="green"))

if __name__ == "__main__":
    try: main()
    except: pass
EOF

python run_aio.py
rm run_aio.py
stty sane
