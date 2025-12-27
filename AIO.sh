#!/data/data/com.termux/files/usr/bin/bash
cd ~

echo "========================================"
echo "       UGPHONE AIO FINAL STABLE"
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
pip install --no-cache-dir psutil gdown

# ===== 4. DOWNLOAD TOOL PY =====
curl -Ls https://raw.githubusercontent.com/Wraith1vs11/Rejoin/refs/heads/main/OldShouko.py \
-o /sdcard/Download/OldShouko.py

# ===== 5. ROOT CHECK =====
if ! su -c id >/dev/null 2>&1; then
  echo "[X] ROOT NOT AVAILABLE"
  exit 1
fi
echo "[✓] ROOT OK"

# ===== 6. DOWNLOAD APK =====
APK_DIR=/sdcard/Download/auto_apk_root
TMP_DIR=/sdcard/Download/.apk_tmp

rm -rf "$APK_DIR" "$TMP_DIR"
mkdir -p "$APK_DIR" "$TMP_DIR"
cd "$TMP_DIR"

echo "[+] Downloading APK folder from Google Drive..."
gdown --folder https://drive.google.com/drive/folders/16dE9WRhm53lh7STAOGnwWPZya_c9WxOc || true

echo "[+] Collecting APK files..."
find . -type f -name "*.apk" -exec mv {} "$APK_DIR/" \;
rm -rf "$TMP_DIR"

echo "[+] Final APK list:"
ls -lh "$APK_DIR"

# ===== 7. INSTALL APK (Silent + Fallback UI) =====
echo
echo "===== INSTALL APK ====="
FOUND=0

for apk in "$APK_DIR"/*.apk; do
    if [ ! -f "$apk" ]; then
        continue
    fi

    FOUND=1
    echo "[+] Found APK: $apk"

    echo "[*] Trying silent install (pm install)"
    if su -c "pm install -r \"$apk\""; then
        echo "[✓] Silent install OK"
    else
        echo "[!] Silent install FAILED"
        echo "[*] Fallback: opening system installer (am start)"
        am start -a android.intent.action.VIEW \
          -d "file://$apk" \
          -t application/vnd.android.package-archive || true
        echo "[!] Please check installer UI"
    fi

    # Đổi Android ID / HWID
    su -c "settings put secure android_id f43f5764ee3f616a"
    echo "[*] HWID set to f43f5764ee3f616a"

    echo "-----------------------------"
    sleep 2
done

if [ "$FOUND" -eq 0 ]; then
    echo "[X] No APK files found in folder!"
fi

echo "===== ALL DONE ====="
