#!/data/data/com.termux/files/usr/bin/bash
clear
set -e

# ===== COLOR =====
BLUE='\033[1;34m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
RESET='\033[0m'

step () {
  echo -e "${BLUE}[$1]${RESET} $2"
}

ok () {
  echo -e "${GREEN}[✓]${RESET} $1"
}

warn () {
  echo -e "${YELLOW}[!]${RESET} $1"
}

fail () {
  echo -e "${RED}[X]${RESET} $1"
}

echo -e "${GREEN}===== UGPHONE AIO FINAL =====${RESET}\n"

# ===== 1. RESET STORAGE =====
step "1/8" "Reset Termux storage"
if [ -e "$HOME/storage" ]; then
  rm -rf "$HOME/storage"
fi
termux-setup-storage > /dev/null 2>&1
ok "Storage ready"

# ===== 2. UPDATE TERMUX =====
step "2/8" "Updating Termux packages"
yes | pkg update > /dev/null 2>&1
yes | pkg upgrade > /dev/null 2>&1
yes | pkg install -y python python-pip android-tools curl > /dev/null 2>&1
ok "Base packages installed"

# ===== 3. PIP SAFE CLEAN =====
step "3/8" "Preparing pip (Termux safe)"
pip cache purge > /dev/null 2>&1 || true
rm -rf ~/.cache/pip > /dev/null 2>&1 || true
ok "Pip cache cleaned"

# ===== 4. PYTHON LIBS =====
step "4/8" "Installing Python libraries"
for lib in requests rich prettytable pytz psutil gdown; do
  echo -ne "  - Installing $lib... "
  pip install --no-cache-dir --quiet "$lib" && echo "OK" || echo "FAIL"
done
ok "Python libraries ready"

# ===== 5. DOWNLOAD TOOL =====
step "5/8" "Downloading tool"
curl -fsSL \
https://raw.githubusercontent.com/Wraith1vs11/Rejoin/refs/heads/main/OldShouko.py \
-o /sdcard/Download/OldShouko.py
ok "Tool saved to Download"

# ===== 6. ROOT CHECK =====
step "6/8" "Checking root access"
if ! su -c id >/dev/null 2>&1; then
  fail "Root not available"
  exit 1
fi
ok "Root OK"

# ===== 7. SYSTEM UI / WINDOW SETTINGS =====
step "7/8" "Applying UI & window settings"

su -c "wm density 100" >/dev/null 2>&1
su -c "settings put global development_settings_enabled 1" >/dev/null 2>&1
su -c "settings put global force_resizable_activities 1" >/dev/null 2>&1
su -c "settings put global enable_freeform_support 1" >/dev/null 2>&1
su -c "settings put global force_desktop_mode_on_external_displays 1" >/dev/null 2>&1

ok "UI & window options applied"

# ===== 8. APK DOWNLOAD & INSTALL (UI INSTALLER) =====
step "8/8" "Downloading & installing APKs"

APK_DIR="/sdcard/Download/Farm-app"
rm -rf "$APK_DIR"
mkdir -p "$APK_DIR"

echo "  - Downloading APKs from Google Drive..."
gdown --folder \
https://drive.google.com/drive/folders/16dE9WRhm53lh7STAOGnwWPZya_c9WxOc \
--quiet

FOUND=0
for apk in "$APK_DIR"/*.apk; do
  [ -f "$apk" ] || continue
  FOUND=1
  echo -e "${BLUE}  → Installing:${RESET} $(basename "$apk")"

  am start -a android.intent.action.VIEW \
    -d "file://$apk" \
    -t application/vnd.android.package-archive >/dev/null 2>&1

  sleep 2
done

if [ "$FOUND" -eq 0 ]; then
  warn "No APK files found"
else
  ok "APK installer opened"
fi

echo
echo -e "${GREEN}===== ALL DONE =====${RESET}"
echo -e "${YELLOW}• Some window features depend on ROM support${RESET}"
echo -e "${YELLOW}• Reboot recommended for best effect${RESET}"
