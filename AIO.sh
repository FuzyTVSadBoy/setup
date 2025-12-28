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
echo -e "${GREEN}===== UGPHONE AIO (PATH SAFE MODE) =====${RESET}\r"
line

# ================== 1. BỘ NHỚ ==================
step "1" "Reset Storage"
rm -rf "$HOME/storage" 2>/dev/null
termux-setup-storage >/dev/null 2>&1
ok "Storage ready"
line

# ================== 2. HỆ THỐNG (DEEP CHECK) ==================
step "2" "System Integrity Check"
# Đảm bảo môi trường luôn đúng
mkdir -p "$PREFIX/etc/apt"
echo "deb https://grimler.se/termux/termux-main stable main" > "$PREFIX/etc/apt/sources.list"
dpkg --configure -a >/dev/null 2>&1
apt update -y >/dev/null 2>&1
# Cài đặt các gói cần thiết
pkgs="python python-pip android-tools curl libexpat openssl"
apt install -y --fix-missing $pkgs >/dev/null 2>&1

if python --version >/dev/null 2>&1; then
    ok "System Libs Verified"
else
    echo -e "${RED}[!] Python missing. Reinstalling...${RESET}\r"
    apt install --reinstall -y python libexpat >/dev/null 2>&1
    ok "System Repaired"
fi
line

# ================== 3. CHUẨN BỊ GDOWN ==================
step "3" "Downloader Setup"
pip cache purge >/dev/null 2>&1 || true
# Cài gdown
pip install gdown requests rich --no-cache-dir --quiet >/dev/null 2>&1
if python -c "import gdown" >/dev/null 2>&1; then
    ok "Downloader Ready"
else
    pip install gdown --force-reinstall >/dev/null 2>&1
    ok "Downloader Retry Done"
fi
line

# ================== 4. TOOL ==================
step "4" "Get Tool"
mkdir -p "/sdcard/Download"
python -c "import urllib.request; urllib.request.urlretrieve('https://raw.githubusercontent.com/Wraith1vs11/Rejoin/refs/heads/main/OldShouko.py', '/sdcard/Download/OldShouko.py')" 2>/dev/null
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

# Định nghĩa đường dẫn tuyệt đối ngay từ đầu
APK_ROOT="/sdcard/Download/auto_apk_root"
TMP_ROOT="/sdcard/Download/.apk_tmp"
GDRIVE="https://drive.google.com/drive/folders/16dE9WRhm53lh7STAOGnwWPZya_c9WxOc"

# Dọn dẹp
rm -rf "$APK_ROOT" "$TMP_ROOT"
mkdir -p "$APK_ROOT" "$TMP_ROOT"

echo -e " -> Downloading...\r"
cd "$TMP_ROOT" || exit
python -m gdown --folder "$GDRIVE" --quiet
if [ -z "$(ls -A "$TMP_ROOT")" ]; then
     echo -e "${YELLOW} -> Retrying download...${RESET}\r"
     python -m gdown --folder "$GDRIVE"
fi

# FLATTERING: Tìm mọi file .apk và đưa về thư mục gốc, đổi tên nếu trùng
# Bước này đảm bảo APK nằm đúng chỗ ta muốn
find . -type f -name "*.apk" -exec mv -f {} "$APK_ROOT/" \;

# Bắt đầu quy trình cài đặt an toàn
cd "$APK_ROOT" || exit
shopt -s nullglob
files=(*.apk)

if [ ${#files[@]} -eq 0 ]; then
    warn "No APKs found"
else
    echo -e " -> Installing ${#files[@]} apps with Absolute Path:\r"
    
    for filename in "${files[@]}"; do
        # TẠO ĐƯỜNG DẪN TUYỆT ĐỐI (CRITICAL FIX)
        # Kết hợp thư mục gốc và tên file để tạo đường dẫn không thể sai
        FULL_PATH="$APK_ROOT/$filename"
        
        # Lấy tên hiển thị ngắn gọn
        shortname=$(echo "$filename" | cut -c 1-15)..
        
        # Cấp quyền đọc cho file (Phòng trường hợp lỗi Permission Denied)
        chmod 644 "$FULL_PATH"
        
        # Lệnh cài đặt sử dụng FULL_PATH được bọc trong ngoặc kép
        # \"$FULL_PATH\" -> Đảm bảo khoảng trắng trong tên file không gây lỗi
        if su -c "pm install -r \"$FULL_PATH\"" >/dev/null 2>&1; then
            echo -e "   [+] $shortname: ${GREEN}OK${RESET}\r"
        else
            echo -e "   [-] $shortname: ${YELLOW}GUI${RESET}\r"
            # Fallback cũng dùng full path
            am start -a android.intent.action.VIEW -d "file://$FULL_PATH" -t application/vnd.android.package-archive >/dev/null 2>&1
            sleep 1
        fi
        stty onlcr 2>/dev/null
    done
fi

rm -rf "$TMP_ROOT"
line
echo -e "${GREEN}===== DONE (REBOOT NOW) =====${RESET}\r"

