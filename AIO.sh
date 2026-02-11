#!/data/data/com.termux/files/usr/bin/bash

# ==============================================================================
# BOOTLOADER: KHỞI TẠO MÔI TRƯỜNG
# ==============================================================================
clear
echo -e "\033[1;32m[>] Initializing UGPHONE MONOLITH SYSTEM v7.3...\033[0m"

if ! command -v python >/dev/null 2>&1; then
    echo " -> Installing Python..."
    pkg install python -y >/dev/null 2>&1
fi
pip install rich requests psutil pyfiglet --no-cache-dir --quiet >/dev/null 2>&1

# ==============================================================================
# MAIN PYTHON SCRIPT (v7.3 HEAVY EDITION)
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
import socket
from datetime import datetime

# RICH UI LIBRARY
from rich.console import Console
from rich.panel import Panel
from rich.layout import Layout
from rich.live import Live
from rich.table import Table
from rich.align import Align
from rich.progress import Progress, SpinnerColumn, BarColumn, TextColumn, TransferSpeedColumn, TimeRemainingColumn, FileSizeColumn
from rich import box
from rich.style import Style
from rich.group import Group

# ==============================================================================
# CONFIGURATION
# ==============================================================================
console = Console()
DOWNLOAD_DIR = "/sdcard/Download/auto_apk_root"
TERMUX_HOME = os.environ["HOME"] 
TOOL_URL = "https://raw.githubusercontent.com/FuzyTVSadBoy/setup/refs/heads/main/OldShouko.py"

# DANH SÁCH LINK MEDIAFIRE
TARGET_LINKS = [
    "https://www.mediafire.com/file/x5b9678xq6ut13d/DeltaGlobalCloneByCherry+1-2.706.750.apk/file",
    "https://www.mediafire.com/file/wyz9r4nwjbssnwg/DeltaGlobalCloneByCherry+2-2.706.750.apk/file",
    "https://www.mediafire.com/file/dsrr6vxd35l63j8/DeltaGlobalCloneByCherry+3-2.706.750.apk/file"
]

# ==============================================================================
# SYSTEM LOGIC FUNCTIONS
# ==============================================================================

def run_cmd(command, timeout=20):
    """
    Thực thi lệnh shell với timeout để tránh treo (Anti-Freeze).
    """
    try:
        result = subprocess.run(command, shell=True, capture_output=True, text=True, timeout=timeout)
        return result
    except subprocess.TimeoutExpired:
        return None
    except Exception:
        return None

def get_mediafire_direct(url):
    """
    Lấy link tải trực tiếp từ Mediafire (Bypass Key).
    """
    try:
        headers = {'User-Agent': 'Mozilla/5.0'}
        res = requests.get(url, headers=headers, timeout=15)
        # Regex tìm link trong nút Download
        match = re.search(r'href="((http|https)://download[^"]+)', res.text)
        if match:
            return match.group(1)
        return None
    except:
        return None

def get_file_status(filename):
    """
    Kiểm tra file có tồn tại và dung lượng hợp lệ (>20MB) hay không.
    """
    path = os.path.join(DOWNLOAD_DIR, filename)
    if os.path.exists(path):
        size = os.path.getsize(path)
        size_mb = size / (1024 * 1024)
        if size_mb > 20: 
            return True, f"{size_mb:.2f} MB"
        else:
            return False, f"{size_mb:.2f} MB (Too Small)"
    return False, "Missing"

def get_ip_address():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except: return "127.0.0.1"

# ==============================================================================
# UI GENERATORS (HÀM TẠO GIAO DIỆN)
# ==============================================================================

def make_header():
    try: 
        import pyfiglet
        title = pyfiglet.figlet_format("UGPHONE", font="slant")
    except: 
        title = "UGPHONE AIO"
    
    return Panel(
        Align.center(f"[bold magenta]{title}[/bold magenta]\n[cyan]v7.3 Monolith Edition (Stable UI)[/cyan]"),
        box=box.HEAVY, border_style="magenta", padding=(0, 0)
    )

def make_info_panel():
    """Tạo bảng Info đầy đủ, không bị trống"""
    uname = platform.uname()
    ram = psutil.virtual_memory()
    disk = psutil.disk_usage('/')
    
    # Grid 4 cột (Label - Value | Label - Value)
    grid = Table.grid(expand=True, padding=(0, 2))
    grid.add_column(justify="right", style="bold cyan")
    grid.add_column(justify="left", style="white")
    grid.add_column(justify="right", style="bold cyan")
    grid.add_column(justify="left", style="white")
    
    grid.add_row("OS:", f"Android {uname.release}", "IP Addr:", get_ip_address())
    grid.add_row("Arch:", f"{uname.machine}", "Storage:", f"{disk.percent}% Free")
    grid.add_row("Memory:", f"{ram.percent}% Used", "Root:", "CHECKED" if os.getuid() == 0 else "UNCHECKED")
    grid.add_row("User:", os.environ.get('USER', 'termux'), "Time:", datetime.now().strftime("%H:%M:%S"))

    return Panel(grid, title="[bold yellow]SYSTEM DIAGNOSTICS[/bold yellow]", border_style="blue")

def generate_table(title, columns, data):
    """Hàm tạo bảng tổng quát"""
    table = Table(expand=True, box=box.ROUNDED, border_style="green", title=f"[bold yellow]{title}[/bold yellow]")
    
    for col in columns:
        table.add_column(col["name"], justify=col["justify"], style=col["style"])
        
    for row in data:
        table.add_row(*row)
        
    return table

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================
def main():
    console.clear()
    
    # 1. SETUP LAYOUT
    layout = Layout()
    layout.split(
        Layout(name="header", size=8),
        Layout(name="info", size=6),
        Layout(name="body")
    )
    
    # Set nội dung tĩnh ban đầu
    layout["header"].update(make_header())
    layout["info"].update(make_info_panel())
    layout["body"].update(Panel(Align.center("[yellow]Initializing System...[/yellow]"), border_style="white"))

    # Bắt đầu Live Loop
    with Live(layout, refresh_per_second=10, screen=True):
        
        # ------------------------------------------------------------------
        # PHASE 1: SYSTEM INITIALIZATION (BẢNG INIT)
        # ------------------------------------------------------------------
        init_tasks = [
            {"name": "Check Root Privileges", "cmd": 'su -c "id"', "status": "Pending"},
            {"name": "Spoof Device Identity", "cmd": 'su -c "settings put secure android_id f43f5764ee3f616a"', "status": "Pending"},
            {"name": "Set Screen Density (200)", "cmd": 'su -c "wm density 200"', "status": "Pending"},
            {"name": "Create Download Directory", "cmd": f"mkdir -p {DOWNLOAD_DIR}", "status": "Pending"},
            {"name": "Fix Storage Permissions", "cmd": "termux-setup-storage", "status": "Pending"}
        ]
        
        init_cols = [
            {"name": "Initialization Task", "justify": "left", "style": "white"},
            {"name": "Status", "justify": "right", "style": "bold"}
        ]

        # Vòng lặp thực thi Init
        for i, task in enumerate(init_tasks):
            # Cập nhật trạng thái "Running"
            init_tasks[i]["status"] = "[yellow]Processing...[/yellow]"
            
            # Tạo data cho bảng
            rows = [[t["name"], t["status"]] for t in init_tasks]
            layout["body"].update(generate_table("SYSTEM BOOT SEQUENCE", init_cols, rows))
            
            # Chạy lệnh (nếu là setup storage thì check trước để đỡ treo)
            if "termux-setup-storage" in task["cmd"]:
                if not os.path.exists("/data/data/com.termux/files/home/storage"):
                     run_cmd(task["cmd"], timeout=5)
            else:
                run_cmd(task["cmd"], timeout=3)
            
            # Cập nhật trạng thái "Done"
            init_tasks[i]["status"] = "[green]COMPLETED ✅[/green]"
            rows = [[t["name"], t["status"]] for t in init_tasks]
            layout["body"].update(generate_table("SYSTEM BOOT SEQUENCE", init_cols, rows))
            time.sleep(0.2)

        time.sleep(1) # Pause

        # ------------------------------------------------------------------
        # PHASE 2: FILE INTEGRITY CHECK (BẢNG INVENTORY)
        # ------------------------------------------------------------------
        # Chuẩn bị dữ liệu file
        file_map = []
        for url in TARGET_LINKS:
            fake_name = url.split('/')[-2]
            if not fake_name.endswith(".apk"): fake_name += ".apk"
            exists, size_str = get_file_status(fake_name)
            file_map.append({
                "url": url,
                "name": fake_name,
                "path": os.path.join(DOWNLOAD_DIR, fake_name),
                "exists": exists,
                "size_str": size_str
            })

        # Tạo bảng Check
        check_cols = [
            {"name": "Target APK File", "justify": "left", "style": "white"},
            {"name": "Local Size", "justify": "center", "style": "cyan"},
            {"name": "Integrity", "justify": "right", "style": "bold"}
        ]
        
        check_rows = []
        for item in file_map:
            status = "[green]READY TO INSTALL[/green]" if item["exists"] else "[red]DOWNLOAD REQUIRED[/red]"
            check_rows.append([item["name"], item["size_str"], status])
        
        layout["body"].update(generate_table("FILE INTEGRITY VERIFICATION", check_cols, check_rows))
        time.sleep(3) # Cho người dùng đọc kỹ

        # ------------------------------------------------------------------
        # PHASE 3: DOWNLOAD MANAGER (PROGRESS PANEL)
        # ------------------------------------------------------------------
        files_to_download = [f for f in file_map if not f["exists"]]
        
        if files_to_download:
            # Tạo đối tượng Progress
            download_progress = Progress(
                SpinnerColumn(style="bold magenta"),
                TextColumn("[bold blue]{task.fields[filename]}"),
                BarColumn(bar_width=None, style="dim", complete_style="bold green"),
                "[progress.percentage]{task.percentage:>3.0f}%",
                FileSizeColumn(),
                TransferSpeedColumn(),
            )
            
            # Nhúng Progress vào Panel để hiển thị trong Layout
            dl_panel = Panel(download_progress, title="[bold yellow]DOWNLOADING RESOURCES[/bold yellow]", border_style="cyan")
            layout["body"].update(dl_panel)
            
            # Tạo task cho Progress bar
            dl_tasks = []
            for item in files_to_download:
                tid = download_progress.add_task("dl", filename=item["name"], total=None)
                dl_tasks.append({"tid": tid, "item": item})
            
            # Thực hiện tải
            for task_data in dl_tasks:
                tid = task_data["tid"]
                item = task_data["item"]
                
                download_progress.update(tid, description="Fetching Key...")
                direct_link = get_mediafire_direct(item["url"])
                
                if direct_link:
                    try:
                        res = requests.get(direct_link, stream=True, timeout=20)
                        total_size = int(res.headers.get('content-length', 0))
                        download_progress.update(tid, total=total_size)
                        
                        with open(item["path"], 'wb') as f:
                            for chunk in res.iter_content(chunk_size=32768):
                                if chunk:
                                    f.write(chunk)
                                    download_progress.update(tid, advance=len(chunk))
                    except:
                        download_progress.console.print(f"[red]Error downloading {item['name']}[/red]")
                else:
                    download_progress.console.print(f"[red]Link Expired: {item['name']}[/red]")
        else:
            # Nếu không cần tải gì cả
            layout["body"].update(Panel(Align.center("[bold green]ALL FILES ARE PRESENT. SKIPPING DOWNLOAD.[/bold green]"), border_style="green"))
            time.sleep(2)

        # ------------------------------------------------------------------
        # PHASE 4: INSTALLATION (REALTIME UPDATE TABLE)
        # ------------------------------------------------------------------
        # Khởi tạo trạng thái cho bảng cài đặt
        inst_states = []
        for item in file_map:
            inst_states.append({
                "name": item["name"],
                "path": item["path"],
                "stage_copy": "Waiting",
                "stage_install": "Waiting",
                "result": "..."
            })
            
        inst_cols = [
            {"name": "APK Package", "justify": "left", "style": "white"},
            {"name": "Cloning (/data)", "justify": "center", "style": "yellow"},
            {"name": "Installing (PM)", "justify": "center", "style": "magenta"},
            {"name": "Final Result", "justify": "right", "style": "bold"}
        ]

        # Hàm helper để render bảng cài đặt từ state hiện tại
        def render_install_table():
            rows = []
            for s in inst_states:
                rows.append([s["name"], s["stage_copy"], s["stage_install"], s["result"]])
            return generate_table("PACKAGE INSTALLATION QUEUE", inst_cols, rows)

        # Update lần đầu
        layout["body"].update(render_install_table())

        # Vòng lặp cài đặt
        for i, state in enumerate(inst_states):
            tmp_path = os.path.join(TERMUX_HOME, f"installer_{i}.apk")
            
            # BƯỚC 1: COPY
            inst_states[i]["stage_copy"] = "[yellow]Processing...[/yellow]"
            layout["body"].update(render_install_table())
            
            try:
                shutil.copyfile(state["path"], tmp_path)
                inst_states[i]["stage_copy"] = "[green]Done[/green]"
            except Exception as e:
                inst_states[i]["stage_copy"] = "[red]Error[/red]"
                inst_states[i]["result"] = "[red]FAILED[/red]"
                layout["body"].update(render_install_table())
                continue
            
            layout["body"].update(render_install_table())

            # BƯỚC 2: INSTALL
            inst_states[i]["stage_install"] = "[yellow]Running...[/yellow]"
            layout["body"].update(render_install_table())
            
            cmd = f'su -c "pm install -r {tmp_path}"'
            # Timeout 45s cho việc cài đặt
            res = run_cmd(cmd, timeout=45)
            
            if res and ("Success" in res.stdout or "Success" in res.stderr):
                inst_states[i]["stage_install"] = "[green]Done[/green]"
                inst_states[i]["result"] = "[bold green]SUCCESS ✅[/bold green]"
            else:
                inst_states[i]["stage_install"] = "[red]Failed[/red]"
                inst_states[i]["result"] = "[bold red]ERROR ❌[/bold red]"
            
            # Cleanup
            if os.path.exists(tmp_path): os.remove(tmp_path)
            
            layout["body"].update(render_install_table())
            time.sleep(0.5)

    # --- FINAL SCREEN ---
    console.clear()
    console.print(make_header())
    console.print(make_info_panel())
    console.print(Panel(Align.center("[bold green blink]ALL TASKS COMPLETED SUCCESSFULLY![/bold green blink]\n[dim]You may now reboot your device.[/dim]"), border_style="green", box=box.DOUBLE))

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        console.print("\n[red]User Aborted![/red]")
        sys.exit(0)
EOF

# CHẠY SCRIPT
python run_aio.py
rm run_aio.py
