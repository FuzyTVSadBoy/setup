#!/bin/bash
# ============================================================
#  AIO SETUP TOOL - Roblox MMO Cloud Phone (UgPhone)
#  Không cần root | Dùng ADB localhost trong Termux
# ============================================================

set -e

R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'
B='\033[0;34m'; C='\033[0;36m'; N='\033[0m'

log()  { echo -e "${G}[OK]${N} $1"; }
warn() { echo -e "${Y}[!!]${N} $1"; }
err()  { echo -e "${R}[ERR]${N} $1"; exit 1; }
hdr()  { echo -e "\n${B}========== $1 ==========${N}"; }

# ============================================================
#  >>> CẤU HÌNH LINK APK - CHỈNH TẠI ĐÂY <<<
# ============================================================

APK_1_NAME="App 1"
APK_1_URL="https://files.catbox.moe/w3goln.apk"

APK_2_NAME="App 2"
APK_2_URL="https://files.catbox.moe/yhsfgi.apk"

APK_3_NAME="App 3"
APK_3_URL="https://files.catbox.moe/blxs0h.apk"

APK_4_NAME="App 4"
APK_4_URL="https://files.catbox.moe/j19dz4.apk"

# ============================================================

# ---------- BƯỚC 0: CÀI ADB & KẾT NỐI LOCALHOST ----------
hdr "0. SETUP ADB LOCALHOST"

# Cài adb nếu chưa có
if ! command -v adb &>/dev/null; then
    warn "Chưa có adb, đang cài..."
    yes | pkg install -y android-tools
    log "Đã cài adb"
else
    log "adb đã có sẵn"
fi

# Kết nối ADB vào chính thiết bị qua localhost
warn "Đang kết nối ADB localhost:5555..."
adb connect localhost:5555 2>/dev/null || true
sleep 2

# Kiểm tra kết nối
if ! adb shell echo ok 2>/dev/null | grep -q "ok"; then
    warn "Port 5555 thất bại, thử 5554..."
    adb connect localhost:5554 2>/dev/null || true
    sleep 2
fi

if ! adb shell echo ok 2>/dev/null | grep -q "ok"; then
    err "Không kết nối được ADB localhost. UgPhone cần bật ADB Wireless trong cài đặt thiết bị."
fi

log "ADB localhost kết nối thành công!"

# Hàm chạy lệnh qua adb shell
S() { adb shell "$@" 2>/dev/null; }

# ---------- BƯỚC 1: BẬT CHẾ ĐỘ NHÀ PHÁT TRIỂN ----------
hdr "1. BẬT CHẾ ĐỘ NHÀ PHÁT TRIỂN"
S settings put global development_settings_enabled 1
S settings put global adb_enabled 1
log "Developer options: BẬT"

# ---------- BƯỚC 2: BẬT 4 TÍNH NĂNG DEVELOPER ----------
hdr "2. BẬT 4 TÍNH NĂNG DEVELOPER"

S settings put global force_allow_on_external 1
log "Buộc cho phép ứng dụng trên bộ nhớ ngoài: BẬT"

S settings put global force_resizable_activities 1
log "Buộc hoạt động có thể thay đổi kích thước: BẬT"

S settings put global enable_freeform_support 1
log "Cửa sổ dạng tự do: BẬT"

S settings put global force_desktop_mode_on_external_displays 1
log "Buộc chạy chế độ máy tính: BẬT"

# ---------- BƯỚC 3: CHỈNH DPI = 220 ----------
hdr "3. CHỈNH DPI -> 220"
S wm density 220
S settings put system screen_density 220
log "DPI đã đặt thành 220"

# ---------- BƯỚC 4: DISABLE GOOGLE PLAY ----------
hdr "4. TẮT GOOGLE PLAY"
for pkg in com.android.vending com.google.android.gms com.google.android.gsf; do
    if S pm list packages | grep -q "$pkg"; then
        S pm disable-user --user 0 "$pkg" \
            && log "Disabled: $pkg" \
            || warn "Không disable được: $pkg (bỏ qua)"
    else
        warn "Không tìm thấy: $pkg"
    fi
done

# ---------- BƯỚC 5: TERMUX - SETUP STORAGE ----------
hdr "5. TERMUX - SETUP STORAGE"
[ -e "$HOME/storage" ] && rm -rf "$HOME/storage"
termux-setup-storage
log "Storage Termux đã thiết lập"

# ---------- BƯỚC 6: CHỌN REPO NHANH NHẤT ----------
hdr "6. CHỌN REPO TERMUX NHANH NHẤT"

REPOS=(
    "https://packages-cf.termux.dev/apt/termux-main"
    "https://mirror.sg.gs/termux/termux-packages-24"
    "https://termux.librehat.com/apt/termux-main"
    "https://dl.kcubeterm.com/termux/termux-main"
)

BEST_URL=""
BEST_TIME=999999

warn "Đang ping các repo..."
for url in "${REPOS[@]}"; do
    T=$(curl -o /dev/null -s -m 6 -w "%{time_total}" "$url/dists/stable/Release" 2>/dev/null || echo "999999")
    T_INT=$(awk "BEGIN {printf \"%d\", $T * 1000}")
    echo -e "  ${C}${url}${N} -> ${T_INT}ms"
    if [ "$T_INT" -lt "$BEST_TIME" ]; then
        BEST_TIME=$T_INT
        BEST_URL=$url
    fi
done

if [ -n "$BEST_URL" ] && [ "$BEST_TIME" -lt 999999 ]; then
    log "Repo nhanh nhất: $BEST_URL (${BEST_TIME}ms)"
    echo "deb $BEST_URL stable main" > "$PREFIX/etc/apt/sources.list"
    log "Đã ghi sources.list"
else
    warn "Không ping được repo nào, dùng script change-repo gốc..."
    . <(curl -Ls https://raw.githubusercontent.com/FuzyTVSadBoy/setup/refs/heads/main/termux-change-repo.sh)
fi

# ---------- BƯỚC 7: UPDATE & CÀI THƯ VIỆN + OLDSHOUKO ----------
hdr "7. UPDATE & CÀI ĐẶT THƯ VIỆN"
yes | pkg update -y
yes | pkg upgrade -y
yes | pkg install -y python python-pip curl wget

pip install --quiet requests rich prettytable pytz

export CFLAGS="-Wno-error=implicit-function-declaration"
pip install --quiet psutil

log "Tải OldShouko.py..."
curl -Ls "https://raw.githubusercontent.com/FuzyTVSadBoy/setup/refs/heads/main/OldShouko.py" \
     -o /sdcard/Download/OldShouko.py
log "OldShouko.py -> /sdcard/Download/OldShouko.py"

# ---------- BƯỚC 8: TẢI & CÀI 4 APK ----------
hdr "8. TẢI & CÀI 4 APK"

install_apk() {
    local name="$1"
    local url="$2"
    local idx="$3"
    local dest="/sdcard/Download/aio_app${idx}.apk"

    if [ -z "$url" ]; then
        warn "[$name] Link trống, bỏ qua."
        return 0
    fi

    echo -e "${C}>> Đang tải [$name]...${N}"
    if curl -L --progress-bar --connect-timeout 15 --retry 3 --retry-delay 2 \
            -o "$dest" "$url"; then
        log "[$name] Tải xong -> $dest"
        echo -e "${C}>> Đang cài [$name]...${N}"
        # Cài qua adb shell pm install (có quyền shell)
        if adb shell pm install -r -g "$dest" 2>/dev/null; then
            log "[$name] Cài APK thành công!"
        else
            warn "[$name] pm install thất bại. File đã lưu: $dest"
        fi
    else
        err "[$name] Tải thất bại. Kiểm tra lại link."
    fi
}

install_apk "$APK_1_NAME" "$APK_1_URL" 1
install_apk "$APK_2_NAME" "$APK_2_URL" 2
install_apk "$APK_3_NAME" "$APK_3_URL" 3
install_apk "$APK_4_NAME" "$APK_4_URL" 4

# ---------- HOÀN TẤT ----------
hdr "HOÀN TẤT"
echo -e "${G}"
echo "  ✔ ADB localhost           : KẾT NỐI"
echo "  ✔ Developer options       : BẬT"
echo "  ✔ 4 tính năng developer   : BẬT"
echo "  ✔ DPI                     : 220"
echo "  ✔ Google Play             : TẮT"
echo "  ✔ Termux repo             : ĐÃ CHỌN NHANH NHẤT"
echo "  ✔ Thư viện + OldShouko   : ĐÃ CÀI"
echo "  ✔ 4 APK                   : ĐÃ XỬ LÝ"
echo -e "${N}"
echo -e "${Y}>>> Khởi động lại để áp dụng toàn bộ thay đổi! <<<${N}"
echo ""
