#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "===== UGPHONE APK INSTALL TEST ====="

# đảm bảo storage
if [ ! -d "$HOME/storage" ]; then
  termux-setup-storage
  echo "[!] Đã cấp quyền storage, chạy lại script"
  exit 0
fi

APK_DIR=/sdcard/Download/auto_apk_test
rm -rf "$APK_DIR"
mkdir -p "$APK_DIR"
cd "$APK_DIR"

echo "[+] Installing gdown..."
pip install -q gdown

echo "[+] Downloading APK to /sdcard/Download..."
gdown --folder https://drive.google.com/drive/folders/16dE9WRhm53lh7STAOGnwWPZya_c9WxOc

echo
echo "[+] Files downloaded:"
ls -lh

echo
echo "[+] Testing APK install..."

for apk in *.apk; do
  echo "-----------------------------"
  echo "[TEST] $apk"

  echo "[1] pm install"
  pm install "$apk" || echo "[!] pm install FAILED"

  echo "[2] adb install"
  adb install "$apk" || echo "[!] adb install FAILED"
done

echo "===== TEST DONE ====="
