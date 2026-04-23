#!/bin/bash
# ============================================================
#  AIO SETUP TOOL - ROOOT VERSION (Fix Staircase UI & APK)
# ============================================================

R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'
B='\033[0;34m'; C='\033[0;36m'; N='\033[0m'

log()  { echo -e "${G}[OK]${N} $1"; }
warn() { echo -e "${Y}[!!]${N} $1"; }
err()  { echo -e "${R}[ERR]${N} $1"; }
hdr()  { echo -e "\n\r${B}========== $1 ==========${N}"; }

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

log "Bật 4 tính năng Developer..."
run_root "settings put global force_allow_on_external 1"
run_root "settings put global force_resizable_activities 1"
run_root "settings put global enable_freeform_support 1"
run_root "settings put global force_desktop_mode_on_external_displays 1"

log "Chỉnh DPI -> 220..."
run_root "wm density 220"
run_root "settings put system screen_density 220"

# --- FIX LỖI BẬC THANG Ở ĐÂY ---
# Đợi 2 giây để màn hình đổi DPI xong, sau đó reset lại UI của Termux
sleep 2
stty sane
clear
# -------------------------------

log "DPI đã đổi xong. Giao diện Terminal đã được reset."

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
log "Cập nhật Termux..."
yes | pkg update -y -q
yes | pkg install python python-pip curl -y -q

log "Cài đặt Python Libs..."
pip install --quiet requests rich prettytable 
pkg install python-psutil

log "Tải OldShouko.py..."
curl -Ls "https://raw.githubusercontent.com/FuzyTVSadBoy/setup/refs/heads/main/OldShouko.py" -o "$HOME/OldShouko.py"

# ============================================================
hdr "HOÀN TẤT THIẾT LẬP"
warn "Vui lòng khởi động lại Cloud Phone để thay đổi có hiệu lực!"
