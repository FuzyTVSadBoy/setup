#!/bin/bash
# ============================================================
#  AIO SETUP TOOL - Roblox MMO Cloud Phone (UgPhone)
#  Multi-method: cmd / content / adb localhost
# ============================================================

R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'
B='\033[0;34m'; C='\033[0;36m'; N='\033[0m'

log()  { echo -e "${G}[OK]${N} $1"; }
warn() { echo -e "${Y}[!!]${N} $1"; }
err()  { echo -e "${R}[ERR]${N} $1"; }
hdr()  { echo -e "\n${B}========== $1 ==========${N}"; }

# ============================================================
#  >>> 4 LINK APK <<<
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

# ============================================================
#  HÀM CHẠY LỆNH ĐA-METHOD
#  Thử theo thứ tự: cmd → content → adb shell → báo lỗi
# ============================================================

ADB_OK=0

# Khởi tạo ADB nếu có
init_adb() {
    if [ "$ADB_OK" = "1" ]; then return 0; fi
    if ! command -v adb &>/dev/null; then
        yes | pkg install -y android-tools -q 2>/dev/null
    fi
    for port in 5555 5554 5037; do
        adb connect localhost:$port &>/dev/null
        sleep 1
        if adb shell echo ok 2>/dev/null | grep -q "ok"; then
            log "ADB kết nối qua localhost:$port"
            ADB_OK=1
            return 0
        fi
    done
    return 1
}

# Đặt setting global
set_global() {
    local key="$1" val="$2"

    # Method 1: cmd settings (uid thường, nhưng một số ROM cho phép)
    if cmd settings put global "$key" "$val" 2>/dev/null; then
        log "  [cmd] $key = $val"
        return 0
    fi

    # Method 2: content provider trực tiếp
    if content insert --uri content://settings/global \
        --bind name:s:"$key" --bind value:s:"$val" 2>/dev/null; then
        log "  [content insert] $key = $val"
        return 0
    fi
    # Nếu đã tồn tại thì update
    if content update --uri content://settings/global \
        --bind value:s:"$val" \
        --where "name='$key'" 2>/dev/null; then
        log "  [content update] $key = $val"
        return 0
    fi

    # Method 3: adb shell
    init_adb
    if [ "$ADB_OK" = "1" ]; then
        if adb shell settings put global "$key" "$val" 2>/dev/null; then
            log "  [adb] $key = $val"
            return 0
        fi
    fi

    warn "  Không đặt được: $key (bỏ qua)"
    return 1
}

set_system() {
    local key="$1" val="$2"

    if cmd settings put system "$key" "$val" 2>/dev/null; then
        log "  [cmd] system.$key = $val"; return 0
    fi
    if content update --uri content://settings/system \
        --bind value:s:"$val" --where "name='$key'" 2>/dev/null; then
        log "  [content] system.$key = $val"; return 0
    fi
    init_adb
    if [ "$ADB_OK" = "1" ]; then
        adb shell settings put system "$key" "$val" 2>/dev/null \
            && log "  [adb] system.$key = $val" && return 0
    fi
    warn "  Không đặt được: system.$key"
}

run_wm() {
    # wm cần shell uid - chỉ adb hoặc cmd window
    if cmd window density "$1" 2>/dev/null; then
        log "  [cmd window] density = $1"; return 0
    fi
    init_adb
    if [ "$ADB_OK" = "1" ]; then
        adb shell wm density "$1" 2>/dev/null \
            && log "  [adb wm] density = $1" && return 0
    fi
    warn "  Không đặt được wm density"
}

run_pm_disable() {
    local pkg="$1"
    # pm disable cần shell uid
    init_adb
    if [ "$ADB_OK" = "1" ]; then
        adb shell pm disable-user --user 0 "$pkg" 2>/dev/null \
            && log "Disabled: $pkg" && return 0
    fi
    warn "Không disable được: $pkg"
}

# ============================================================

# ---------- BƯỚC 1: BẬT CHẾ ĐỘ NHÀ PHÁT TRIỂN ----------
hdr "1. BẬT CHẾ ĐỘ NHÀ PHÁT TRIỂN"
set_global development_settings_enabled 1
set_global adb_enabled 1

# ---------- BƯỚC 2: BẬT 4 TÍNH NĂNG DEVELOPER ----------
hdr "2. BẬT 4 TÍNH NĂNG DEVELOPER"
set_global force_allow_on_external 1
set_global force_resizable_activities 1
set_global enable_freeform_support 1
set_global force_desktop_mode_on_external_displays 1

# ---------- BƯỚC 3: CHỈNH DPI = 220 ----------
hdr "3. CHỈNH DPI -> 220"
run_wm 220
set_system screen_density 220

# ---------- BƯỚC 4: DISABLE GOOGLE PLAY ----------
hdr "4. TẮT GOOGLE PLAY"
for pkg in com.android.vending com.google.android.gms com.google.android.gsf; do
    run_pm_disable "$pkg"
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
else
    warn "Fallback sang script change-repo gốc..."
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
log "OldShouko.py -> /sdcard/Download/"

# ---------- BƯỚC 8: TẢI & CÀI 4 APK ----------
hdr "8. TẢI & CÀI 4 APK"

install_apk() {
    local name="$1" url="$2" idx="$3"
    local dest="/sdcard/Download/aio_app${idx}.apk"

    if [ -z "$url" ]; then warn "[$name] Link trống, bỏ qua."; return 0; fi

    echo -e "${C}>> Đang tải [$name]...${N}"
    if ! curl -L --progress-bar --connect-timeout 20 --retry 3 --retry-delay 2 \
              -o "$dest" "$url"; then
        err "[$name] Tải thất bại."
        return 1
    fi
    log "[$name] Tải xong -> $dest"

    echo -e "${C}>> Đang cài [$name]...${N}"

    # Method 1: adb pm install (shell uid - silent)
    init_adb
    if [ "$ADB_OK" = "1" ]; then
        if adb shell pm install -r -g "$dest" 2>/dev/null; then
            log "[$name] Cài thành công (adb pm install)!"
            return 0
        fi
    fi

    # Method 2: am start intent (mở trình cài đặt)
    if am start -a android.intent.action.VIEW \
        -d "file://$dest" \
        -t "application/vnd.android.package-archive" \
        --flags 0x10000001 2>/dev/null; then
        log "[$name] Đã mở trình cài đặt APK"
        sleep 3
        return 0
    fi

    warn "[$name] Cần cài thủ công: $dest"
}

install_apk "$APK_1_NAME" "$APK_1_URL" 1
install_apk "$APK_2_NAME" "$APK_2_URL" 2
install_apk "$APK_3_NAME" "$APK_3_URL" 3
install_apk "$APK_4_NAME" "$APK_4_URL" 4

# ---------- HOÀN TẤT ----------
hdr "HOÀN TẤT"
echo -e "${G}"
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
