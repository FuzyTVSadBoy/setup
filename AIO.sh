#!/data/data/com.termux/files/usr/bin/bash

# ==============================================================================
# BOOTLOADER: KIỂM TRA THƯ VIỆN (CHỈ CÀI KHI THIẾU)
# ==============================================================================
clear
echo -e "\033[1;36m[>] Initializing Smart Environment...\033[0m"

# Hàm check thư viện Python nhanh
python -c "import rich, requests, psutil, pyfiglet" >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo -e "\033[1;33m[!] Missing libraries. Installing...\033[0m"
    pip install rich requests psutil pyfiglet --no-cache-dir --quiet
else
    echo -e "\033[1;32m[✓] Libraries already installed. Skipping.\033[0m"
fi

# ==============================================================================
# MAIN PYTHON SCRIPT (v5.1 - BUG FIXES & SMART SKIP)
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
from rich.console import Console
from rich.panel import Panel
from rich.layout import Layout
from rich.live import Live
from rich.table import Table
from rich.align import Align
from rich.progress import Progress, SpinnerColumn, BarColumn, TextColumn, TransferSpeedColumn, TimeRemainingColumn
from rich import box

console = Console()
DOWNLOAD_DIR = "/sdcard/Download/auto_apk_root"
TOOL_URL = "https://raw.githubusercontent.com/FuzyTVSadBoy/setup/refs/heads/main/OldShouko.py"

# --- LINK MEDIAFIRE CŨ (NHƯ BẠN YÊU CẦU) ---
APK_LINKS = [
    "https://download2272.mediafire.com/6xz4xlxoffagKvtpi3FSD-dX6QqN8tfX6NHSRXSvn0Nz6jAZLG9V5FyYwX2Wvi0K_B6p0KjgeT1jMPN_TNoCC4Rh8WUEjDt0TtTxr2wDKu5Mdp6stol7j7nHeKHCnO1mErxTKvjDYuBESGwJ55xu_12q3yPkhXgdFPKGMCB4g6laiw/x5b9678xq6ut13d/DeltaGlobalCloneByCherry+1-2.706.750.apk.apk",
    "https://download2264.mediafire.com/vi77ssprg8bgwmO2m2X5aYfbs1FAWWQI9nw9uu5i7GNvkHkFrMWLkFSSUzMTNfmOlhIt9COFrjSzMgkqHxw-6BlyXLCvgCBOCvQUaXwC_7BeArU3NAxiSWI8zKzmubxBLMgKu-g3qjQziBA-Xsh-MEt5nNJTqjNi8qmJ55DPlXTcwA/wyz9r4nwjbssnwg/DeltaGlobalCloneByCherry+2-2.706.750.apk.apk",
    "https://download1591.mediafire.com/iqaccp5d39gg3D3f3M6x8wwD5JmsHWyBP9bWH_wQ4yQdy13TY1w8V8yXRGRC1G2I-fxz6uqIaq3jglds_LvIB1GSuL9RPMZNp1TtSHa2rhdFgHpQYSOCazn65XF2_fmuNmftAQdTIawaVEGljQ8p4Tk-a0TuvalwahVpR_MMehN7Lw/dsrr6vxd35l63j8/DeltaGlobalCloneByCherry+3-2.706.750.apk.apk"
]

def run_cmd(command):
    try:
        subprocess.run(command, shell=True, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return True
    except: return False

def make_header():
    try: import pyfiglet; title = pyfiglet.figlet_format("UGPHONE", font="slant")
    except: title = "UGPHONE AIO"
    return Panel(Align.center(f"[bold magenta]{title}[/bold magenta]\n[white]Fixed Installer & Smart Skip v5.1[/white]"), box=box.ROUNDED, border_style="cyan")

def create_job_table(jobs):
    table = Table(expand=True, box=box.SIMPLE_HEAVY, border_style="dim white")
    table.add_column("Task", style="white")
    table.add_column("Status", justify="right")
    for job in jobs:
        icon = "..."
        if job["status"] == "running": icon = "🔄"
        elif job["status"] == "done": icon = "✅"
        elif job["status"] == "skip": icon = "⏭️"
        elif job["status"] == "error": icon = "❌"
        table.add_row(job["name"], icon)
    return Panel(table, title="[bold yellow]SYSTEM CHECK[/bold yellow]", border_style="yellow")

def main():
    console.clear()
    console.print(make_header())

    # --- PHẦN 1: CẤU HÌNH HỆ THỐNG ---
    jobs = [
        {"name": "Check Storage", "status": "pending"},
        {"name": "Download Tool (OldShouko)", "status": "pending"},
        {"name": "Root & Config", "status": "pending"},
    ]
    
    with Live(create_job_table(jobs), refresh_per_second=10, console=console) as live:
        # Job 1
        jobs[0]["status"] = "running"; live.update(create_job_table(jobs))
        run_cmd("termux-setup-storage")
        jobs[0]["status"] = "done"; live.update(create_job_table(jobs))

        # Job 2 (Smart Skip)
        jobs[1]["status"] = "running"; live.update(create_job_table(jobs))
        dest = "/sdcard/Download/OldShouko.py"
        if os.path.exists(dest) and os.path.getsize(dest) > 1024:
             jobs[1]["status"] = "skip" # Đã có thì bỏ qua
        else:
            try:
                r = requests.get(TOOL_URL, timeout=10)
                if r.status_code == 200:
                    with open(dest, 'wb') as f: f.write(r.content)
                    jobs[1]["status"] = "done"
                else: jobs[1]["status"] = "error"
            except: jobs[1]["status"] = "error"
        live.update(create_job_table(jobs))

        # Job 3
        jobs[2]["status"] = "running"; live.update(create_job_table(jobs))
        try:
            subprocess.check_call(['su', '-c', 'id'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            run_cmd('su -c "settings put secure android_id f43f5764ee3f616a"')
            run_cmd('su -c "wm density 200"')
            jobs[2]["status"] = "done"
        except: jobs[2]["status"] = "error"
        live.update(create_job_table(jobs))

    # --- PHẦN 2: DOWNLOAD (FIX HIỂN THỊ 3 FILE) ---
    console.print("\n[bold cyan]📥 DOWNLOAD MANAGER[/bold cyan]")
    if not os.path.exists(DOWNLOAD_DIR): os.makedirs(DOWNLOAD_DIR)

    progress = Progress(
        SpinnerColumn(),
        TextColumn("[bold blue]{task.fields[filename]}", justify="left"),
        BarColumn(style="dim", complete_style="bold green"),
        "[progress.percentage]{task.percentage:>3.0f}%",
        TransferSpeedColumn(),
        console=console
    )

    with progress:
        # BƯỚC 1: TẠO TRƯỚC 3 TASK ĐỂ HIỂN THỊ ĐỦ UI
        task_ids = []
        for i, url in enumerate(APK_LINKS):
            filename = url.split('/')[-1]
            if filename.endswith(".apk.apk"): filename = filename[:-4]
            display_name = (filename[:20] + '..') if len(filename) > 20 else filename
            
            # Tạo task ở trạng thái chờ (total=0)
            tid = progress.add_task("waiting", filename=display_name, total=0, start=False)
            task_ids.append((tid, url, filename))

        # BƯỚC 2: XỬ LÝ TỪNG TASK
        for tid, url, filename in task_ids:
            dest_path = os.path.join(DOWNLOAD_DIR, filename)
            
            # --> CHECK SKIP: Nếu file tồn tại và > 100MB (Delta Clone thường nặng)
            if os.path.exists(dest_path):
                file_size = os.path.getsize(dest_path)
                if file_size > 50 * 1024 * 1024: # Lớn hơn 50MB coi như là file xịn
                    progress.update(tid, description=f"[yellow]Skipped (Exists)[/yellow]", total=100, completed=100)
                    continue
                else:
                    # File rác < 50MB, xóa đi tải lại
                    os.remove(dest_path)

            # --> BẮT ĐẦU TẢI
            progress.start_task(tid)
            try:
                response = requests.get(url, stream=True, timeout=30, headers={'User-Agent': 'Mozilla/5.0'})
                total_len = int(response.headers.get('content-length', 0))
                progress.update(tid, total=total_len)
                
                with open(dest_path, 'wb') as f:
                    for chunk in response.iter_content(chunk_size=8192):
                        if chunk:
                            f.write(chunk)
                            progress.update(tid, advance=len(chunk))
            except Exception as e:
                 progress.update(tid, description=f"[red]Error[/red]")

    # --- PHẦN 3: CÀI ĐẶT (FIX LỖI CÀI ẢO) ---
    console.print("\n[bold yellow]📦 INSTALLATION (INTEGRITY CHECK)[/bold yellow]")
    
    files = [f for f in os.listdir(DOWNLOAD_DIR) if f.endswith(".apk")]
    
    table = Table(box=box.SIMPLE)
    table.add_column("APK", style="white")
    table.add_column("Status", justify="right")
    table.add_column("Detail", style="dim")

    with Live(table, refresh_per_second=4, console=console) as live:
        for apk in files:
            full_path = os.path.join(DOWNLOAD_DIR, apk)
            short_name = (apk[:20] + '..') if len(apk) > 20 else apk
            
            # Check kỹ file trước khi cài
            if os.path.getsize(full_path) < 10 * 1024 * 1024:
                table.add_row(short_name, "❌ SKIP", "File Corrupted (<10MB)")
                continue

            # Fix quyền
            try: os.chmod(full_path, 0o644)
            except: pass

            # --- LỆNH CÀI ĐẶT CHUẨN (ĐỌC KẾT QUẢ TRẢ VỀ) ---
            # Sử dụng subprocess để bắt lấy output của lệnh pm install
            proc = subprocess.run(
                ['su', '-c', f'pm install -r "{full_path}"'],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )
            
            # Kiểm tra xem hệ thống có trả về chữ "Success" không
            if "Success" in proc.stdout:
                table.add_row(short_name, "[bold green]SUCCESS[/bold green]", "Installed")
            else:
                # Nếu không Success, in ra lỗi (ví dụ: Failure [INSTALL_FAILED...])
                error_msg = proc.stdout.strip() if proc.stdout else "Unknown Error"
                # Lọc bớt chữ thừa cho gọn
                clean_err = error_msg.replace("Failure [", "").replace("]", "")
                table.add_row(short_name, "[bold red]FAILED[/bold red]", clean_err)

    console.print(Panel(Align.center("[bold green]ALL DONE[/bold green]\n[dim]Reboot Recommended[/dim]"), border_style="green"))

if __name__ == "__main__":
    main()
EOF

# Chạy tool
python run_aio.py
rm run_aio.py
