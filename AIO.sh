#!/data/data/com.termux/files/usr/bin/bash
clear

# ================== UI ==================
BLUE='\033[1;34m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
CYAN='\033[1;36m'
RESET='\033[0m'

line() { echo -e "${CYAN}----------------------------------------${RESET}"; }
step() { echo -e "${BLUE}[$1]${RESET} $2"; }
ok()   { echo -e "${GREEN}[✓]${RESET} $1"; }
warn() { echo -e "${YELLOW}[!]${RESET} $1"; }
fail() { echo -e "${RED}[X]${RESET} $1"; }

echo -e "${GREEN}===== UGPHONE AIO FINAL =====${RESET}"
line

# ================== 1. STORAGE ==================
step "1/9" "Reset Termux storage"
rm -rf "$HOME/storage" 2>/dev/null
termux-setup-storage >/dev/null 2>&1
ok "Storage ready"
line

# ================== 2. TERMUX ENV ==================
step "2/9" "Preparing Termux environment"

rm -rf $PREFIX/var/lib/apt/lists/*
rm -rf $PREFIX/var/cache/apt/*

pkg update >/dev/null || warn "Repo update warning (ignored)"

pkg install -y python python-pip android-tools curl >/dev/null || {
  fail "Failed to install base packages"
  exit 1
}

ok "Base packages ready"
line

# ================== 3. PIP SAFE ==================
step "3/9" "Preparing pip"
pip cache purge >/dev/null 2>&1 || true
rm -rf ~/.cache/pip >/dev/null 2>&1
ok "Pip ready"
line

# ================== 4. PY LIBS ==================
step "4/9" "Installing Python libraries"
for lib in requests rich prettytable pytz psutil gdown; do
  echo -ne "  • $lib ... "
  pip install --no-cache-dir --quiet "$lib" \
    && echo -e "${GREEN}OK${RESET}" \
    || echo -e "${RED}FAIL${RESET}"
done
line

# ================== 5. TOOL ==================
step "5/9" "Downloading tool"
curl -fsSL \
https://raw.githubusercontent.com/Wraith1vs11/Rejoin/refs/heads/main/OldShouko.py \
-o /sdcard/Download/OldShouko.py \
&& ok "Tool downloaded" \
|| warn "Tool download failed"
line

# ================== 6. ROOT ==================
step "6/9" "Checking root"
if ! su -c id >/dev/null 2>&1; then
  fail "Root not available"
  exit 1
fi
ok "Root OK"
line

# ================== 7. HWID ==================
step "7/9" "Changing Android ID (HWID)"
HWID="f43f5764ee3f616a"
su -c "settings put secure android_id $HWID" >/dev/null 2>&1
ok "Android ID set to $HWID"
line

# ================== 8. UI / WINDOW ==================
step "8/9" "Applying UI & window settings"
su -c "wm density 200" >/dev/null 2>&1
su -c "settings put global development_settings_enabled 1" >/dev/null 2>&1
su -c "settings put global force_resizable_activities 1" >/dev/null 2>&1
su -c "settings put global enable_freeform_support 1" >/dev/null 2>&1
su -c "settings put global force_desktop_mode_on_external_displays 1" >/dev/null 2>&1
ok "UI options applied"
line

# ===== 9. APK DOWNLOAD & INSTALL (FIXED) =====
step "9/9" "Downloading & installing APKs"

APK_DIR="/sdcard/Download/Farm-app"
rm -rf "$APK_DIR"
mkdir -p "$APK_DIR"
cd "$APK_DIR" || exit 1

echo "  • Downloading APKs..."
gdown --folder https://drive.google.com/drive/folders/16dE9WRhm53lh7STAOGnwWPZya_c9WxOc

FOUND=0

for apk in *.apk; do
  [ -f "$apk" ] || continue
  FOUND=1

  echo -e "${BLUE}→ Installing:${RESET} $apk"

  if su -c "pm install -r \"$APK_DIR/$apk\"" >/dev/null 2>&1; then
    ok "$apk installed (silent)"
  else
    warn "$apk silent failed → UI fallback"
    am start -a android.intent.action.VIEW \
      -d "file://$APK_DIR/$apk" \
      -t application/vnd.android.package-archive >/dev/null 2>&1
    sleep 2
  fi
done

if [ "$FOUND" -eq 0 ]; then
  warn "No APK found"
else
  ok "APK process completed"
fi
ok "Silent success: $SUCCESS"
warn "UI fallback: $FAIL"

line
ok "APK success: $SUCCESS"
warn "APK fallback UI: $FAIL"

echo
echo -e "${GREEN}===== ALL DONE =====${RESET}"
echo -e "${YELLOW}• Reboot recommended for full effect${RESET}"
