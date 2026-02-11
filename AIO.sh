#!/data/data/com.termux/files/usr/bin/bash

# ==============================================================================
# BOOTLOADER: CÀI ĐẶT MÔI TRƯỜNG & THƯ VIỆN CẦN THIẾT
# ==============================================================================
clear
echo -e "\033[1;36m[>] Initializing Cyberpunk UI Environment...\033[0m"

# 1. Update & Cài Python
if ! command -v python >/dev/null 2>&1; then
    pkg install python -y >/dev/null 2>&1
fi

# 2. Cài thư viện (Requests để tải, Rich để làm màu)
pip install rich requests psutil pyfiglet --no-cache-dir --quiet >/dev/null 2>&1

# ==============================================================================
# MAIN PYTHON SCRIPT (v4.0 - MEDIAFIRE AUTO-GET LINK)
# ==============================================================================
cat <<EOF > run_aio.py
import os
import sys
import time
import subprocess
import shutil
import requests
import re # Dùng Regex để tìm link
import psutil
import platform

# RICH IMPORTS
from rich.console import Console
from rich.panel import Panel
from rich.layout import Layout
from rich.live import Live
from rich.table import Table
from rich.align import Align
from rich.progress import Progress, SpinnerColumn, BarColumn, TextColumn, TransferSpeedColumn, TimeRemainingColumn
from rich import box

# --- CẤU HÌNH ---
console = Console()
DOWNLOAD_DIR = "/sdcard/Download/auto_apk_root"
TOOL_URL = "https://raw.githubusercontent.com/FuzyTVSadBoy/setup/refs/heads/main/OldShouko.py"

# ==============================================================================
# [QUAN TRỌNG] HÃY DÁN LINK GỐC (PERMANENT LINK) CỦA 3 FILE BẠN MUỐN VÀO ĐÂY
# Link phải có dạng: https://www.mediafire.com/file/xxxx/ten_file/file
# ==============================================================================
TARGET_LINKS = [
    "https://www.mediafire.com/file/x5b9678xq6ut13d/DeltaGlobalCloneByCherry+1-2.706.750.apk/file",
    "https://www.mediafire.com/file/wyz9r4nwjbssnwg/DeltaGlobalCloneByCherry+2-2.706.750.apk/file",
    "https://www.mediafire.com/file/dsrr6vxd35l63j8/DeltaGlobalCloneByCherry+3-2.706.750.apk/file"
]

# --- HÀM HỆ THỐNG ---
def run_cmd(command, shell=True):
    try:
        subprocess.run(command, shell=shell, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return True
    except:
        return False

def get_sys_info():
    uname = platform.uname()
    ram = psutil.virtual_memory()
    return f"[bold cyan]OS:[/bold cyan] Android {uname.release} | [bold cyan]RAM:[/bold cyan] {ram.percent}% Used"

# --- HÀM LẤY DIRECT LINK MEDIAFIRE (NEW FEATURE) ---
def get_mediafire_direct_link(url):
    try:
        headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'}
        session = requests.Session()
        response = session.get(url, headers=headers)
        
        if response.status_code != 200:
            return None
        
        # Dùng Regex để tìm link trong thẻ <a id="downloadButton">
        match = re.search(r'href="((http|https)://download[^"]+)', response.text)
        if match:
            return match.group(1)
        return None
    except Exception as e:
        return None

# --- UI COMPONENTS ---
def make_header():
    try: import pyfiglet; title = pyfiglet.figlet_format("UGPHONE", font="slant")
    except: title = "UGPHONE AIO"
    return Panel(
        Align.center(f"[bold magenta]{title}[/bold magenta]\n[white]Auto-Get Mediafire Link v4.0[/white]"),
        box=box.ROUNDED, border_style="cyan"
    )

def create_job_table(jobs):
    table = Table(expand=True, box=box.SIMPLE_HEAVY, border_style="dim white")
    table.add_column("ID", justify="center", style="cyan", width=4)
    table.add_column("Task Name", style="white")
    table.add_column("Status", justify="right")
    for job in jobs:
        status_style = "dim"; status_icon = "..."
        if job["status"] == "running": status_style = "bold yellow"; status_icon = "🔄"
        elif job["status"] == "done": status_style = "bold green"; status_icon = "✅"
        elif job["status"] == "error": status_style = "bold red"; status_icon = "❌"
        table.add_row(str(job["id"]), job["name"], f"[{status_style}]{status_icon}[/{status_style}]")
    return Panel(table, title="[bold yellow]TASK MANAGER[/bold yellow]", border_style="yellow")

# --- MAIN LOGIC ---
def main():
    jobs = [
        {"id": 1, "name": "System & Storage Config", "status": "pending"},
        {"id": 2, "name": "Generate Mediafire Keys", "status": "pending"},
        {"id": 3, "name": "Download Core Tool", "status": "pending"},
        {"id": 4, "name": "Root & Device ID", "status": "pending"},
    ]

    layout = Layout()
    layout.split(Layout(name="header", size=8), Layout(name="body"), Layout(name="footer", size=3))
    layout["header"].update(make_header())
    layout["footer"].update(Panel(Align.center(get_sys_info()), style="blue"))

    # KHỞI TẠO CÁC LINK TẢI THỰC TẾ
    REAL_DOWNLOAD_LINKS = []

    with Live(layout, refresh_per_second=10, screen=True):
        # JOB 1
        jobs[0]["status"] = "running"; layout["body"].update(create_job_table(jobs))
        home_storage = "/data/data/com.termux/files/home/storage"
        if os.path.exists(home_storage): shutil.rmtree(home_storage, ignore_errors=True)
        run_cmd("termux-setup-storage"); time.sleep(1)
        jobs[0]["status"] = "done"; layout["body"].update(create_job_table(jobs))

        # JOB 2: GET MEDIAFIRE LINK (QUAN TRỌNG)
        jobs[1]["status"] = "running"; layout["body"].update(create_job_table(jobs))
        jobs[1]["name"] = "Generating Fresh Keys..." # Đổi tên task cho ngầu
        
        for link in TARGET_LINKS:
            direct_link = get_mediafire_direct_link(link)
            if direct_link:
                REAL_DOWNLOAD_LINKS.append(direct_link)
            else:
                # Nếu không lấy được link, thử dùng link gốc (hên xui)
                REAL_DOWNLOAD_LINKS.append(link)
        
        if len(REAL_DOWNLOAD_LINKS) > 0:
            jobs[1]["status"] = "done"
        else:
            jobs[1]["status"] = "error"
        layout["body"].update(create_job_table(jobs))

        # JOB 3
        jobs[2]["status"] = "running"; layout["body"].update(create_job_table(jobs))
        dest = "/sdcard/Download/OldShouko.py"
        try:
            r = requests.get(TOOL_URL, timeout=10)
            if r.status_code == 200:
                with open(dest, 'wb') as f: f.write(r.content)
                jobs[2]["status"] = "done"
            else: jobs[2]["status"] = "error"
        except: jobs[2]["status"] = "error"
        layout["body"].update(create_job_table(jobs))

        # JOB 4
        jobs[3]["status"] = "running"; layout["body"].update(create_job_table(jobs))
        try:
            subprocess.check_call(['su', '-c', 'id'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            run_cmd(f'su -c "settings put secure android_id f43f5764ee3f616a"')
            run_cmd('su -c "wm density 200"')
            jobs[3]["status"] = "done"
        except: jobs[3]["status"] = "error"
        layout["body"].update(create_job_table(jobs))

    # --- DOWNLOADER SECTION ---
    console.clear(); console.print(make_header())
    console.print(Panel("[bold cyan]DOWNLOADING 3 CLONES...[/bold cyan]", border_style="cyan"))
    
    if os.path.exists(DOWNLOAD_DIR): shutil.rmtree(DOWNLOAD_DIR)
    os.makedirs(DOWNLOAD_DIR)

    progress = Progress(
        SpinnerColumn(style="bold magenta"),
        TextColumn("[bold cyan]{task.fields[filename]}", justify="left"),
        BarColumn(style="magenta", complete_style="bold cyan"),
        "[progress.percentage]{task.percentage:>3.0f}%",
        TransferSpeedColumn(),
        TimeRemainingColumn(),
        console=console
    )

    with progress:
        for url in REAL_DOWNLOAD_LINKS:
            # Lấy tên file gốc từ URL (Decode để tránh lỗi ký tự lạ)
            try:
                if "/file/" in url: # Nếu là link gốc chưa direct
                    filename = url.split('/')[-2] # Lấy tên từ url gốc
                else:
                    filename = url.split('/')[-1] # Lấy tên từ url direct
            except:
                filename = f"App_Clone_{int(time.time())}.apk"
            
            # Làm sạch tên file
            if "?" in filename: filename = filename.split("?")[0]
            if not filename.endswith(".apk"): filename += ".apk"
            
            display_name = (filename[:20] + '..') if len(filename) > 20 else filename
            dest_path = os.path.join(DOWNLOAD_DIR, filename)

            task_id = progress.add_task("dl", filename=display_name, total=None)
            
            try:
                response = requests.get(url, stream=True, timeout=30, headers={'User-Agent': 'Mozilla/5.0'})
                total_size = int(response.headers.get('content-length', 0))
                progress.update(task_id, total=total_size)
                
                with open(dest_path, 'wb') as f:
                    for chunk in response.iter_content(chunk_size=8192):
                        if chunk:
                            f.write(chunk)
                            progress.update(task_id, advance=len(chunk))
                
                # Check Size
                if os.path.getsize(dest_path) < 10 * 1024 * 1024:
                    os.remove(dest_path)
                    console.print(f"[red]⚠ SKIP (Error/Small File): {filename}[/red]")

            except Exception as e:
                console.print(f"[red]Download Fail: {filename}[/red]")

    # --- INSTALLER SECTION ---
    console.clear(); console.print(make_header())
    
    files = [f for f in os.listdir(DOWNLOAD_DIR) if f.endswith(".apk")]
    install_data = []

    def build_table():
        table = Table(title="[bold yellow]INSTALLATION QUEUE[/bold yellow]", expand=True, box=box.ROUNDED)
        table.add_column("APK Name", style="white")
        table.add_column("Status", style="dim")
        table.add_column("Result", justify="right")
        for row in install_data: table.add_row(*row)
        return table

    if not files:
        console.print(Panel("[bold red]NO VALID APK FILES DOWNLOADED![/bold red]", border_style="red"))
    else:
        with Live(build_table(), refresh_per_second=4, console=console) as live:
            for apk in files:
                short_name = (apk[:25] + '..') if len(apk) > 25 else apk
                full_path = os.path.join(DOWNLOAD_DIR, apk)
                
                install_data.append([short_name, "Installing...", "⏳"])
                live.update(build_table())
                
                try: os.chmod(full_path, 0o644)
                except: pass
                
                cmd = f'su -c "pm install -r \\"{full_path}\\""'
                if run_cmd(cmd):
                    install_data[-1][1] = "[bold green]Done[/bold green]"
                    install_data[-1][2] = "[bold green]SUCCESS[/bold green]"
                else:
                    install_data[-1][1] = "[red]Error[/red]"
                    install_data[-1][2] = "[bold red]FAIL[/bold red]"
                
                live.update(build_table())
                time.sleep(0.5)

    console.print(Panel("[bold yellow blink]REBOOT DEVICE NOW![/bold yellow blink]", border_style="red"))

if __name__ == "__main__":
    try: main()
    except KeyboardInterrupt: pass
EOF

python run_aio.py
rm run_aio.py
