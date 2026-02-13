#!/data/data/com.termux/files/usr/bin/bash

# ==============================================================================
# BOOTLOADER v9.0: ANTI-BLOCK & SMART DOWNLOADER
# ==============================================================================
shopt -s checkwinsize
stty sane
clear

echo -e "\033[1;33m[>] Initializing UGPHONE v9.0 (Anti-Block)...\033[0m"

# 1. CẤU HÌNH REPO (MEOWICE - TỐC ĐỘ CAO)
if ! grep -q "meowsmp" $PREFIX/etc/apt/sources.list; then
    echo -e "\033[1;36m[+] Switching to MeowIce Mirror (VN)...\033[0m"
    cp $PREFIX/etc/apt/sources.list $PREFIX/etc/apt/sources.list.bak 2>/dev/null
    echo "deb https://mirror.meowsmp.net/termux/termux-main stable main" > $PREFIX/etc/apt/sources.list
    [ -f "$PREFIX/etc/apt/sources.list.d/root.list" ] && echo "deb https://mirror.meowsmp.net/termux/termux-root root stable" > $PREFIX/etc/apt/sources.list.d/root.list
    [ -f "$PREFIX/etc/apt/sources.list.d/x11.list" ] && echo "deb https://mirror.meowsmp.net/termux/termux-x11 x11 main" > $PREFIX/etc/apt/sources.list.d/x11.list
    apt-get update -qq
fi

# 2. CÀI ĐẶT MÔI TRƯỜNG
if ! command -v python >/dev/null 2>&1; then
    echo -e "\033[1;36m[+] Installing Python...\033[0m"
    apt-get install python -y
fi

echo -e "\033[1;36m[+] Checking Libraries...\033[0m"
pip install rich requests psutil prettytable pytz --break-system-packages --quiet || pip install rich requests psutil prettytable pytz --quiet

echo -e "\033[1;32m[OK] Launching...\033[0m"
sleep 1

# ==============================================================================
# MAIN PYTHON SCRIPT (v9.0)
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

# [LƯU Ý] NẾU PIXELDRAIN VẪN LỖI, HÃY DÙNG LINK GITHUB RELEASE
TARGET_LINKS = [
    "https://www.dropbox.com/scl/fi/3h9b51dx9ps7kio8vgcqq/DeltaGlobalCloneByCherry-1-2.706.750.apk?rlkey=9uxoj85co0bl0v8drk6lmjybq&st=ew4fw6q5&dl=1",
    "https://www.dropbox.com/scl/fi/7v9d3l9dkboq8ib12sbjg/DeltaGlobalCloneByCherry-2-2.706.750.apk?rlkey=owvcrqsn91zf2v1is8mlnw0bp&st=wdldibvv&dl=1",
    "https://www.dropbox.com/scl/fi/xi7oc77d5cp42jcrs0lfw/DeltaGlobalCloneByCherry-3-2.706.750.apk?rlkey=j2xf74h6f6xmkv54x4kldigl8&st=6q8zyrg6&dl=1"
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

def download_with_headers(url, path, progress_task=None, progress_obj=None):
    """Hàm tải file giả lập trình duyệt để vượt qua chặn"""
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Referer': 'https://pixeldrain.com/',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8'
    }
    try:
        # Allow_redirects=True để hỗ trợ link GitHub/Mediafire
        response = requests.get(url, stream=True, timeout=30, headers=headers, allow_redirects=True)
        
        if response.status_code != 200:
            return False, f"HTTP {response.status_code}"
            
        total_size = int(response.headers.get('content-length', 0))
        
        if progress_obj and progress_task:
            progress_obj.update(progress_task, total=total_size)

        with open(path, 'wb') as f:
            for chunk in response.iter_content(chunk_size=32768):
                if chunk:
                    f.write(chunk)
                    if progress_obj and progress_task:
                        progress_obj.update(progress_task, advance=len(chunk))
        return True, "OK"
    except Exception as e:
        return False, str(e)

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
    layout["header"].update(Panel(Align.center("[bold magenta]UGPHONE AIO v9.0 (Anti-Block)[/bold magenta]"), style="magenta", box=box.HEAVY))
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
                # Tải tool dùng hàm mới có Header để chắc chắn không bị chặn
                success, msg = download_with_headers(TOOL_URL, TOOL_PATH)
                if success: tasks[i]["status"] = "[green]OK[/green]"
                else: tasks[i]["status"] = f"[red]Fail: {msg}[/red]"
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

        # PHASE 3: DOWNLOAD (ANTI-BLOCK LOGIC)
        to_download = [x for x in file_map if not x["exists"]]
        if to_download:
            prog = Progress(SpinnerColumn(), TextColumn("[bold blue]{task.fields[filename]}"), BarColumn(style="dim", complete_style="green"), "[progress.percentage]{task.percentage:>3.0f}%", FileSizeColumn(), TransferSpeedColumn())
            layout["body"].update(Panel(prog, title="[yellow]DOWNLOADING (ANTI-BLOCK)[/yellow]", border_style="cyan"))
            
            # Ép Render UI trước khi tải
            live.refresh() 
            time.sleep(0.2)
            live.auto_refresh = True
            
            dl_tasks = []
            for item in to_download:
                tid = prog.add_task("dl", filename=item["name"], total=None)
                dl_tasks.append((tid, item))
            
            for tid, item in dl_tasks:
                success, msg = download_with_headers(item["url"], item["path"], tid, prog)
                if not success:
                    prog.console.print(f"[red]Failed to download {item['name']}: {msg}. Try GitHub Links![/red]")
            
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
