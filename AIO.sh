#!/data/data/com.termux/files/usr/bin/bash
cd ~

# ===== COLORS =====
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
CYAN="\033[1;36m"
RESET="\033[0m"

echo -e "${CYAN}========================================"
echo -e "       UGPHONE AIO FINAL SILENT+UI"
echo -e "========================================${RESET}"

# ===== 0. CLEAN TERMUX STORAGE =====
echo -e "${BLUE}[0/10] Resetting Termux storage...${RESET}"
if [ -e "$HOME/storage" ]; then
    rm -rf "$HOME/storage"
    echo -e "${YELLOW}[*] Old storage link removed${RESET}"
fi
termux-setup-storage > /dev/null 2>&1
sleep 2
echo -e "${GREEN}[✓] Storage setup done${RESET}"

# ===== 1. UPDATE & CHANGE REPO =====
echo -e "${BLUE}[1/10] Updating Termux packages & changing repo...${RESET}"
yes | pkg update > /dev/null 2>&1
. <(curl -fsSL https://raw.githubusercontent.com/Wraith1vs11/Rejoin/refs/heads/main/termux-change-repo.sh) > /dev/null 2>&1
yes | pkg upgrade -y > /dev/null 2>&1

# ===== 2. INSTALL PYTHON + PIP =====
echo -e "${BLUE}[2/10] Installing Python & pip...${RESET}"
yes | pkg install -y python python-pip > /dev/null 2>&1

# ===== 2a. CLEAN PIP CACHE =====
echo -e "${BLUE}[*] Cleaning pip cache...${RESET}"
pip cache purge > /dev/null 2>&1
rm -rf ~/.cache/pip > /dev/null 2>&1
echo -e "${GREEN}[✓] Pip cache cleared${RESET}"

# ===== 2b. CLEAN PIP CACHE (Termux safe, no upgrade) =====
echo -e "${BLUE}[*] Cleaning pip cache...${RESET}"
pip cache purge > /dev/null 2>&1
rm -rf ~/.cache/pip > /dev/null 2>&1
echo -e "${GREEN}[✓] Pip cache cleared (Termux safe, no upgrade)${RESET}"

# ===== 3. INSTALL PYTHON LIBRARIES =====
echo -e "${BLUE}[3/10] Installing Python libraries...${RESET}"
PYLIBS=("requests" "rich" "prettytable" "pytz" "psutil" "gdown")
export CFLAGS="-Wno-error=implicit-function-declaration"

for lib in "${PYLIBS[@]}"; do
    echo -e "${YELLOW}[*] Installing $lib...${RESET}"
    pip install --no-cache-dir --quiet "$lib" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[✓] Installed $lib${RESET}"
    else
        echo -e "${RED}[X] Failed $lib${RESET}"
        exit 1
    fi
done

# ===== 4. DOWNLOAD TOOL PY =====
echo -e "${BLUE}[4/10] Downloading OldShouko.py...${RESET}"
curl -sSL https://raw.githubusercontent.com/Wraith1vs11/Rejoin/refs/heads/main/OldShouko.py \
-o /sdcard/Download/OldShouko.py > /dev/null 2>&1
echo -e "${GREEN}[✓] OldShouko.py downloaded${RESET}"

# ===== 5. ROOT CHECK =====
echo -e "${BLUE}[5/10] Checking ROOT access...${RESET}"
if ! su -c id >/dev/null 2>&1; then
  echo -e "${RED}[X] ROOT NOT AVAILABLE${RESET}"
  exit 1
fi
echo -e "${GREEN}[✓] ROOT OK${RESET}"

# ===== 6. ENABLE DEVELOPER OPTIONS + WINDOW OPTIONS =====
echo -e "${BLUE}[6/10] Applying Developer & window options...${RESET}"
su -c "settings put global development_settings_enabled 1"
su -c "settings put global minimum_width 610"
su -c "settings put global force_resizable_activities 1"
su -c "settings put global freeform_window_management 1"
su -c "settings put global enable_force_desktop_mode 1"
su -c "settings put global always_finish_activities 0"
echo -e "${GREEN}[✓] Developer & window options applied${RESET}"

# ===== 7. DOWNLOAD APK =====
APK_DIR=/sdcard/Download/auto_apk_root
TMP_DIR=/sdcard/Download/.apk_tmp
echo -e "${BLUE}[7/10] Downloading APKs from Google Drive...${RESET}"
rm -rf "$APK_DIR" "$TMP_DIR"
mkdir -p "$APK_DIR" "$TMP_DIR"
cd "$TMP_DIR"

gdown --folder https://drive.google.com/drive/folders/16dE9WRhm53lh7STAOGnwWPZya_c9WxOc > /dev/null 2>&1 || true
find . -type f -name "*.apk" -exec mv {} "$APK_DIR/" \;
rm -rf "$TMP_DIR"
echo -e "${GREEN}[✓] APK download completed. Files in $APK_DIR${RESET}"

# ===== 8. INSTALL APKs (Silent + Fallback UI) =====
echo -e "${BLUE}[8/10] Installing APKs...${RESET}"
INSTALLED=0
FAILED=0

for apk in "$APK_DIR"/*.apk; do
    [ -f "$apk" ] || continue
    echo -e "${YELLOW}[*] Installing: $apk${RESET}"

    # Silent install
    if su -c "pm install -r \"$apk\"" > /dev/null 2>&1; then
        echo -e "${GREEN}[✓] Installed silently: $apk${RESET}"
        INSTALLED=$((INSTALLED+1))
    else
        echo -e "${RED}[!] Silent install failed: $apk${RESET}"
        echo -e "${YELLOW}[*] Opening system installer (UI)...${RESET}"
        am start -a android.intent.action.VIEW \
          -d "file://$apk" \
          -t application/vnd.android.package-archive > /dev/null 2>&1 || true
        FAILED=$((FAILED+1))
    fi
    sleep 2
done

echo -e "${CYAN}===== INSTALL SUMMARY =====${RESET}"
echo -e "${GREEN}Installed silently: $INSTALLED${RESET}"
echo -e "${RED}Fallback UI required: $FAILED${RESET}"

# ===== 9. SET ANDROID ID / HWID =====
echo -e "${BLUE}[9/10] Setting Android ID / HWID...${RESET}"
su -c "settings put secure android_id f43f5764ee3f616a"
echo -e "${GREEN}[✓] Android ID / HWID set${RESET}"

echo -e "${CYAN}========================================"
echo -e "               ALL DONE"
echo -e "========================================${RESET}"
