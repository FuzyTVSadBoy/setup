#!/bin/bash
cd

# Reset storage (clean)
if [ -e "/data/data/com.termux/files/home/storage" ]; then
	rm -rf /data/data/com.termux/files/home/storage
fi

termux-setup-storage

yes | pkg update

# Change repo (script ngoài)
. <(curl -fsSL https://raw.githubusercontent.com/Wraith1vs11/Rejoin/refs/heads/main/termux-change-repo.sh)

yes | pkg upgrade
yes | pkg i python -y
yes | pkg i python-pip -y
yes | pkg i android-tools -y

# Python libs
pip install --no-cache-dir requests rich prettytable pytz

# Fix build psutil
export CFLAGS="-Wno-error=implicit-function-declaration"
pip install --no-cache-dir psutil

# ---- DOWNLOAD PY TOOL ----
curl -Ls https://raw.githubusercontent.com/Wraith1vs11/Rejoin/refs/heads/main/OldShouko.py \
-o /sdcard/Download/OldShouko.py

# ---- GOOGLE DRIVE APK AUTO INSTALL ----
pip install --no-cache-dir gdown

APK_DIR=$HOME/auto_apk
mkdir -p "$APK_DIR"
cd "$APK_DIR"

# 👉 THAY FOLDER_ID Ở ĐÂY
gdown --folder https://drive.google.com/drive/folders/16dE9WRhm53lh7STAOGnwWPZya_c9WxOc --quiet

# Install all APK
for apk in *.apk; do
	echo "[+] Installing $apk"
	pm install --user 0 "$apk" >/dev/null 2>&1
done

echo "[✓] ALL DONE"
