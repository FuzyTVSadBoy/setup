#!/data/data/com.termux/files/usr/bin/bash

# ================== CẤU HÌNH UI (CLASSIC) ==================
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
echo -e "${GREEN}===== UGPHONE AIO (REPAIR & FIX) =====${RESET}\r"
line

# ================== 1. BỘ NHỚ ==================
step "1/7" "Reset Storage"
rm -rf "$HOME/storage" 2>/dev/null
termux-setup-storage >/dev/null 2>&1
ok "Storage ready"
line

# ================== 2. REPO SETUP (MANUAL FIX) ==================
step "2/7" "Configuring Repository"

# FIX: Script ngoài bị lỗi, ta cấu hình trực tiếp vào Grimler (Ổn định nhất)
echo -e " -> Setting up Grimler Mirror...\r"
mkdir -p "$PREFIX/etc/apt"
echo "deb https://grimler.se/termux/termux-main stable main" > "$PREFIX/etc/apt/sources.list"

# Mở khóa dpkg
dpkg --configure -a >/dev/null 2>&1
ok "Repo Configured (Grimler)"
line

# ================== 3. SYSTEM INSTALL (APT-GET FORCE) ==================
step "3/7" "System Upgrade & Python"

echo -e " -> Updating package lists...\r"
# Dùng apt-get update thay vì pkg
apt-get update -y -o Dpkg::Options::="--force-confnew" >/dev/null 2>&1

echo -e " -> Installing Python & Core...\r"
# FIX: Dùng apt-get install -y để tránh lỗi Broken pipe
pkgs="python python-pip android-tools curl binutils clang make libexpat openssl"
apt-get install -y $pkgs >/dev/null 2>&1

# Refresh lại đường dẫn lệnh
hash -r

if python --version >/dev/null 2>&1; then
    ok "Python Installed Success"
else
    echo -e "${RED}[!] Python missing. Force Repairing...${RESET}\r"
    # Thử cài lại bằng dpkg force
    apt-get install -y --reinstall python libexpat openssl >/dev/null 2>&1
    if python --version >/dev/null 2>&1; then
         ok "Python Repaired"
    else
         fail "FATAL: Python could not be installed!"
         exit 1
    fi
fi
line

# ================== 4. PYTHON LIBS ==================
step "4/7" "Installing Libraries"
pip cache purge >/dev/null 2>&1 || true
export CFLAGS="-Wno-error=implicit-function-declaration"

libs="requests rich prettytable pytz gdown"
echo -ne " -> Installing: $libs ... \r"
# Cài đặt silent, không hiện output dài dòng
if pip install $libs --no-cache-dir --quiet >/dev/null 2>&1; then
    echo -e "${GREEN}OK${RESET}\r"
else
    echo -e "${YELLOW}RETRY${RESET}\r"
    pip install $libs --no-cache-dir >/dev/null 2>&1
fi

echo -ne " -> Installing: psutil ... \r"
if pip install psutil --no-cache-dir --quiet >/dev/null 2>&1; then
    echo -e "${GREEN}OK${RESET}\r"
else
    echo -e "${YELLOW}BUILDING${RESET}\r"
    pip install psutil --no-binary :all: >/dev/null 2>&1
fi
ok "Libraries Ready"
line

# ================== 5. TOOL (NEW LINK) ==================
step "5/7" "Downloading Tool"
mkdir -p "/sdcard/Download"

# Link mới bạn yêu cầu
TOOL_URL="https://raw.githubusercontent.com/FuzyTVSadBoy/setup/refs/heads/main/OldShouko.py"
TOOL_PATH="/sdcard/Download/OldShouko.py"

python -c "import urllib.request; urllib.request.urlretrieve('$TOOL_URL', '$TOOL_PATH')" 2>/dev/null
ok "Tool Saved"
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

# ================== 7. APK INSTALLER ==================
step "7/7" "Installing APKs"

APK_ROOT="/sdcard/Download/auto_apk_root"
TMP_ROOT="/sdcard/Download/.apk_tmp"
GDRIVE="https://drive.google.com/drive/folders/16dE9WRhm53lh7STAOGnwWPZya_c9WxOc"

rm -rf "$APK_ROOT" "$TMP_ROOT"
mkdir -p "$APK_ROOT" "$TMP_ROOT"

echo -e " -> Downloading from Drive...\r"
cd "$TMP_ROOT" || exit
# Hiện thanh tải xuống (bỏ quiet) để bạn thấy tiến trình
python -m gdown --folder "$GDRIVE"

find . -type f -name "*.apk" -exec mv -f {} "$APK_ROOT/" \;

cd "$APK_ROOT" || exit
shopt -s nullglob
files=(*.apk)

if [ ${#files[@]} -eq 0 ]; then
    warn "No APKs Found"
else
    echo -e " -> Installing ${#files[@]} apps:\r"
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
