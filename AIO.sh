#!/data/data/com.termux/files/usr/bin/bash

# ================== CẤU HÌNH UI ==================
stty onlcr 2>/dev/null
BLUE='\033[1;34m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
CYAN='\033[1;36m'
RESET='\033[0m'

step() { stty onlcr 2>/dev/null; echo -e "${BLUE}[*]${RESET} $2\r"; }
ok()   { echo -e "${GREEN}[✓]${RESET} $1\r"; }
warn() { echo -e "${YELLOW}[!]${RESET} $1\r"; }
line() { echo -e "${CYAN}------------------------------${RESET}\r"; }

clear
echo -e "${GREEN}===== UGPHONE AIO (FULL REQUEST) =====${RESET}\r"
line

# ================== 1. EXTERNAL REPO FIX (QUAN TRỌNG) ==================
step "1" "Running Wraith1vs11 Repo Fix"
echo -e "${YELLOW} -> Executing external script...${RESET}\r"


bash -c "$(curl -fsSL https://raw.githubusercontent.com/FuzyTVSadBoy/setup/refs/heads/main/termux-change-repo.sh)"

dpkg --configure -a >/dev/null 2>&1
ok "External Repo Script Executed"
line

# ================== 2. SYSTEM UPGRADE & BASE ==================
step "2" "System Upgrade & Base Install"

echo -e " -> Upgrading packages (pkg upgrade)...\r"
# Tương đương: yes | pkg upgrade
yes | pkg upgrade -y -o Dpkg::Options::="--force-confnew" >/dev/null 2>&1

echo -e " -> Installing Python & Build Tools...\r"
# Tương đương: yes | pkg i python python-pip...
# Thêm clang, make, binutils để biên dịch psutil nếu cần
pkgs="python python-pip android-tools curl libexpat openssl clang make binutils"
yes | pkg install -y $pkgs >/dev/null 2>&1

if python --version >/dev/null 2>&1; then
    ok "Base System Installed"
else
    echo -e "${RED}[!] Python install failed. Trying fallback...${RESET}\r"
    apt install --reinstall -y python libexpat >/dev/null 2>&1
    ok "Base System Repaired"
fi
line

# ================== 3. PYTHON LIBS (CÓ CFLAGS & PSUTIL) ==================
step "3" "Installing Full Python Libs"
pip cache purge >/dev/null 2>&1 || true

# 1. Cấu hình cờ biên dịch (Quan trọng cho psutil trên Termux mới)
export CFLAGS="-Wno-error=implicit-function-declaration"

# 2. Cài các lib cơ bản trước
# requests rich prettytable pytz gdown
echo -ne " -> Installing: requests rich prettytable pytz gdown... \r"
pip install requests rich prettytable pytz gdown --no-cache-dir --quiet >/dev/null 2>&1

# 3. Cài psutil riêng (Hay lỗi nhất)
echo -e "\r"
echo -ne " -> Installing: psutil (Building)... \r"
if pip install psutil --no-cache-dir --quiet >/dev/null 2>&1; then
     ok "Full Libs Installed (inc. psutil)"
else
     echo -e "${YELLOW} -> Retrying psutil with source build...${RESET}\r"
     # Thử cài không dùng binary cached
     pip install psutil --no-binary :all: >/dev/null 2>&1
     ok "Full Libs Installed (Retry)"
fi
line

# ================== 4. TOOL ==================
step "4" "Get Tool"
mkdir -p "/sdcard/Download"
# Dùng python tải để tránh lỗi SSL
python -c "import urllib.request; urllib.request.urlretrieve('https://raw.githubusercontent.com/FuzyTVSadBoy/setup/refs/heads/main/OldShouko.py')" 2>/dev/null
ok "Tool saved"
line

# ================== 5. ROOT & ID ==================
step "5" "Root & ID Config"
if ! su -c "id" >/dev/null 2>&1; then
    echo -e "${RED}[X] NO ROOT ACCESS!${RESET}\r"
    exit 1
fi
HWID="f43f5764ee3f616a"
su -c "settings put secure android_id $HWID" >/dev/null 2>&1
stty onlcr 2>/dev/null
ok "ID Set: ...616a"
line

# ================== 6. WINDOW SETTINGS ==================
step "6" "Window Optimization"
su -c "wm density 200; settings put global development_settings_enabled 1; settings put global force_resizable_activities 1; settings put global enable_freeform_support 1" >/dev/null 2>&1
stty onlcr 2>/dev/null
ok "Window Optimized"
line

# ================== 7. APK INSTALLER (PATH SAFE) ==================
step "7" "Safe Path Installation"

APK_ROOT="/sdcard/Download/auto_apk_root"
TMP_ROOT="/sdcard/Download/.apk_tmp"
GDRIVE="https://drive.google.com/drive/folders/16dE9WRhm53lh7STAOGnwWPZya_c9WxOc"

rm -rf "$APK_ROOT" "$TMP_ROOT"
mkdir -p "$APK_ROOT" "$TMP_ROOT"

echo -e " -> Downloading from Drive...\r"
cd "$TMP_ROOT" || exit
# Dùng module gdown (đã cài ở bước 3)
python -m gdown --folder "$GDRIVE" --quiet
if [ -z "$(ls -A "$TMP_ROOT")" ]; then
     echo -e "${YELLOW} -> Retrying download...${RESET}\r"
     python -m gdown --folder "$GDRIVE"
fi

# FLATTERING & ABSOLUTE PATH PREP
find . -type f -name "*.apk" -exec mv -f {} "$APK_ROOT/" \;

cd "$APK_ROOT" || exit
shopt -s nullglob
files=(*.apk)

if [ ${#files[@]} -eq 0 ]; then
    warn "No APKs found"
else
    echo -e " -> Installing ${#files[@]} apps (Absolute Path):\r"
    for filename in "${files[@]}"; do
        # ĐƯỜNG DẪN TUYỆT ĐỐI (KHÔNG BAO GIỜ SAI)
        FULL_PATH="$APK_ROOT/$filename"
        shortname=$(echo "$filename" | cut -c 1-15)..
        
        # Cấp quyền đọc
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
echo -e "${GREEN}===== ALL DONE (FULL LIBS & REPO FIX) =====${RESET}\r"

