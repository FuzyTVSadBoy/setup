#!/bin/bash
# ============================================================
#  AIO SETUP TOOL - ROOOT VERSION (Fix UI & APK Install)
# ============================================================

R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'
B='\033[0;34m'; C='\033[0;36m'; N='\033[0m'

log()  { echo -e "${G}[OK]${N} $1"; }
warn() { echo -e "${Y}[!!]${N} $1"; }
err()  { echo -e "${R}[ERR]${N} $1"; }
hdr()  { echo -e "\n${B}========== $1 ==========${N}"; }

if ! command -v su &>/dev/null; then
    err "Máy chưa Root hoặc Termux chưa được cấp quyền Root!"
    exit 1
fi

run_root() {
    su -c "$1"
}

APK_1_URL="https://files.catbox.moe/w3goln.apk"
APK_2_URL="https://files.catbox.moe/yhsfgi.apk"
APK_3_URL="https://files.catbox.moe/blxs0h.apk"
APK_4_URL="https://files.catbox.moe/j19dz4.apk"

# ============================================================
hdr "1. THIẾT LẬP HỆ THỐNG (ROOT)"
log "Đang kích hoạt Developer Options..."
run_root "settings put global development_settings_enabled 1"
run_root "settings put global adb_enabled 1"

log "Chỉ bật Force Resizable (Đã bỏ Freeform/Desktop để tránh lỗi UI)..."
run_root "settings put global force_resizable_activities 1"

log "Chỉnh DPI -> 220..."
run_root "wm density 220"
run_root "settings put system screen_density 220"

# ============================================================
hdr "2. VÔ HIỆU HÓA GOOGLE SERVICES"
APPS=("com.android.vending" "com.google.android.gms" "com.google.android.gsf")
for pkg in "${APPS[@]}"; do
    run_root "pm disable-user --user 0 $pkg" >/dev/null 2>&1
    log "Đã tắt: $pkg"
done

# ============================================================
hdr "3. TẢI VÀ CÀI ĐẶT APK IM LẶNG"

install_silent() {
    local url="$1"
    local idx="$2"
    # Sửa lỗi path: Lưu thẳng vào thư mục HOME của Termux, user nào cũng ghi được
    local dest="$HOME/app_${idx}.apk" 

    echo -ne "${C}>> Đang tải app $idx...${N} "
    # Bỏ -s để nếu có lỗi mạng sẽ hiện ra thay vì im lặng
    if curl -L -q -o "$dest" "$url" 2>/dev/null; then
        echo -e "${G}Tải xong!${N}"
        log "Đang cài đặt App $idx..."
        
        # Cấp full quyền cho file phòng trường hợp pm install không đọc được
        chmod 777 "$dest"
        
        # Chạy pm install và bắt output
        local install_log
        install_log=$(run_root "pm install -r -g $dest" 2>&1)
        
        if echo "$install_log" | grep -qi "Success"; then
            log "Cài đặt THÀNH CÔNG App $idx!"
        else
            err "Cài đặt thất bại App $idx. Chi tiết lỗi: $install_log"
        fi
        
        rm -f "$dest" # Dọn dẹp file rác
    else
        err "Tải thất bại App $idx. Vui lòng kiểm tra lại link!"
    fi
}

install_silent "$APK_1_URL" 1
install_silent "$APK_2_URL" 2
install_silent "$APK_3_URL" 3
install_silent "$APK_4_URL" 4

# ============================================================
hdr "4. TERMUX & LIBRARIES"
log "Cập nhật Termux..."
yes | pkg update -y -q
yes | pkg install python python-pip curl -y -q

log "Cài đặt Python Libs..."
pip install --quiet requests rich prettytable psutil

log "Tải OldShouko.py..."
curl -Ls "https://raw.githubusercontent.com/FuzyTVSadBoy/setup/refs/heads/main/OldShouko.py" -o "$HOME/OldShouko.py"

# ============================================================
hdr "HOÀN TẤT THIẾT LẬP"
warn "Vui lòng khởi động lại Cloud Phone để DPI có hiệu lực hoàn toàn!"
