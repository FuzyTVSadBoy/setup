#!/bin/bash
# ============================================================
#  AIO SETUP TOOL - ROOOT VERSION (UgPhone)
#  Yêu cầu: Máy đã bật Root (SuperUser)
# ============================================================

R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'
B='\033[0;34m'; C='\033[0;36m'; N='\033[0m'

log()  { echo -e "${G}[OK]${N} $1"; }
warn() { echo -e "${Y}[!!]${N} $1"; }
err()  { echo -e "${R}[ERR]${N} $1"; }
hdr()  { echo -e "\n${B}========== $1 ==========${N}"; }

# Kiểm tra Root trước khi chạy
if ! command -v su &>/dev/null; then
    err "LỖI: Máy chưa Root hoặc chưa cấp quyền cho Termux!"
    exit 1
fi

# Hàm thực thi lệnh dưới quyền Root
run_root() {
    su -c "$1" >/dev/null 2>&1
}

# ============================================================
#  CÁC BIẾN APK
# ============================================================
APK_1_URL="https://files.catbox.moe/w3goln.apk"
APK_2_URL="https://files.catbox.moe/yhsfgi.apk"
APK_3_URL="https://files.catbox.moe/blxs0h.apk"
APK_4_URL="https://files.catbox.moe/j19dz4.apk"

# ============================================================
#  BƯỚC 1: HỆ THỐNG & DEVELOPER OPTIONS
# ============================================================
hdr "1. THIẾT LẬP HỆ THỐNG (ROOT)"

# Bật Developer Mode & ADB
log "Đang kích hoạt Developer Options..."
run_root "settings put global development_settings_enabled 1"
run_root "settings put global adb_enabled 1"

# Bật 4 tính năng Developer quan trọng
log "Đang bật 4 tính năng ép buộc..."
run_root "settings put global force_allow_on_external 1"
run_root "settings put global force_resizable_activities 1"
run_root "settings put global enable_freeform_support 1"
run_root "settings put global force_desktop_mode_on_external_displays 1"

# Chỉnh DPI (Sử dụng wm density của Root cực kỳ ổn định)
log "Chỉnh DPI -> 220..."
run_root "wm density 220"
run_root "settings put system screen_density 220"

# ============================================================
#  BƯỚC 2: ĐÓNG BĂNG GOOGLE PLAY
# ============================================================
hdr "2. VÔ HIỆU HÓA GOOGLE SERVICES"
APPS=("com.android.vending" "com.google.android.gms" "com.google.android.gsf")

for pkg in "${APPS[@]}"; do
    if run_root "pm disable-user --user 0 $pkg"; then
        log "Đã tắt: $pkg"
    else
        warn "Không thể tắt: $pkg"
    fi
done

# ============================================================
#  BƯỚC 3: CÀI ĐẶT APK IM LẶNG (SILENT INSTALL)
# ============================================================
hdr "3. TẢI VÀ CÀI ĐẶT APK IM LẶNG"

install_silent() {
    local url="$1"
    local idx="$2"
    local dest="/data/local/tmp/app_${idx}.apk" # Tải vào vùng hệ thống để cài nhanh hơn

    echo -ne "${C}>> Đang tải app $idx...${N} "
    if curl -L -s -o "$dest" "$url"; then
        echo -e "${G}Xong${N}"
        # Lệnh cài đặt im lặng của Root
        if run_root "pm install -r -g $dest"; then
            log "Cài đặt thành công App $idx"
        else
            err "Cài đặt thất bại App $idx"
        fi
        run_root "rm $dest" # Xóa file tạm sau khi cài
    else
        err "Tải thất bại App $idx"
    fi
}

install_silent "$APK_1_URL" 1
install_silent "$APK_2_URL" 2
install_silent "$APK_3_URL" 3
install_silent "$APK_4_URL" 4

# ============================================================
#  BƯỚC 4: TERMUX SETUP & PYTHON
# ============================================================
hdr "4. TERMUX & LIBRARIES"
# Lưu ý: Các lệnh pkg và pip không cần su -c vì nó chạy trong môi trường termux
log "Cập nhật Termux..."
yes | pkg update -y -q
yes | pkg install python python-pip curl -y -q

log "Cài đặt Python Libs..."
pip install --quiet requests rich prettytable
pkg install python-psutil

log "Tải OldShouko.py..."
curl -Ls "https://raw.githubusercontent.com/FuzyTVSadBoy/setup/refs/heads/main/OldShouko.py" -o "$HOME/OldShouko.py"

# ============================================================
#  HOÀN TẤT
# ============================================================
hdr "HOÀN TẤT THIẾT LẬP"
log "Mọi tùy chọn đã được áp dụng qua quyền ROOT."
warn "Vui lòng khởi động lại Cloud Phone để DPI và Settings có hiệu lực hoàn toàn!"
