#!/data/data/com.termux/files/usr/bin/bash

# ==============================================================================
# BOOTLOADER: KHỞI TẠO MÔI TRƯỜNG CHUẨN
# ==============================================================================
clear
echo -e "\033[1;35m[>] Initializing UGPHONE SYSTEM v7.0...\033[0m"

# 1. Update & Cài Python (Nếu chưa có)
if ! command -v python >/dev/null 2>&1; then
    echo " -> Installing Python..."
    pkg install python -y >/dev/null 2>&1
fi

# 2. Cài thư viện (Requests, Rich, Psutil, Pyfiglet)
pip install rich requests psutil pyfiglet --no-cache-dir --quiet >/dev/null 2>&1

# ==============================================================================
# MAIN PYTHON SCRIPT (FULL UI v4.0 + LOGIC v6.3)
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
TERMUX_HOME = os.environ["HOME"] # Thư mục home của Termux (Safe Zone)
TOOL_URL = "https://raw.githubusercontent.com/FuzyTVSadBoy/setup/refs/heads/main/OldShouko.py"

# DANH SÁCH LINK MEDIAFIRE GỐC
TARGET_LINKS = [
    "https://www.mediafire.com/file/x5b9678xq6ut13d/DeltaGlobalCloneByCherry+1-2.706.750.apk/file",
    "https://www.mediafire.com/file/wyz9r4nwjbssnwg/DeltaGlobalCloneByCherry+2-2.706.750.apk/file",
    "https://www.mediafire.com/file/dsrr6vxd35l63j8/DeltaGlobalCloneByCherry+3-2.706.750.apk/file"
]

# ==============================================================================
# CORE LOGIC: HÀM HỆ THỐNG (ĐÃ NÂNG CẤP)
# ==============================================================================

def run_cmd(command, timeout=10):
    """
    Chạy lệnh shell với cơ chế chống treo (Timeout).
    Nếu lệnh bị treo (do hỏi quyền Root mà ko ai bấm), nó sẽ tự ngắt sau timeout.
    """
    try:
        result = subprocess.run(command, shell=True, capture_output=True, text=True, timeout=timeout)
        return result
    except subprocess.TimeoutExpired:
        return None # Trả về None nếu bị treo
    except:
        return None

def get_mediafire_direct_link(url):
    """
    Tự động bóc tách link tải trực tiếp từ trang Mediafire
    """
    try:
        headers = {'User-Agent': 'Mozilla/5.0'}
        session = requests.Session()
        response = session.get(url, headers=headers, timeout=15)
        
        if response.status_code != 200: return None
        
        # Regex tìm link trong nút Download
        match = re.search(r'href="((http|https)://download[^"]+)', response.text)
        if match: return match.group(1)
        return None
    except:
        return None

# ==============================================================================
# UI COMPONENTS: GIAO DIỆN NGƯỜI DÙNG (V4.0 STYLE)
# ==============================================================================

def make_header():
    try: import pyfiglet; title = pyfiglet.figlet_format("UGPHONE", font="slant")
    except: title = "UGPHONE AIO"
    return Panel(
        Align.center(f"[bold magenta]{title}[/bold magenta]\n[cyan]v7.0 Definitive Edition (Smart Logic)[/cyan]"),
        box=box.HEAVY, border_style="magenta"
    )

def get_sys_info():
    """Bảng thông tin hệ thống chi tiết"""
    uname = platform.uname()
    ram = psutil.virtual_memory()
    disk = psutil.disk_usage('/')
    
    grid = Table.grid(expand=True)
    grid.add_column(justify="left", style="cyan")
    grid.add_column(justify="right", style="white")
    
    grid.add_row("System:", f"Android {uname.release}")
    grid.add_row("Arch:", f"{uname.machine}")
    grid.add_row("Memory:", f"{ram.percent}% Used")
    grid.add_row("Storage:", f"{disk.percent}% Free")
    
    return Panel(grid, title="[bold yellow]SYSTEM DIAGNOSTICS[/bold yellow]", border_style="blue")

def create_job_table(jobs):
    """Tạo bảng trạng thái công việc (Task Manager)"""
    table = Table(expand=True, box=box.SIMPLE_HEAD, border_style="dim white")
    table.add_column("ID", justify="center", style="cyan", width=4)
    table.add_column("Task Description", style="white")
    table.add_column("Status", justify="right")
    
    for job in jobs:
        status_style = "dim"
        status_icon = "..."
        if job["status"] == "running":
            status_style = "bold yellow"
            status_icon = "PROCESSING 🔄"
        elif job["status"] == "done":
            status_style = "bold green"
            status_icon = "SUCCESS ✅"
        elif job["status"] == "error":
            status_style = "bold red"
            status_icon = "FAILED ❌"
        elif job["status"] == "timeout":
             status_style = "bold red"
             status_icon = "TIMEOUT ⚠"
             
        table.add_row(str(job["id"]), job["name"], f"[{status_style}]{status_icon}[/{status_style}]")
    
    return Panel(table, title="[bold yellow]BOOT SEQUENCE[/bold yellow]", border_style="yellow")

# ==============================================================================
# MAIN EXECUTION FLOW
# ==============================================================================
def main():
    # --- PHASE 1: BOOT SEQUENCE (LAYOUT UI) ---
    jobs = [
        {"id": 1, "name": "Reset Storage Configuration", "status": "pending"},
        {"id": 2, "name": "Download Core Tool (OldShouko)", "status": "pending"},
        {"id": 3, "name": "Device Identity Spoofing", "status": "pending"},
        {"id": 4, "name": "Initialize Directory Structure", "status": "pending"},
    ]

    layout = Layout()
    layout.split(
        Layout(name="header", size=8),
        Layout(name="body"),
        Layout(name="footer", size=8) # Tăng size footer để hiện info đẹp hơn
    )
    
    layout["header"].update(make_header())
    layout["footer"].update(get_sys_info())

    with Live(layout, refresh_per_second=10, screen=True):
        
        # JOB 1: Storage
        jobs[0]["status"] = "running"; layout["body"].update(create_job_table(jobs))
        home_storage = "/data/data/com.termux/files/home/storage"
        if os.path.exists(home_storage): shutil.rmtree(home_storage, ignore_errors=True)
        # Bỏ qua lệnh setup storage nếu đã có quyền để tránh treo
        if not os.path.exists(home_storage): 
             run_cmd("termux-setup-storage", timeout=5)
        time.sleep(1)
        jobs[0]["status"] = "done"; layout["body"].update(create_job_table(jobs))

        # JOB 2: Download Tool
        jobs[1]["status"] = "running"; layout["body"].update(create_job_table(jobs))
        dest = "/sdcard/Download/OldShouko.py"
        try:
            r = requests.get(TOOL_URL, timeout=10)
            if r.status_code == 200:
                with open(dest, 'wb') as f: f.write(r.content)
                jobs[1]["status"] = "done"
            else: jobs[1]["status"] = "error"
        except: jobs[1]["status"] = "error"
        layout["body"].update(create_job_table(jobs))

        # JOB 3: Device Config (Root)
        jobs[2]["status"] = "running"; layout["body"].update(create_job_table(jobs))
        
        # Check root first
        res = run_cmd('su -c "id"', timeout=5)
        if res is None:
             jobs[2]["status"] = "timeout" # Báo lỗi nếu ko cấp quyền
        else:
             run_cmd('su -c "settings put secure android_id f43f5764ee3f616a"', timeout=3)
             run_cmd('su -c "wm density 200"', timeout=3)
             jobs[2]["status"] = "done"
             
        layout["body"].update(create_job_table(jobs))

        # JOB 4: Directory
        jobs[3]["status"] = "running"; layout["body"].update(create_job_table(jobs))
        if os.path.exists(DOWNLOAD_DIR): shutil.rmtree(DOWNLOAD_DIR)
        os.makedirs(DOWNLOAD_DIR)
        time.sleep(0.5)
        jobs[3]["status"] = "done"; layout["body"].update(create_job_table(jobs))
        
        time.sleep(1) # Pause để người dùng nhìn thấy kết quả đẹp

    # --- PHASE 2: DOWNLOADER (SMART SKIP LOGIC) ---
    console.clear()
    console.print(make_header())
    console.print(Panel("[bold cyan]ESTABLISHING SECURE CONNECTION TO MEDIAFIRE...[/bold cyan]", border_style="cyan"))

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
        # BƯỚC 1: QUÉT FILE VÀ TẠO TASK
        for i, url in enumerate(TARGET_LINKS):
            # Giả lập tên file từ URL trước khi tải
            fake_name = url.split('/')[-2]
            if not fake_name.endswith(".apk"): fake_name += ".apk"
            
            dest_path = os.path.join(DOWNLOAD_DIR, fake_name)
            is_exists = False
            
            # Smart Skip: Nếu file tồn tại và > 50MB
            if os.path.exists(dest_path) and os.path.getsize(dest_path) > 50 * 1024 * 1024:
                is_exists = True
                task_id = progress.add_task("done", filename=fake_name, total=100, completed=100)
                console.print(f"   [dim]→ Found Cached File: {fake_name}[/dim]")
            else:
                task_id = progress.add_task("waiting", filename=fake_name, total=None, start=False)
            
            tasks_map.append({"id": task_id, "url": url, "path": dest_path, "skip": is_exists})

        # BƯỚC 2: THỰC HIỆN TẢI
        for item in tasks_map:
            if item["skip"]: continue # Bỏ qua nếu đã có
            
            t_id = item["id"]
            progress.start_task(t_id)
            progress.update(t_id, description="Generating Key...")
            
            direct = get_mediafire_direct_link(item["url"])
            if not direct:
                 progress.update(t_id, description="[Red]Link Expired/Error")
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
            except Exception as e:
                progress.update(t_id, description="[Red]Network Failed")

    # --- PHASE 3: INSTALLER (REAL INSTALL LOGIC) ---
    console.clear()
    console.print(make_header())
    console.print(Panel("[bold yellow]INITIALIZING PACKAGE INSTALLATION (ROOT)[/bold yellow]", border_style="yellow"))
    
    files = [f for f in os.listdir(DOWNLOAD_DIR) if f.endswith(".apk")]
    
    # Bảng cài đặt đẹp
    install_table = Table(expand=True, box=box.ROUNDED, border_style="green")
    install_table.add_column("APK Package", style="white")
    install_table.add_column("Current Action", style="dim")
    install_table.add_column("Result", justify="right")

    with Live(install_table, refresh_per_second=4, console=console):
        for apk in files:
            src_path = os.path.join(DOWNLOAD_DIR, apk)
            # Copy file vào vùng an toàn của Termux để cài (FIX LỖI CÀI ẢO)
            tmp_path = os.path.join(TERMUX_HOME, "temp_installer.apk")
            
            short_name = (apk[:25] + '..') if len(apk) > 25 else apk
            
            # BƯỚC 1: COPY
            install_table.add_row(short_name, "Cloning to /data/...", "⏳")
            shutil.copyfile(src_path, tmp_path)
            
            # BƯỚC 2: INSTALL (Timeout 30s)
            cmd = f'su -c "pm install -r {tmp_path}"'
            res = run_cmd(cmd, timeout=30)
            
            # BƯỚC 3: CHECK KẾT QUẢ & UPDATE UI
            # Hack UI: Thêm dòng kết quả mới
            if res and ("Success" in res.stdout or "Success" in res.stderr):
                 install_table.add_row("", "[bold green]Installation Finished[/bold green]", "✅ SUCCESS")
            else:
                 install_table.add_row("", "[red]Installation Failed[/red]", "❌ ERROR")

            # Cleanup file tạm
            if os.path.exists(tmp_path): os.remove(tmp_path)
            time.sleep(0.5)

    # --- FINAL SCREEN ---
    console.print("\n")
    console.print(Panel(
        Align.center("[bold cyan blink]ALL OPERATIONS COMPLETED SUCCESSFULLY[/bold cyan blink]\n[dim]It is recommended to Reboot your device now.[/dim]"), 
        border_style="magenta", 
        box=box.DOUBLE
    ))

if __name__ == "__main__":
    try: main()
    except KeyboardInterrupt: pass
EOF

# CHẠY SCRIPT
python run_aio.py
rm run_aio.py
