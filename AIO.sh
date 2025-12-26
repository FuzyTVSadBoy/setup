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
for apk in *.apk; do
  echo "----------------------------------"
  echo "[INSTALL] $apk"

  if su -c "pm install '$APK_DIR/$apk'"; then
    echo "[✓] Installed $apk"
  else
    echo "[X] Failed $apk"
  fi
su -c "settings put secure android_id f43f5764ee3f616a"
echo "Change HWID to f43f5764ee3f616a"
done

echo
echo "===== ALL DONE ====="
