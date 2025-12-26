#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "========== APK INSTALL TEST =========="
echo "[*] Current dir: $(pwd)"
echo "[*] Android version:"
getprop ro.build.version.release
echo "[*] ABI:"
getprop ro.product.cpu.abi
echo "======================================"

APK_DIR=$HOME/auto_apk_test
rm -rf "$APK_DIR"
mkdir -p "$APK_DIR"
cd "$APK_DIR"

echo "[+] Installing gdown..."
pip install -q gdown

echo "[+] Downloading APK from Drive..."
gdown --folder https://drive.google.com/drive/folders/16dE9WRhm53lh7STAOGnwWPZya_c9WxOc

echo
echo "[+] Files downloaded:"
ls -lh

echo
echo "[+] Testing APK install..."

for apk in *.apk; do
  echo "--------------------------------------"
  echo "[TEST] File: $apk"

  echo "[1] pm install"
  pm install "$apk"
  echo "[pm exit code] $?"

  echo
  echo "[2] adb install"
  adb install "$apk"
  echo "[adb exit code] $?"
done

echo
echo "========== TEST DONE =========="
