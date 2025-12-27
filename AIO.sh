#!/data/data/com.termux/files/usr/bin/bash
set -e
cd ~

echo "========================================"
echo "       UGPHONE AIO FINAL SETUP"
echo "========================================"

# ===== 1. TERMUX STORAGE =====
if [ -e "$HOME/storage" ]; then
  rm -rf "$HOME/storage"
fi
termux-setup-storage
sleep 2

# ===== 2. UPDATE & CHANGE REPO =====
yes | pkg update
. <(curl -fsSL https://raw.githubusercontent.com/Wraith1vs11/Rejoin/refs/heads/main/termux-change-repo.sh)
yes | pkg upgrade

# ===== 3. INSTALL PYTHON + TOOLS =====
yes | pkg install -y python python-pip android-tools curl wget
pip install --upgrade pip
pip install --no-cache-dir requests rich prettytable pytz
export CFLAGS="-Wno-error=implicit-function-declaration"
pip install --no-cache-dir psutil
pip install --no-cache-dir gdown

# ===== 4. DOWNLOAD TOOL PY =====
curl -Ls https://raw.githubusercontent.com/Wraith1vs11/Rejoin/refs/heads/main/OldShouko.py \
-o /sdcard/Download/OldShouko.py

# ===== 5. ROOT CHECK =====
if ! su -c id >/dev/null 2>&1; then
  echo "[X] ROOT NOT AVAILABLE"
  exit 1
fi
echo "[✓] ROOT OK"

# ===== 6. DOWNLOAD APK FROM GOOGLE DRIVE =====
APK_DIR=/sdcard/Download/auto_apk_root
TMP_DIR=/sdcard/Download/.apk_tmp

rm -rf "$APK_DIR" "$TMP_DIR"
mkdir -p "$APK_DIR" "$TMP_DIR"
cd "$TMP_DIR"

echo "[+] Downloading APK folder from Google Drive..."
gdown --folder https://drive.google.com/drive/folders/16dE9WRhm53lh7STAOGnwWPZya_c9WxOc

echo "[+] Collecting APK files..."
find . -type f -name "*.apk" -exec mv {} "$APK_DIR/" \;
rm -rf "$TMP_DIR"

echo "[+] Final APK list:"
ls -lh "$APK_DIR"

# ===== 7. INSTALL APK =====
cd "$APK_DIR" || exit 1
INSTALLED=0
FAILED=0

for BASE in $(ls *.apk | sed 's/_.*//g' | sort -u); do
    FILES=$(ls ${BASE}*.apk 2>/dev/null)
    COUNT=$(echo "$FILES" | wc -l)

    echo "----------------------------------"
    echo "[INSTALL] $BASE ($COUNT file)"

    if [ "$COUNT" -gt 1 ]; then
        echo "    → Split APK detected"
        if su -c "pm install-multiple $FILES"; then
            echo "    ✓ Installed"
            INSTALLED=$((INSTALLED+1))
        else
            echo "    ✗ Failed → fallback UI"
            for apk in $FILES; do
                am start -a android.intent.action.VIEW \
                  -d "file://$APK_DIR/$apk" \
                  -t application/vnd.android.package-archive
                sleep 2
            done
            FAILED=$((FAILED+1))
        fi
    else
        APK_FILE="$FILES"
        echo "    → Single APK"
        if su -c "pm install -r \"$APK_DIR/$APK_FILE\""; then
            echo "    ✓ Installed"
            INSTALLED=$((INSTALLED+1))
        else
            echo "    ✗ Failed → fallback UI"
            am start -a android.intent.action.VIEW \
              -d "file://$APK_DIR/$APK_FILE" \
              -t application/vnd.android.package-archive
            FAILED=$((FAILED+1))
        fi
    fi

    # Change Android ID / HWID
    su -c "settings put secure android_id f43f5764ee3f616a"
    echo "    → HWID set to f43f5764ee3f616a"

done

echo
echo "============== SUMMARY ================"
echo " Installed groups : $INSTALLED"
echo " Failed groups    : $FAILED"
echo "======================================="
echo " ALL DONE "
