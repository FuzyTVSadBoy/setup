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
echo -e "${GREEN}===== UGPHONE AIO (USER CORE) =====${RESET}\r"
line

# ================== 1. BỘ NHỚ ==================
step "1/7" "Reset Storage"
# Code gốc của bạn
if [ -e "/data/data/com.termux/files/home/storage" ]; then
    rm -rf /data/data/com.termux/files/home/storage
fi
termux-setup-storage >/dev/null 2>&1
ok "Storage ready"
line

# ================== 2. REPO & UPGRADE ==================
step "2/7" "Repo & System Upgrade"

echo -e " -> Updating package lists...\r"
yes | pkg update -y >/dev/null 2>&1

echo -e " -> Config Repo (FuzyTVSadBoy)...\r"
# Lệnh curl repo của bạn
bash -c "$(curl -fsSL https://raw.githubusercontent.com/FuzyTVSadBoy/setup/refs/heads/main/termux-change-repo.sh)" >/dev/null 2>&1

echo -e " -> Upgrading system (pkg upgrade)...\r"
# Lệnh upgrade của bạn
yes | pkg upgrade -y -o Dpkg::Options::="--force-confnew" >/dev/null 2>&1

ok "System Upgraded"
line

# ================== 3. PYTHON SETUP ==================
step "3/7" "Installing Python"

echo -e " -> Installing Python & Pip...\r"
# Lệnh cài python của bạn (thêm clang/make để build psutil)
yes | pkg install -y python python-pip clang make binutils >/dev/null 2>&1

if python --version >/dev/null 2>&1; then
    ok "Python Installed"
else
    fail "Python Install Failed!"
    exit 1
fi
line

# ================== 4. LIBS & PSUTIL (FIX) ==================
step "4/7" "Installing Libraries"
pip cache purge >/dev/null 2>&1 || true

# 1. Cài các libs thường
echo -ne " -> Installing requests, rich... \r"
pip install requests rich prettytable pytz gdown --no-cache-dir --quiet >/dev/null 2>&1

# 2. Cài psutil với CFLAGS (Lệnh chuẩn của bạn)
echo -ne " -> Installing psutil (CFLAGS)... \r"
export CFLAGS="-Wno-error=implicit-function-declaration"
if pip install psutil --no-cache-dir --quiet >/dev/null 2>&1; then
    echo -e "${GREEN}OK${RESET}\r"
else
    # Fallback nhẹ nếu vẫn lỗi
    pip install psutil --no-binary :all: --quiet >/dev/null 2>&1
    echo -e "${YELLOW}OK (Source)${RESET}\r"
fi
ok "All Libraries Ready"
line

# ================== 5. DOWNLOAD TOOL ==================
step "5/7" "Downloading Tool"
mkdir -p "/sdcard/Download"

# Lệnh curl tool của bạn
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

# ================== 7. APK INSTALLER (AUTO-RENAME) ==================
step "7/7" "Installing APKs"

APK_ROOT="/sdcard/Download/auto_apk_root"
TMP_ROOT="/sdcard/Download/.apk_tmp"
GDRIVE="https://drive.google.com/drive/folders/16dE9WRhm53lh7STAOGnwWPZya_c9WxOc"

rm -rf "$APK_ROOT" "$TMP_ROOT"
mkdir -p "$APK_ROOT" "$TMP_ROOT"

echo -e "${YELLOW} -> Downloading from Drive (Please wait)...${RESET}\r"
cd "$TMP_ROOT" || exit
# Tải xuống im lặng
python -m gdown --folder "$GDRIVE" --quiet >/dev/null 2>&1

# ========================================================
# FIX LỖI ">" & SAI ĐƯỜNG DẪN: Đổi tên file tự động
# ========================================================
find . -type f -name "*.apk" | while read filename; do
    # Đổi tên file chứa ký tự lạ thành dấu gạch dưới
    safe_name=$(echo "$filename" | sed 's/[^a-zA-Z0-9.]/_/g')
    mv "$filename" "$APK_ROOT/$safe_name"
done

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
            echo -e "   [+] $shortname: ${GREEN}OK${RESET}\r"
        else
            echo -e "   [-] $shortname: ${YELLOW}GUI${RESET}\r"
            am start -a android.intent.action.VIEW -d "file://$FULL_PATH" -t application/vnd.android.package-archive >/dev/null 2>&1
            sleep 1
        fi
        stty onlcr 2>/dev/null
    done
fi

rm -rf "$TMP_ROOT"
line
echo -e "${GREEN}===== ALL DONE =====${RESET}\r"
echo -e "${YELLOW}Reboot Device Now!${RESET}\r"

