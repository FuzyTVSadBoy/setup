#!/bin/bash
# ============================================================
#  AIO SETUP TOOL - ROOOT VERSION (Optimized for HK Cloud)
# ============================================================

R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'
B='\033[0;34m'; C='\033[0;36m'; N='\033[0m'

log()  { echo -e "${G}[OK]${N} $1"; }
warn() { echo -e "${Y}[!!]${N} $1"; }
err()  { echo -e "${R}[ERR]${N} $1"; }
hdr()  { echo -e "\n\r${B}========== $1 ==========${N}"; }

# Kiểm tra quyền Root
if ! command -v su &>/dev/null; then
    err "Máy chưa Root hoặc Termux chưa được cấp quyền Root!"
    exit 1
fi

run_root() {
    su -c "$1"
}

APK_1_URL="https://files.catbox.moe/ogtjtp.apk" # Roblox
APK_2_URL="https://files.catbox.moe/zxz4lp.apk" # Roblox
APK_3_URL="https://files.catbox.moe/blxs0h.apk"
APK_4_URL="https://files.catbox.moe/j19dz4.apk"

# ============================================================
hdr "0. TỐI ƯU TỐC ĐỘ REPO (HONG KONG)"
log "Đang chuyển sang Mirror Tsinghua..."
sed -i 's@^\(deb.*termux.org/termux-main\).*$@deb https://mirrors.tuna.tsinghua.edu.cn/termux/termux-main stable main@' $PREFIX/etc/apt/sources.list

# ============================================================
hdr "1. THIẾT LẬP HỆ THỐNG (ROOT)"

log "Đang kích hoạt Developer Options..."
run_root "settings put global development_settings_enabled 1"
run_root "settings put global adb_enabled 1"

log "Bật 4 tính năng Developer..."
run_root "settings put global force_allow_on_external 1"
run_root "settings put global force_resizable_activities 1"
run_root "settings put global enable_freeform_support 1"
run_root "settings put global force_desktop_mode_on_external_displays 1"

log "Chỉnh DPI -> 220..."
run_root "wm density 220"
run_root "settings put system screen_density 220"

# --- FIX LỖI BẬC THANG ---
sleep 3
reset
stty sane
clear
# -------------------------

log "DPI đã đổi xong. Giao diện Terminal đã được reset."

# ============================================================
hdr "3. TẢI VÀ CÀI ĐẶT APK IM LẶNG"

install_silent() {
    local url="$1"
    local idx="$2"
    local dest="$HOME/app_${idx}.apk" 

    echo -ne "\r${C}>> Đang tải app $idx...${N} "
    
    if curl -L -q -o "$dest" "$url" 2>/dev/null; then
        echo -e "\r${G}>> Đang tải app $idx... Tải xong!${N}"
        
        chmod 777 "$dest"
        local install_log
        install_log=$(run_root "pm install -r -g $dest" 2>&1)
        
        if echo "$install_log" | grep -qi "Success"; then
            log "Cài đặt THÀNH CÔNG App $idx!"
        else
            err "Cài đặt thất bại App $idx. Lỗi: $install_log"
        fi
        rm -f "$dest"
    else
        err "Tải thất bại App $idx."
    fi
}

install_silent "$APK_1_URL" 1
install_silent "$APK_2_URL" 2
install_silent "$APK_3_URL" 3
install_silent "$APK_4_URL" 4

# ============================================================
hdr "4. TERMUX & LIBRARIES"
log "Cập nhật Termux (Mirror HK)..."
yes | pkg update
yes | pkg upgrade
yes | pkg install python python-pip curl ncurses-utils -y -q

log "Cài đặt Python Libs..."
pip install --quiet requests rich prettytable pytz
pkg install python-psutil -y -q

log "Tải OldShouko.py..."
curl -Ls "https://raw.githubusercontent.com/caot60002/ROKID-EDITED/refs/heads/main/main.py" -o /sdcard/Download/OldShouko.py

# ============================================================
hdr "HOÀN TẤT THIẾT LẬP"
warn "Vui lòng khởi động lại Cloud Phone để thay đổi có hiệu lực!"
