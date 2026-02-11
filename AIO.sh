#!/data/data/com.termux/files/usr/bin/bash

# ==============================================================================
# BOOTLOADER: KIỂM TRA & BỎ QUA NẾU ĐÃ ĐỦ THƯ VIỆN
# ==============================================================================
clear
echo -e "\033[1;36m[>] Initializing Smart Environment...\033[0m"

# 1. Chỉ cài Python nếu chưa có
if ! command -v python >/dev/null 2>&1; then
    echo " -> Installing Python..."
    pkg install python -y >/dev/null 2>&1
fi

# 2. Check thư viện Python (Smart Check)
python -c "import rich, requests, psutil, pyfiglet" >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo " -> Missing libraries. Installing..."
    pip install rich requests psutil pyfiglet --no-cache-dir --quiet
else
    echo " -> Libraries found. Skipping install."
fi

# ==============================================================================
# MAIN PYTHON SCRIPT (v5.5 - SMART CHECK & REAL INSTALL FIX)
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
from rich.progress import Progress, SpinnerColumn, BarColumn, TextColumn, TransferSpeedColumn, TimeRemainingColumn
from rich import box

console = Console()
DOWNLOAD_DIR = "/sdcard/Download/auto_apk_root"
TERMUX_HOME = os.environ["HOME"]

# --- LINK MEDIAFIRE GỐC (TOOL SẼ TỰ TÌM LINK TẢI) ---
TARGET_LINKS = [
    "https://www.mediafire.com/file/x5b9678xq6ut13d/DeltaGlobalCloneByCherry+1-2.706.750.apk/file",
    "https://www.mediafire.com/file/wyz9r4nwjbssnwg/DeltaGlobalCloneByCherry+2-2.706.750.apk/file",
    "https://www.mediafire.com/file/dsrr6vxd35l63j8/DeltaGlobalCloneByCherry+3-2.706.750.apk/file"
]

def run_cmd(command):
    try:
        # Capture output để check lỗi cài đặt
        result = subprocess.run(command, shell=True, capture_output=True, text=True)
        return result
    except: return None

def get_mediafire_direct(url):
    """Hàm bóc tách link tải trực tiếp"""
    try:
        headers = {'User-Agent': 'Mozilla/5.0'}
        session = requests.Session()
        res = session.get(url, headers=headers)
        # Regex tìm link tải
        match = re.search(r'href="((http|https)://download[^"]+)', res.text)
        if match: return match.group(1)
    except: pass
    return None

def make_header():
    try: import pyfiglet; title = pyfiglet.figlet_format("UGPHONE", font="slant")
    except: title = "UGPHONE AIO"
    return Panel(Align.center(f"[bold magenta]{title}[/bold magenta]\n[white]Smart Fix v5.5 (Real Install)[/white]"), box=box.ROUNDED, border_style="cyan")

def main():
    console.clear()
    console.print(make_header())

    # 1. Cấu hình Device (Chạy ngầm cho gọn)
    with console.status("[bold yellow]System Check & Config...", spinner="dots"):
        run_cmd("termux-setup-storage")
        run_cmd('su -c "settings put secure android_id f43f5764ee3f616a"')
        run_cmd('su -c "wm density 200"')
        if not os.path.exists(DOWNLOAD_DIR): os.makedirs(DOWNLOAD_DIR)
        time.sleep(1)

    # 2. XỬ LÝ TẢI FILE (SMART CHECK)
    console.print("\n[bold cyan]📥 DOWNLOAD MANAGER[/bold cyan]")
    
    progress = Progress(
        SpinnerColumn(),
        TextColumn("[bold blue]{task.fields[filename]}", justify="left"),
        BarColumn(style="dim", complete_style="bold green"),
        "[progress.percentage]{task.percentage:>3.0f}%",
        TransferSpeedColumn(),
        console=console
    )

    # Tạo trước danh sách tasks để hiển thị đủ 3 dòng (Fix lỗi hiển thị thiếu)
    tasks = []
    with progress:
        # Bước 1: Khởi tạo UI cho cả 3 file
        for i, url in enumerate(TARGET_LINKS):
            # Lấy tên file dự kiến từ URL gốc
            fake_name = url.split('/')[-2]
            if not fake_name.endswith(".apk"): fake_name += ".apk"
            short_name = (fake_name[:25] + '..') if len(fake_name) > 25 else fake_name
            
            task_id = progress.add_task("waiting", filename=short_name, total=None, start=False)
            tasks.append({"id": task_id, "url": url, "name": fake_name})

        # Bước 2: Xử lý từng file
        for item in tasks:
            dest_path = os.path.join(DOWNLOAD_DIR, item["name"])
            task_id = item["id"]
            
            # --- SMART CHECK: Nếu file đã tồn tại và > 50MB -> BỎ QUA ---
            if os.path.exists(dest_path) and os.path.getsize(dest_path) > 50 * 1024 * 1024:
                progress.update(task_id, description="[Skipped] Exists", completed=100, total=100)
                progress.start_task(task_id)
                console.print(f"   [dim]→ Found {item['name']}, skipping download.[/dim]")
                continue
            
            # Nếu chưa có -> Bắt đầu tải
            progress.update(task_id, description="Get Link...", total=None)
            progress.start_task(task_id)
            
            direct_link = get_mediafire_direct(item["url"])
            if not direct_link:
                progress.update(task_id, description="[Red]Link Error!")
                continue

            try:
                # Tải file
                response = requests.get(direct_link, stream=True, timeout=30, headers={'User-Agent': 'Mozilla/5.0'})
                total_size = int(response.headers.get('content-length', 0))
                progress.update(task_id, total=total_size, description="Downloading...")
                
                with open(dest_path, 'wb') as f:
                    for chunk in response.iter_content(chunk_size=16384):
                        if chunk:
                            f.write(chunk)
                            progress.update(task_id, advance=len(chunk))
            except:
                progress.update(task_id, description="[Red]Failed!")

    # 3. CÀI ĐẶT (FIX LỖI CÀI ẢO)
    console.print("\n[bold yellow]📦 INSTALLATION (ROOT MODE)[/bold yellow]")
    
    files = [f for f in os.listdir(DOWNLOAD_DIR) if f.endswith(".apk")]
    
    # Bảng kết quả
    table = Table(box=box.SIMPLE)
    table.add_column("APK Name")
    table.add_column("Action")
    table.add_column("Result")

    with Live(table, refresh_per_second=4, console=console):
        for apk in files:
            src_path = os.path.join(DOWNLOAD_DIR, apk)
            # Copy vào vùng kín của Termux để cài (Bypass lỗi sdcard)
            tmp_path = os.path.join(TERMUX_HOME, "temp_install.apk")
            
            short_name = (apk[:20] + '..') if len(apk) > 20 else apk
            
            # Bước 1: Copy
            table.add_row(short_name, "Copying to Internal...", "⏳")
            shutil.copyfile(src_path, tmp_path)
            
            # Bước 2: Cài đặt thật
            # Xóa dòng cũ, cập nhật dòng mới
            # (Do Rich không cho sửa row cũ dễ dàng, ta add row mới cho mỗi step hành động)
            
            cmd = f'su -c "pm install -r {tmp_path}"'
            res = run_cmd(cmd)
            
            # Bước 3: Check kết quả thực tế từ Output
            if res and ("Success" in res.stdout or "Success" in res.stderr):
                table.add_row(short_name, "[bold green]Installing...[/bold green]", "[bold green]SUCCESS ✅[/bold green]")
            else:
                err_msg = "Unknown Error"
                if res: err_msg = res.stderr.strip()[:20]
                table.add_row(short_name, "[red]Install Failed[/red]", f"[red]{err_msg} ❌[/red]")
            
            # Dọn dẹp
            if os.path.exists(tmp_path): os.remove(tmp_path)
            time.sleep(0.5)

    console.print(Panel(Align.center("[bold cyan]PROCESS COMPLETED[/bold cyan]"), border_style="green"))

if __name__ == "__main__":
    try: main()
    except KeyboardInterrupt: pass
EOF

python run_aio.py
rm run_aio.py
