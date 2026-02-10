#!/data/data/com.termux/files/usr/bin/bash

# ================== CẤU HÌNH UI ==================
stty onlcr 2>/dev/null
BLUE='\033[1;34m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
CYAN='\033[1;36m'
RESET='\033[0m'

step() { stty onlcr 2>/dev/null; echo -e "${BLUE}[$1]${RESET} $2\r"; }
ok()   { echo -e "${GREEN}[✓]${RESET} $1\r"; }
warn() { echo -e "${YELLOW}[!]${RESET} $1\r"; }
fail() { echo -e "${RED}[X]${RESET} $1\r"; }
line() { echo -e "${CYAN}------------------------------${RESET}\r"; }

clear
echo -e "${GREEN}===== UGPHONE AIO (MEDIAFIRE MOD) =====${RESET}\r"
line

# ================== 1. BỘ NHỚ ==================
step "1/7" "Reset Storage"
if [ -e "/data/data/com.termux/files/home/storage" ]; then
    rm -rf /data/data/com.termux/files/home/storage
fi
termux-setup-storage >/dev/null 2>&1
ok "Storage ready"
line

# ================== 2. REPO & UPGRADE ==================
step "2/7" "Repo & Upgrade"

echo -e " -> Updating package lists...\r"
pkg update -y >/dev/null 2>&1

echo -e " -> Config Repo (FuzyTVSadBoy)...\r"
bash -c "$(curl -fsSL https://raw.githubusercontent.com/FuzyTVSadBoy/setup/refs/heads/main/termux-change-repo.sh)" >/dev/null 2>&1

echo -e " -> Upgrading system...\r"
pkg upgrade -y -o Dpkg::Options::="--force-confnew" >/dev/null 2>&1
ok "System Upgraded"
line

# ================== 3. PYTHON SETUP ==================
step "3/7" "Installing Python"

echo -e " -> Installing Python & Pip...\r"
pkg install -y python python-pip clang make binutils >/dev/null 2>&1

if python --version >/dev/null 2>&1; then
    ok "Python Installed"
else
    apt install -y python python-pip >/dev/null 2>&1
    ok "Python Installed (Apt)"
fi
line

# ================== 4. LIBS & PSUTIL ==================
step "4/7" "Installing Libraries"
pip cache purge >/dev/null 2>&1 || true

echo -ne " -> Installing base libs... \r"
# Vẫn giữ gdown để không lỗi code cũ nếu có, nhưng tải chính dùng requests
pip install requests rich prettytable pytz gdown --no-cache-dir --quiet >/dev/null 2>&1

echo -ne " -> Installing psutil (CFLAGS)... \r"
export CFLAGS="-Wno-error=implicit-function-declaration"
if pip install psutil --no-cache-dir --quiet >/dev/null 2>&1; then
    echo -e "${GREEN}OK${RESET}\r"
else
    pip install psutil --no-binary :all: --quiet >/dev/null 2>&1
    echo -e "${YELLOW}OK (Source)${RESET}\r"
fi
ok "Libraries Ready"
line

# ================== 5. DOWNLOAD TOOL ==================
step "5/7" "Downloading Tool"
mkdir -p "/sdcard/Download"

curl -Ls "https://raw.githubusercontent.com/FuzyTVSadBoy/setup/refs/heads/main/OldShouko.py" -o /sdcard/Download/OldShouko.py

if [ -f "/sdcard/Download/OldShouko.py" ]; then
    ok "Tool Saved"
else
    fail "Download Tool Failed"
fi
line

# ================== 6. DEVICE CONFIG ==================
step "6/7" "Device Config"
if ! su -c "id" >/dev/null 2>&1; then
    fail "NO ROOT ACCESS!"
    exit 1
fi
HWID="f43f5764ee3f616a"
su -c "settings put secure android_id $HWID" >/dev/null 2>&1
ok "ID Set: ...616a"

su -c "wm density 200; settings put global development_settings_enabled 1; settings put global force_resizable_activities 1; settings put global enable_freeform_support 1" >/dev/null 2>&1
ok "Window Optimized"
line

# ================== 7. APK INSTALLER (MEDIAFIRE FIX) ==================
step "7/7" "Installing APKs"

APK_ROOT="/sdcard/Download/auto_apk_root"
rm -rf "$APK_ROOT"
mkdir -p "$APK_ROOT"

echo -e "${YELLOW} -> Downloading Files form Mediafire...${RESET}\r"

# ------------------------------------------------------------------
# PYTHON DOWNLOADER (DIRECT LINK MOD)
# ------------------------------------------------------------------
cat <<EOF > downloader.py
import requests
import os
import sys

# Danh sách link trực tiếp bạn đã cung cấp
urls = [
    "https://download2272.mediafire.com/6xz4xlxoffagKvtpi3FSD-dX6QqN8tfX6NHSRXSvn0Nz6jAZLG9V5FyYwX2Wvi0K_B6p0KjgeT1jMPN_TNoCC4Rh8WUEjDt0TtTxr2wDKu5Mdp6stol7j7nHeKHCnO1mErxTKvjDYuBESGwJ55xu_12q3yPkhXgdFPKGMCB4g6laiw/x5b9678xq6ut13d/DeltaGlobalCloneByCherry+1-2.706.750.apk.apk",
    "https://download2264.mediafire.com/vi77ssprg8bgwmO2m2X5aYfbs1FAWWQI9nw9uu5i7GNvkHkFrMWLkFSSUzMTNfmOlhIt9COFrjSzMgkqHxw-6BlyXLCvgCBOCvQUaXwC_7BeArU3NAxiSWI8zKzmubxBLMgKu-g3qjQziBA-Xsh-MEt5nNJTqjNi8qmJ55DPlXTcwA/wyz9r4nwjbssnwg/DeltaGlobalCloneByCherry+2-2.706.750.apk.apk",
    "https://download1591.mediafire.com/iqaccp5d39gg3D3f3M6x8wwD5JmsHWyBP9bWH_wQ4yQdy13TY1w8V8yXRGRC1G2I-fxz6uqIaq3jglds_LvIB1GSuL9RPMZNp1TtSHa2rhdFgHpQYSOCazn65XF2_fmuNmftAQdTIawaVEGljQ8p4Tk-a0TuvalwahVpR_MMehN7Lw/dsrr6vxd35l63j8/DeltaGlobalCloneByCherry+3-2.706.750.apk.apk"
]

final_dir = "/sdcard/Download/auto_apk_root"

def log(msg):
    print(msg + "\r")

def download(url, index):
    try:
        # Lấy tên file từ URL và fix lỗi .apk.apk
        filename = url.split('/')[-1]
        if filename.endswith(".apk.apk"):
            filename = filename[:-4] # Bỏ bớt 1 đuôi .apk
            
        path = os.path.join(final_dir, filename)
        
        log(f"    Downloading ({index}/3): {filename[:25]}...")
        
        # Giả lập User-Agent để tránh bị chặn 403
        headers = {'User-Agent': 'Mozilla/5.0'}
        
        r = requests.get(url, headers=headers, stream=True)
        if r.status_code == 200:
            with open(path, 'wb') as f:
                for chunk in r.iter_content(chunk_size=1024):
                    if chunk:
                        f.write(chunk)
            return True
        else:
            log(f"    [!] Failed HTTP {r.status_code}")
            return False
            
    except Exception as e:
        log(f"    [X] Error: {e}")
        return False

count = 0
for i, url in enumerate(urls, 1):
    if download(url, i):
        count += 1

log(f"    Prepared {count} APK(s) for installation.")
EOF
# ------------------------------------------------------------------

# Chạy Python script
python downloader.py
rm downloader.py

# Cài đặt
cd "$APK_ROOT" || exit
shopt -s nullglob
files=(*.apk)

if [ ${#files[@]} -eq 0 ]; then
    warn "No APKs Found"
else
    echo -e " -> Installing ${#files[@]} App(s):\r"
    for filename in "${files[@]}"; do
        FULL_PATH="$APK_ROOT/$filename"
        shortname=$(echo "$filename" | cut -c 1-20)..
        
        chmod 644 "$FULL_PATH"
        if su -c "pm install -r \"$FULL_PATH\"" >/dev/null 2>&1; then
            echo -e "    [+] $shortname: ${GREEN}OK${RESET}\r"
        else
            echo -e "    [-] $shortname: ${YELLOW}GUI${RESET}\r"
            am start -a android.intent.action.VIEW -d "file://$FULL_PATH" -t application/vnd.android.package-archive >/dev/null 2>&1
            sleep 1
        fi
        stty onlcr 2>/dev/null
    done
fi

line
echo -e "${GREEN}===== ALL DONE =====${RESET}\r"
echo -e "${YELLOW}Reboot Device Now!${RESET}\r"
