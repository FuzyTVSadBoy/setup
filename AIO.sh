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
rm -rf $PREFIX/var/lib/apt/lists/* $PREFIX/var/cache/apt/*

pkg update -y >/dev/null 2>&1
pkg install -y python python-pip android-tools curl >/dev/null 2>&1 \
  || { fail "Base packages install failed"; exit 1; }

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
  if pip install --no-cache-dir --quiet "$lib"; then
    echo -e "${GREEN}OK${RESET}"
  else
    echo -e "${RED}FAIL${RESET}"
  fi
done
line

# ================== 5. TOOL ==================
step "5/9" "Downloading tool"
if curl -fsSL https://raw.githubusercontent.com/Wraith1vs11/Rejoin/refs/heads/main/OldShouko.py \
  -o /sdcard/Download/OldShouko.py; then
  ok "Tool downloaded"
else
  warn "Tool download failed"
fi
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
step "7/9" "Changing Android ID"
HWID="f43f5764ee3f616a"
su -c "settings put secure android_id $HWID" >/dev/null 2>&1
ok "Android ID set"
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

# ================== 9. APK DOWNLOAD & INSTALL ==================
step "9/9" "Downloading & installing APKs"

APK_DIR="/sdcard/Download/"
rm -rf "$APK_DIR"
mkdir -p "$APK_DIR"
cd "$APK_DIR" || exit 1

SUCCESS=0
FAIL=0

echo "  • Downloading APKs..."
gdown --folder https://drive.google.com/drive/folders/16dE9WRhm53lh7STAOGnwWPZya_c9WxOc >/dev/null 2>&1

for apk in *.apk; do
  [ -f "$apk" ] || continue

  echo -e "${BLUE}→ Installing:${RESET} $apk"

  if su -c "pm install -r \"$APK_DIR/$apk\"" >/dev/null 2>&1; then
    ok "$apk installed (silent)"
    SUCCESS=$((SUCCESS+1))
  else
    warn "$apk silent failed → UI"
    am start -a android.intent.action.VIEW \
      -d "file://$APK_DIR/$apk" \
      -t application/vnd.android.package-archive >/dev/null 2>&1
    FAIL=$((FAIL+1))
    sleep 2
  fi
done

line
ok "Silent installed: $SUCCESS app(s)"
warn "UI fallback: $FAIL app(s)"

echo
echo -e "${GREEN}===== ALL DONE =====${RESET}"
echo -e "${YELLOW}• Reboot recommended${RESET}"
