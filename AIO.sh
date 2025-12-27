#!/data/data/com.termux/files/usr/bin/bash
set -e
cd ~

echo "===== UGPHONE AIO ROOT SETUP ====="

# ===== RESET STORAGE =====
if [ -e "/data/data/com.termux/files/home/storage" ]; then
  rm -rf /data/data/com.termux/files/home/storage
fi

termux-setup-storage

# ===== UPDATE TERMUX =====
yes | pkg update

# ===== CHANGE REPO =====
. <(curl -fsSL https://raw.githubusercontent.com/Wraith1vs11/Rejoin/refs/heads/main/termux-change-repo.sh)

yes | pkg upgrade
yes | pkg install -y python python-pip android-tools

# ===== PYTHON LIBS =====
pip install --no-cache-dir requests rich prettytable pytz

export CFLAGS="-Wno-error=implicit-function-declaration"
pip install --no-cache-dir psutil

# ===== DOWNLOAD TOOL PY =====
curl -Ls https://raw.githubusercontent.com/Wraith1vs11/Rejoin/refs/heads/main/OldShouko.py \
-o /sdcard/Download/OldShouko.py

# ===== ROOT CHECK =====
if ! su -c id >/dev/null 2>&1; then
  echo "[X] ROOT NOT AVAILABLE"
  exit 1
fi
echo "[✓] ROOT OK"

# ===== GOOGLE DRIVE APK =====
pip install --no-cache-dir gdown

APK_DIR=/sdcard/Download/auto_apk_root
rm -rf "$APK_DIR"
mkdir -p "$APK_DIR"
cd "$APK_DIR"

echo "[+] Download APK from Google Drive..."
gdown --folder https://drive.google.com/drive/folders/16dE9WRhm53lh7STAOGnwWPZya_c9WxOc

echo
echo "[+] Downloaded files:"
ls -lh

# ===== INSTALL APK (ROOT MODE) =====
cd "$APK_DIR" || exit 1
INSTALLED=0
FAILED=0

# Gom nhóm APK theo base name để detect split APK
for BASE in $(ls *.apk | sed 's/_.*//g' | sort -u); do
    FILES=$(ls ${BASE}*.apk 2>/dev/null)
    COUNT=$(echo "$FILES" | wc -l)

    echo "----------------------------------"
    echo "[INSTALL] $BASE ($COUNT file)"

    # SPLIT APK
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
done

echo
echo "============== SUMMARY ================"
echo " Installed groups : $INSTALLED"
echo " Failed groups    : $FAILED"
echo "======================================="
echo " ALL DONE "

echo
echo "===== ALL DONE ====="
