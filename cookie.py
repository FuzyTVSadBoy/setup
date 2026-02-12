import os
import sys
import time
import subprocess
import shutil
import sqlite3
import requests

# --- CẤU HÌNH ---
DEFAULT_PREFIX = "com.roblox.client"
TEMP_DIR = "temp_cookie_data"

# Link tải file mẫu (Link của bạn)
URL_COOKIES_DB = "https://raw.githubusercontent.com/FuzyTVSadBoy/setup/refs/heads/main/library/Cookies"
URL_APPSTORAGE = "https://raw.githubusercontent.com/FuzyTVSadBoy/setup/refs/heads/main/library/appStorage.json"

class Colors:
    HEADER = '\033[95m'
    BLUE = '\033[94m'
    GREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'

class ADB:
    @staticmethod
    def run(command):
        """Chạy lệnh ADB shell"""
        full_cmd = f"adb shell {command}"
        result = subprocess.run(full_cmd, shell=True, capture_output=True, text=True)
        return result.stdout.strip()

    @staticmethod
    def check_connection():
        result = subprocess.run("adb devices", shell=True, capture_output=True, text=True)
        if "device" not in result.stdout.replace("List of devices attached", "").strip():
            return False
        return True

    @staticmethod
    def root_access():
        """Cấp quyền root cho ADB"""
        subprocess.run("adb root", shell=True, stdout=subprocess.DEVNULL)
        time.sleep(1)

class CookieManager:
    def __init__(self):
        self.prefix = DEFAULT_PREFIX
        self.packages = []
        if not os.path.exists(TEMP_DIR):
            os.makedirs(TEMP_DIR)

    def set_prefix(self):
        print(f"\n{Colors.HEADER}--- CẤU HÌNH PREFIX ---{Colors.ENDC}")
        print(f"Prefix hiện tại: {Colors.BOLD}{self.prefix}{Colors.ENDC}")
        new_prefix = input("Nhập prefix mới (Enter để giữ nguyên): ").strip()
        if new_prefix:
            self.prefix = new_prefix
            print(f"{Colors.GREEN}Đã đổi prefix thành: {self.prefix}{Colors.ENDC}")

    def scan_packages(self):
        print(f"\n{Colors.BLUE}[*] Đang quét các gói có tên chứa '{self.prefix}'...{Colors.ENDC}")
        try:
            output = ADB.run(f"pm list packages | grep {self.prefix}")
            self.packages = []
            if output:
                for line in output.splitlines():
                    pkg = line.replace("package:", "").strip()
                    self.packages.append(pkg)
            
            if not self.packages:
                print(f"{Colors.FAIL}[!] Không tìm thấy gói nào khớp prefix.{Colors.ENDC}")
            else:
                print(f"{Colors.GREEN}[+] Tìm thấy {len(self.packages)} gói:{Colors.ENDC}")
                for i, pkg in enumerate(self.packages):
                    print(f"    {i+1}. {pkg}")
        except Exception as e:
            print(f"{Colors.FAIL}[!] Lỗi khi quét: {e}{Colors.ENDC}")

    def download_resources(self):
        # Kiểm tra nếu file đã có thì thôi không tải lại để tiết kiệm thời gian
        if os.path.exists(f"{TEMP_DIR}/Cookies") and os.path.exists(f"{TEMP_DIR}/appStorage.json"):
            return True

        print(f"\n{Colors.BLUE}[*] Đang tải file mẫu...{Colors.ENDC}")
        try:
            r = requests.get(URL_COOKIES_DB)
            with open(f"{TEMP_DIR}/Cookies", "wb") as f:
                f.write(r.content)
            
            r = requests.get(URL_APPSTORAGE)
            with open(f"{TEMP_DIR}/appStorage.json", "wb") as f:
                f.write(r.content)
            
            print(f"{Colors.GREEN}[+] Tải thành công!{Colors.ENDC}")
            return True
        except Exception as e:
            print(f"{Colors.FAIL}[!] Lỗi tải file: {e}{Colors.ENDC}")
            return False

    def verify_cookie(self, cookie_string):
        print(f"{Colors.BLUE}[*] Đang kiểm tra Cookie...{Colors.ENDC}")
        try:
            headers = {'Cookie': f'.ROBLOSECURITY={cookie_string}'}
            r = requests.get('https://users.roblox.com/v1/users/authenticated', headers=headers)
            if r.status_code == 200:
                user_data = r.json()
                print(f"{Colors.GREEN}[+] Cookie Live! User: {user_data.get('name')} (ID: {user_data.get('id')}){Colors.ENDC}")
                return user_data.get('id')
            else:
                print(f"{Colors.FAIL}[!] Cookie Chết hoặc không hợp lệ!{Colors.ENDC}")
                return None
        except Exception as e:
            print(f"{Colors.FAIL}[!] Lỗi kết nối API: {e}{Colors.ENDC}")
            return None

    def inject_cookie_root(self, package, cookie_string):
        """
        Inject vào /data/data/ + FIX QUYỀN SỞ HỮU (Chown)
        Đây là chìa khóa để Delta đọc được cookie.
        """
        print(f"\n{Colors.HEADER}>>> Đang Inject cho: {package}{Colors.ENDC}")
        
        # 1. Kill App
        ADB.run(f"am force-stop {package}")
        
        # 2. Xử lý file Cookie Database cục bộ
        local_db = f"{TEMP_DIR}/Cookies"
        local_json = f"{TEMP_DIR}/appStorage.json"
        
        try:
            conn = sqlite3.connect(local_db)
            cursor = conn.cursor()
            # Cập nhật Cookie vào DB
            cursor.execute("UPDATE cookies SET value = ? WHERE name = '.ROBLOSECURITY'", (cookie_string,))
            conn.commit()
            conn.close()
        except Exception as e:
            print(f"{Colors.FAIL}[!] Lỗi ghi DB SQLite: {e}{Colors.ENDC}")
            return

        # 3. Đẩy file vào thiết bị (Vào thư mục trung gian /sdcard)
        temp_remote = "/sdcard/Download"
        subprocess.run(f"adb push {local_db} {temp_remote}/Cookies_Temp", shell=True, stdout=subprocess.DEVNULL)
        subprocess.run(f"adb push {local_json} {temp_remote}/appStorage_Temp.json", shell=True, stdout=subprocess.DEVNULL)

        # 4. THỰC HIỆN ROOT INJECTION
        # Đường dẫn chuẩn của Android Data
        root_data = f"/data/data/{package}"
        dest_cookies = f"{root_data}/app_webview/Default/Cookies"
        dest_storage = f"{root_data}/files/appData/LocalStorage/appStorage.json"
        
        print(f"{Colors.BLUE}   [1/2] Copy file vào hệ thống (/data/data)...{Colors.ENDC}")
        
        cmds = [
            # Tạo thư mục (nếu chưa có)
            f"mkdir -p {root_data}/app_webview/Default/",
            f"mkdir -p {root_data}/files/appData/LocalStorage/",
            
            # Copy file từ thư mục tạm vào hệ thống
            f"cp {temp_remote}/Cookies_Temp {dest_cookies}",
            f"cp {temp_remote}/appStorage_Temp.json {dest_storage}",
            
            # Cấp quyền đọc ghi (chmod 777)
            f"chmod 777 {dest_cookies}",
            f"chmod 777 {dest_storage}",
        ]
        ADB.run("; ".join(cmds))

        # 5. FIX OWNER (QUAN TRỌNG NHẤT)
        # Lấy UID của package (Ví dụ: u0_a123)
        # Chúng ta dùng lệnh stat để xem thư mục gốc của package thuộc về ai
        # Sau đó gán quyền sở hữu file Cookie cho người đó.
        print(f"{Colors.BLUE}   [2/2] Fix quyền sở hữu (Chown)...{Colors.ENDC}")
        
        chown_cmd = f"chown $(stat -c '%U:%G' {root_data}) {dest_cookies} {dest_storage}"
        ADB.run(chown_cmd)

        print(f"{Colors.GREEN}[+] Inject hoàn tất!{Colors.ENDC}")
        
        # 6. Mở game
        print(f"{Colors.BLUE}   [>] Khởi động lại game...{Colors.ENDC}")
        ADB.run(f"am start -n {package}/com.roblox.client.startup.ActivitySplash")

    def run(self):
        print(f"{Colors.HEADER}======================================")
        print(f"   COOKIE.PY - ROOT INJECTION FIX")
        print(f"======================================{Colors.ENDC}")

        if not ADB.check_connection():
            print(f"{Colors.FAIL}[!] Không tìm thấy thiết bị ADB.{Colors.ENDC}")
            return

        ADB.root_access()

        while True:
            print(f"\n{Colors.WARNING}--- MENU ---{Colors.ENDC}")
            print("1. Cấu hình Prefix")
            print("2. Login with Cookie")
            print("3. Thoát")
            
            choice = input("Chọn: ").strip()

            if choice == "1":
                self.set_prefix()
                self.scan_packages()
            
            elif choice == "2":
                if not self.packages:
                    self.scan_packages()
                if not self.packages: continue

                cookie_raw = input(f"\n{Colors.BOLD}Nhập Cookie: {Colors.ENDC}").strip()
                if not cookie_raw: continue

                if not self.verify_cookie(cookie_raw): continue
                self.download_resources()

                print(f"\n{Colors.BLUE}Chọn gói:{Colors.ENDC}")
                print("0. TẤT CẢ")
                for i, pkg in enumerate(self.packages):
                    print(f"{i+1}. {pkg}")
                
                idx = input("Nhập STT: ").strip()
                
                targets = []
                if idx == "0": targets = self.packages
                elif idx.isdigit() and 1 <= int(idx) <= len(self.packages):
                    targets = [self.packages[int(idx)-1]]
                else: continue

                for pkg in targets:
                    self.inject_cookie_root(pkg, cookie_raw)

            elif choice == "3":
                if os.path.exists(TEMP_DIR): shutil.rmtree(TEMP_DIR)
                sys.exit()

if __name__ == "__main__":
    try:
        app = CookieManager()
        app.run()
    except KeyboardInterrupt:
        pass
