from prettytable import PrettyTable
import threading
import time
import json
import requests
import subprocess
import sqlite3
import shutil
import pytz
import traceback
import random
import psutil
import sys
import gc
import os
import http.server
import socketserver
from rich.table import Table
from rich.panel import Panel
from rich.text import Text
from rich.align import Align
from rich.box import ROUNDED
from rich.console import Console
from datetime import datetime, timezone
from threading import Lock, Event
from psutil import boot_time, process_iter, cpu_percent, virtual_memory, Process, NoSuchProcess, AccessDenied, ZombieProcess

package_lock = Lock()
status_lock = Lock()
rejoin_lock = Lock()
bot_instance = None
bot_thread = None
socket_server = None
stop_webhook_thread = False
webhook_thread = None
webhook_url = None
device_name = None
webhook_interval = None
reset_tab_interval = None
close_and_rejoin_delay = None
boot_time = boot_time()
auto_android_id_enabled = False
auto_android_id_thread = None
auto_android_id_value = None

globals()["_disable_ui"] = "0"
globals()["package_statuses"] = {}
globals()["_uid_"] = {}
globals()["_user_"] = {}
globals()["is_runner_ez"] = False
globals()["check_exec_enable"] = "1"

executors = {
    "Fluxus": "/storage/emulated/0/Fluxus/",
    "Fluxus Clone 001": "/storage/emulated/0/RobloxClone001/Fluxus/",
    "Fluxus Clone 002": "/storage/emulated/0/RobloxClone002/Fluxus/",
    "Fluxus Clone 003": "/storage/emulated/0/RobloxClone003/Fluxus/",
    "Fluxus Clone 004": "/storage/emulated/0/RobloxClone004/Fluxus/",
    "Fluxus Clone 005": "/storage/emulated/0/RobloxClone005/Fluxus/",
    "Fluxus Clone 006": "/storage/emulated/0/RobloxClone006/Fluxus/",
    "Fluxus Clone 007": "/storage/emulated/0/RobloxClone007/Fluxus/",
    "Fluxus Clone 008": "/storage/emulated/0/RobloxClone008/Fluxus/",
    "Fluxus Clone 009": "/storage/emulated/0/RobloxClone009/Fluxus/",
    "Fluxus Clone 010": "/storage/emulated/0/RobloxClone010/Fluxus/",
    "Fluxus Clone 011": "/storage/emulated/0/RobloxClone011/Fluxus/",
    "Fluxus Clone 012": "/storage/emulated/0/RobloxClone012/Fluxus/",
    "Fluxus Clone 013": "/storage/emulated/0/RobloxClone013/Fluxus/",
    "Fluxus Clone 014": "/storage/emulated/0/RobloxClone014/Fluxus/",
    "Fluxus Clone 015": "/storage/emulated/0/RobloxClone015/Fluxus/",
    "Fluxus Clone 016": "/storage/emulated/0/RobloxClone016/Fluxus/",
    "Fluxus Clone 017": "/storage/emulated/0/RobloxClone017/Fluxus/",
    "Fluxus Clone 018": "/storage/emulated/0/RobloxClone018/Fluxus/",
    "Fluxus Clone 019": "/storage/emulated/0/RobloxClone019/Fluxus/",
    "Fluxus Clone 020": "/storage/emulated/0/RobloxClone020/Fluxus/",
    "Codex": "/storage/emulated/0/Codex/",
    "Codex Clone 001": "/storage/emulated/0/RobloxClone001/Codex/",
    "Codex Clone 002": "/storage/emulated/0/RobloxClone002/Codex/",
    "Codex Clone 003": "/storage/emulated/0/RobloxClone003/Codex/",
    "Codex Clone 004": "/storage/emulated/0/RobloxClone004/Codex/",
    "Codex Clone 005": "/storage/emulated/0/RobloxClone005/Codex/",
    "Codex Clone 006": "/storage/emulated/0/RobloxClone006/Codex/",
    "Codex Clone 007": "/storage/emulated/0/RobloxClone007/Codex/",
    "Codex Clone 008": "/storage/emulated/0/RobloxClone008/Codex/",
    "Codex Clone 009": "/storage/emulated/0/RobloxClone009/Codex/",
    "Codex Clone 010": "/storage/emulated/0/RobloxClone010/Codex/",
    "Codex Clone 011": "/storage/emulated/0/RobloxClone011/Codex/",
    "Codex Clone 012": "/storage/emulated/0/RobloxClone012/Codex/",
    "Codex Clone 013": "/storage/emulated/0/RobloxClone013/Codex/",
    "Codex Clone 014": "/storage/emulated/0/RobloxClone014/Codex/",
    "Codex Clone 015": "/storage/emulated/0/RobloxClone015/Codex/",
    "Codex Clone 016": "/storage/emulated/0/RobloxClone016/Codex/",
    "Codex Clone 017": "/storage/emulated/0/RobloxClone017/Codex/",
    "Codex Clone 018": "/storage/emulated/0/RobloxClone018/Codex/",
    "Codex Clone 019": "/storage/emulated/0/RobloxClone019/Codex/",
    "Codex Clone 020": "/storage/emulated/0/RobloxClone020/Codex/",
    "Codex VNG Clone 001": "/storage/emulated/0/RobloxVNGClone001/Codex/",
    "Codex VNG Clone 002": "/storage/emulated/0/RobloxVNGClone002/Codex/",
    "Codex VNG Clone 003": "/storage/emulated/0/RobloxVNGClone003/Codex/",
    "Codex VNG Clone 004": "/storage/emulated/0/RobloxVNGClone004/Codex/",
    "Codex VNG Clone 005": "/storage/emulated/0/RobloxVNGClone005/Codex/",
    "Codex VNG Clone 006": "/storage/emulated/0/RobloxVNGClone006/Codex/",
    "Codex VNG Clone 007": "/storage/emulated/0/RobloxVNGClone007/Codex/",
    "Codex VNG Clone 008": "/storage/emulated/0/RobloxVNGClone008/Codex/",
    "Codex VNG Clone 009": "/storage/emulated/0/RobloxVNGClone009/Codex/",
    "Codex VNG Clone 010": "/storage/emulated/0/RobloxVNGClone010/Codex/",
    "Codex VNG Clone 011": "/storage/emulated/0/RobloxVNGClone011/Codex/",
    "Codex VNG Clone 012": "/storage/emulated/0/RobloxVNGClone012/Codex/",
    "Codex VNG Clone 013": "/storage/emulated/0/RobloxVNGClone013/Codex/",
    "Codex VNG Clone 014": "/storage/emulated/0/RobloxVNGClone014/Codex/",
    "Codex VNG Clone 015": "/storage/emulated/0/RobloxVNGClone015/Codex/",
    "Codex VNG Clone 016": "/storage/emulated/0/RobloxVNGClone016/Codex/",
    "Codex VNG Clone 017": "/storage/emulated/0/RobloxVNGClone017/Codex/",
    "Codex VNG Clone 018": "/storage/emulated/0/RobloxVNGClone018/Codex/",
    "Codex VNG Clone 019": "/storage/emulated/0/RobloxVNGClone019/Codex/",
    "Codex VNG Clone 020": "/storage/emulated/0/RobloxVNGClone020/Codex/",
    "Arceus X": "/storage/emulated/0/Arceus X/",
    "Arceus X Clone 001": "/storage/emulated/0/RobloxClone001/Arceus X/",
    "Arceus X Clone 002": "/storage/emulated/0/RobloxClone002/Arceus X/",
    "Arceus X Clone 003": "/storage/emulated/0/RobloxClone003/Arceus X/",
    "Arceus X Clone 004": "/storage/emulated/0/RobloxClone004/Arceus X/",
    "Arceus X Clone 005": "/storage/emulated/0/RobloxClone005/Arceus X/",
    "Arceus X Clone 006": "/storage/emulated/0/RobloxClone006/Arceus X/",
    "Arceus X Clone 007": "/storage/emulated/0/RobloxClone007/Arceus X/",
    "Arceus X Clone 008": "/storage/emulated/0/RobloxClone008/Arceus X/",
    "Arceus X Clone 009": "/storage/emulated/0/RobloxClone009/Arceus X/",
    "Arceus X Clone 010": "/storage/emulated/0/RobloxClone010/Arceus X/",
    "Arceus X Clone 011": "/storage/emulated/0/RobloxClone011/Arceus X/",
    "Arceus X Clone 012": "/storage/emulated/0/RobloxClone012/Arceus X/",
    "Arceus X Clone 013": "/storage/emulated/0/RobloxClone013/Arceus X/",
    "Arceus X Clone 014": "/storage/emulated/0/RobloxClone014/Arceus X/",
    "Arceus X Clone 015": "/storage/emulated/0/RobloxClone015/Arceus X/",
    "Arceus X Clone 016": "/storage/emulated/0/RobloxClone016/Arceus X/",
    "Arceus X Clone 017": "/storage/emulated/0/RobloxClone017/Arceus X/",
    "Arceus X Clone 018": "/storage/emulated/0/RobloxClone018/Arceus X/",
    "Arceus X Clone 019": "/storage/emulated/0/RobloxClone019/Arceus X/",
    "Arceus X Clone 020": "/storage/emulated/0/RobloxClone020/Arceus X/",
    "Arceus X VNG Clone 001": "/storage/emulated/0/RobloxVNGClone001/Arceus X/",
    "Arceus X VNG Clone 002": "/storage/emulated/0/RobloxVNGClone002/Arceus X/",
    "Arceus X VNG Clone 003": "/storage/emulated/0/RobloxVNGClone003/Arceus X/",
    "Arceus X VNG Clone 004": "/storage/emulated/0/RobloxVNGClone004/Arceus X/",
    "Arceus X VNG Clone 005": "/storage/emulated/0/RobloxVNGClone005/Arceus X/",
    "Arceus X VNG Clone 006": "/storage/emulated/0/RobloxVNGClone006/Arceus X/",
    "Arceus X VNG Clone 007": "/storage/emulated/0/RobloxVNGClone007/Arceus X/",
    "Arceus X VNG Clone 008": "/storage/emulated/0/RobloxVNGClone008/Arceus X/",
    "Arceus X VNG Clone 009": "/storage/emulated/0/RobloxVNGClone009/Arceus X/",
    "Arceus X VNG Clone 010": "/storage/emulated/0/RobloxVNGClone010/Arceus X/",
    "Arceus X VNG Clone 011": "/storage/emulated/0/RobloxVNGClone011/Arceus X/",
    "Arceus X VNG Clone 012": "/storage/emulated/0/RobloxVNGClone012/Arceus X/",
    "Arceus X VNG Clone 013": "/storage/emulated/0/RobloxVNGClone013/Arceus X/",
    "Arceus X VNG Clone 014": "/storage/emulated/0/RobloxVNGClone014/Arceus X/",
    "Arceus X VNG Clone 015": "/storage/emulated/0/RobloxVNGClone015/Arceus X/",
    "Arceus X VNG Clone 016": "/storage/emulated/0/RobloxVNGClone016/Arceus X/",
    "Arceus X VNG Clone 017": "/storage/emulated/0/RobloxVNGClone017/Arceus X/",
    "Arceus X VNG Clone 018": "/storage/emulated/0/RobloxVNGClone018/Arceus X/",
    "Arceus X VNG Clone 019": "/storage/emulated/0/RobloxVNGClone019/Arceus X/",
    "Arceus X VNG Clone 020": "/storage/emulated/0/RobloxVNGClone020/Arceus X/",
    "RonixExploit": "/storage/emulated/0/RonixExploit/",
    "RonixExploit Clone 001": "/storage/emulated/0/RobloxClone001/RonixExploit/",
    "RonixExploit Clone 002": "/storage/emulated/0/RobloxClone002/RonixExploit/",
    "RonixExploit Clone 003": "/storage/emulated/0/RobloxClone003/RonixExploit/",
    "RonixExploit Clone 004": "/storage/emulated/0/RobloxClone004/RonixExploit/",
    "RonixExploit Clone 005": "/storage/emulated/0/RobloxClone005/RonixExploit/",
    "RonixExploit Clone 006": "/storage/emulated/0/RobloxClone006/RonixExploit/",
    "RonixExploit Clone 007": "/storage/emulated/0/RobloxClone007/RonixExploit/",
    "RonixExploit Clone 008": "/storage/emulated/0/RobloxClone008/RonixExploit/",
    "RonixExploit Clone 009": "/storage/emulated/0/RobloxClone009/RonixExploit/",
    "RonixExploit Clone 010": "/storage/emulated/0/RobloxClone010/RonixExploit/",
    "RonixExploit Clone 011": "/storage/emulated/0/RobloxClone011/RonixExploit/",
    "RonixExploit Clone 012": "/storage/emulated/0/RobloxClone012/RonixExploit/",
    "RonixExploit Clone 013": "/storage/emulated/0/RobloxClone013/RonixExploit/",
    "RonixExploit Clone 014": "/storage/emulated/0/RobloxClone014/RonixExploit/",
    "RonixExploit Clone 015": "/storage/emulated/0/RobloxClone015/RonixExploit/",
    "RonixExploit Clone 016": "/storage/emulated/0/RobloxClone016/RonixExploit/",
    "RonixExploit Clone 017": "/storage/emulated/0/RobloxClone017/RonixExploit/",
    "RonixExploit Clone 018": "/storage/emulated/0/RobloxClone018/RonixExploit/",
    "RonixExploit Clone 019": "/storage/emulated/0/RobloxClone019/RonixExploit/",
    "RonixExploit Clone 020": "/storage/emulated/0/RobloxClone020/RonixExploit/",
    "RonixExploit VNG Clone 001": "/storage/emulated/0/RobloxVNGClone001/RonixExploit/",
    "RonixExploit VNG Clone 002": "/storage/emulated/0/RobloxVNGClone002/RonixExploit/",
    "RonixExploit VNG Clone 003": "/storage/emulated/0/RobloxVNGClone003/RonixExploit/",
    "RonixExploit VNG Clone 004": "/storage/emulated/0/RobloxVNGClone004/RonixExploit/",
    "RonixExploit VNG Clone 005": "/storage/emulated/0/RobloxVNGClone005/RonixExploit/",
    "RonixExploit VNG Clone 006": "/storage/emulated/0/RobloxVNGClone006/RonixExploit/",
    "RonixExploit VNG Clone 007": "/storage/emulated/0/RobloxVNGClone007/RonixExploit/",
    "RonixExploit VNG Clone 008": "/storage/emulated/0/RobloxVNGClone008/RonixExploit/",
    "RonixExploit VNG Clone 009": "/storage/emulated/0/RobloxVNGClone009/RonixExploit/",
    "RonixExploit VNG Clone 010": "/storage/emulated/0/RobloxVNGClone010/RonixExploit/",
    "RonixExploit VNG Clone 011": "/storage/emulated/0/RobloxVNGClone011/RonixExploit/",
    "RonixExploit VNG Clone 012": "/storage/emulated/0/RobloxVNGClone012/RonixExploit/",
    "RonixExploit VNG Clone 013": "/storage/emulated/0/RobloxVNGClone013/RonixExploit/",
    "RonixExploit VNG Clone 014": "/storage/emulated/0/RobloxVNGClone014/RonixExploit/",
    "RonixExploit VNG Clone 015": "/storage/emulated/0/RobloxVNGClone015/RonixExploit/",
    "RonixExploit VNG Clone 016": "/storage/emulated/0/RobloxVNGClone016/RonixExploit/",
    "RonixExploit VNG Clone 017": "/storage/emulated/0/RobloxVNGClone017/RonixExploit/",
    "RonixExploit VNG Clone 018": "/storage/emulated/0/RobloxVNGClone018/RonixExploit/",
    "RonixExploit VNG Clone 019": "/storage/emulated/0/RobloxVNGClone019/RonixExploit/",
    "RonixExploit VNG Clone 020": "/storage/emulated/0/RobloxVNGClone020/RonixExploit/",
    "Delta": "/storage/emulated/0/Delta/",
    "Delta Clone 001": "/storage/emulated/0/RobloxClone001/Delta/",
    "Delta Clone 002": "/storage/emulated/0/RobloxClone002/Delta/",
    "Delta Clone 003": "/storage/emulated/0/RobloxClone003/Delta/",
    "Delta Clone 004": "/storage/emulated/0/RobloxClone004/Delta/",
    "Delta Clone 005": "/storage/emulated/0/RobloxClone005/Delta/",
    "Delta Clone 006": "/storage/emulated/0/RobloxClone006/Delta/",
    "Delta Clone 007": "/storage/emulated/0/RobloxClone007/Delta/",
    "Delta Clone 008": "/storage/emulated/0/RobloxClone008/Delta/",
    "Delta Clone 009": "/storage/emulated/0/RobloxClone009/Delta/",
    "Delta Clone 010": "/storage/emulated/0/RobloxClone010/Delta/",
    "Delta Clone 011": "/storage/emulated/0/RobloxClone011/Delta/",
    "Delta Clone 012": "/storage/emulated/0/RobloxClone012/Delta/",
    "Delta Clone 013": "/storage/emulated/0/RobloxClone013/Delta/",
    "Delta Clone 014": "/storage/emulated/0/RobloxClone014/Delta/",
    "Delta Clone 015": "/storage/emulated/0/RobloxClone015/Delta/",
    "Delta Clone 016": "/storage/emulated/0/RobloxClone016/Delta/",
    "Delta Clone 017": "/storage/emulated/0/RobloxClone017/Delta/",
    "Delta Clone 018": "/storage/emulated/0/RobloxClone018/Delta/",
    "Delta Clone 019": "/storage/emulated/0/RobloxClone019/Delta/",
    "Delta Clone 020": "/storage/emulated/0/RobloxClone020/Delta/",
    "Cryptic": "/storage/emulated/0/Cryptic/",
    "Cryptic Clone 001": "/storage/emulated/0/RobloxClone001/Cryptic/",
    "Cryptic Clone 002": "/storage/emulated/0/RobloxClone002/Cryptic/",
    "Cryptic Clone 003": "/storage/emulated/0/RobloxClone003/Cryptic/",
    "Cryptic Clone 004": "/storage/emulated/0/RobloxClone004/Cryptic/",
    "Cryptic Clone 005": "/storage/emulated/0/RobloxClone005/Cryptic/",
    "Cryptic Clone 006": "/storage/emulated/0/RobloxClone006/Cryptic/",
    "Cryptic Clone 007": "/storage/emulated/0/RobloxClone007/Cryptic/",
    "Cryptic Clone 008": "/storage/emulated/0/RobloxClone008/Cryptic/",
    "Cryptic Clone 009": "/storage/emulated/0/RobloxClone009/Cryptic/",
    "Cryptic Clone 010": "/storage/emulated/0/RobloxClone010/Cryptic/",
    "Cryptic Clone 011": "/storage/emulated/0/RobloxClone011/Cryptic/",
    "Cryptic Clone 012": "/storage/emulated/0/RobloxClone012/Cryptic/",
    "Cryptic Clone 013": "/storage/emulated/0/RobloxClone013/Cryptic/",
    "Cryptic Clone 014": "/storage/emulated/0/RobloxClone014/Cryptic/",
    "Cryptic Clone 015": "/storage/emulated/0/RobloxClone015/Cryptic/",
    "Cryptic Clone 016": "/storage/emulated/0/RobloxClone016/Cryptic/",
    "Cryptic Clone 017": "/storage/emulated/0/RobloxClone017/Cryptic/",
    "Cryptic Clone 018": "/storage/emulated/0/RobloxClone018/Cryptic/",
    "Cryptic Clone 019": "/storage/emulated/0/RobloxClone019/Cryptic/",
    "Cryptic Clone 020": "/storage/emulated/0/RobloxClone020/Cryptic/",
    "KRNL": "/storage/emulated/0/krnl/",
    "Trigon": "/storage/emulated/0/Trigon/",
    "FrostWare": "/storage/emulated/0/FrostWare/",
    "FrostWare Clone 001": "/storage/emulated/0/RobloxClone001/FrostWare/",
    "FrostWare Clone 002": "/storage/emulated/0/RobloxClone002/FrostWare/",
    "FrostWare Clone 003": "/storage/emulated/0/RobloxClone003/FrostWare/",
    "FrostWare Clone 004": "/storage/emulated/0/RobloxClone004/FrostWare/",
    "FrostWare Clone 005": "/storage/emulated/0/RobloxClone005/FrostWare/",
    "FrostWare Clone 006": "/storage/emulated/0/RobloxClone006/FrostWare/",
    "FrostWare Clone 007": "/storage/emulated/0/RobloxClone007/FrostWare/",
    "FrostWare Clone 008": "/storage/emulated/0/RobloxClone008/FrostWare/",
    "FrostWare Clone 009": "/storage/emulated/0/RobloxClone009/FrostWare/",
    "FrostWare Clone 010": "/storage/emulated/0/RobloxClone010/FrostWare/",
    "FrostWare Clone 011": "/storage/emulated/0/RobloxClone011/FrostWare/",
    "FrostWare Clone 012": "/storage/emulated/0/RobloxClone012/FrostWare/",
    "FrostWare Clone 013": "/storage/emulated/0/RobloxClone013/FrostWare/",
    "FrostWare Clone 014": "/storage/emulated/0/RobloxClone014/FrostWare/",
    "FrostWare Clone 015": "/storage/emulated/0/RobloxClone015/FrostWare/",
    "FrostWare Clone 016": "/storage/emulated/0/RobloxClone016/FrostWare/",
    "FrostWare Clone 017": "/storage/emulated/0/RobloxClone017/FrostWare/",
    "FrostWare Clone 018": "/storage/emulated/0/RobloxClone018/FrostWare/",
    "FrostWare Clone 019": "/storage/emulated/0/RobloxClone019/FrostWare/",
    "FrostWare Clone 020": "/storage/emulated/0/RobloxClone020/FrostWare/",
    "Evon": "/storage/emulated/0/Evon/",
}
workspace_paths = [f"{base_path}Workspace" for base_path in executors.values()] + \
                  [f"{base_path}workspace" for base_path in executors.values()]
globals()["workspace_paths"] = workspace_paths
globals()["executors"] = executors

if not os.path.exists("Shouko.dev"):
    os.makedirs("Shouko.dev", exist_ok=True)
SERVER_LINKS_FILE = "Shouko.dev/server-links.txt"
ACCOUNTS_FILE = "Shouko.dev/accounts.txt"
CONFIG_FILE = "Shouko.dev/config.json"

version = "2.2.6 | Created By Shouko.dev | Bug Fixes By Nexus Hideout"

class Utilities:
    @staticmethod
    def collect_garbage():
        gc.collect()

    @staticmethod
    def log_error(error_message):
        with open("error_log.txt", "a") as error_log:
            error_log.write(f"{error_message}\n\n")

    @staticmethod
    def clear_screen():
        os.system('cls' if os.name == 'nt' else 'clear')

    @staticmethod
    def get_hwid_codex():
        return subprocess.run(["settings", "get", "secure", "android_id"], capture_output=True, text=True, check=True).stdout.strip()

    @staticmethod
    def calculate_time_left(expiry_timestamp):
        current_time = int(time.time())
        time_left = expiry_timestamp / 1000 - current_time
        return time_left

    @staticmethod
    def format_time_left(time_left):
        hours, remainder = divmod(time_left, 3600)
        minutes, seconds = divmod(remainder, 60)
        return f"{int(hours):02} hour(s) {int(minutes):02} minute(s) {int(seconds):02} second(s)"

    @staticmethod
    def convert_to_ho_chi_minh_time(expiry_timestamp):
        ho_chi_minh_tz = pytz.timezone("Asia/Ho_Chi_Minh")
        expiry_datetime = datetime.fromtimestamp(expiry_timestamp / 1000, pytz.utc)
        expiry_datetime = expiry_datetime.astimezone(ho_chi_minh_tz)
        return expiry_datetime.strftime("%Y-%m-%d %H:%M:%S")

class FileManager:
    SERVER_LINKS_FILE = "Shouko.dev/server-link.txt"
    ACCOUNTS_FILE = "Shouko.dev/account.txt"
    CONFIG_FILE = "Shouko.dev/config-wh.json"

    @staticmethod
    def setup_user_ids():
        print("\033[1;32m[ Shouko.dev ] - Auto-detecting User IDs from app packages...\033[0m")
        packages = RobloxManager.get_roblox_packages()
        accounts = []
        if not packages:
            print("\033[1;31m[ Shouko.dev ] - No Roblox packages detected to set up User IDs.\033[0m")
            return []

        for package_name in packages:
            file_path = f'/data/data/{package_name}/files/appData/LocalStorage/appStorage.json'
            try:
                user_id = FileManager.find_userid_from_file(file_path)
                if user_id and user_id != "-1":
                    accounts.append((package_name, user_id))
                    print(f"\033[96m[ Shouko.dev ] - Found UserID for {package_name}: {user_id}\033[0m")
                else:
                    print(f"\033[1;31m[ Shouko.dev ] - UserID not found for {package_name}.\033[0m")
            except Exception as e:
                print(f"\033[1;31m[ Shouko.dev ] - Error reading file for {package_name}: {e}\033[0m")
                Utilities.log_error(f"Error reading appStorage.json for {package_name}: {e}")

        if accounts:
            FileManager.save_accounts(accounts)
            print("\033[1;32m[ Shouko.dev ] - User IDs have been successfully saved.\033[0m")
        else:
            print("\033[1;31m[ Shouko.dev ] - Could not find any valid User IDs to set up.\033[0m")
        
        return accounts

    @staticmethod
    def save_server_links(server_links):
        try:
            os.makedirs(os.path.dirname(FileManager.SERVER_LINKS_FILE), exist_ok=True)
            with open(FileManager.SERVER_LINKS_FILE, "w") as file:
                for package, link in server_links:
                    file.write(f"{package},{link}\n")
            print("\033[1;32m[ Shouko.dev ] - Server links saved successfully.\033[0m")
        except IOError as e:
            print(f"\033[1;31m[ Shouko.dev ] - Error saving server links: {e}\033[0m")
            Utilities.log_error(f"Error saving server links: {e}")

    @staticmethod
    def load_server_links():
        server_links = []
        if os.path.exists(FileManager.SERVER_LINKS_FILE):
            with open(FileManager.SERVER_LINKS_FILE, "r") as file:
                for line in file:
                    package, link = line.strip().split(",", 1)
                    server_links.append((package, link))
        return server_links

    @staticmethod
    def save_accounts(accounts):
        with open(FileManager.ACCOUNTS_FILE, "w") as file:
            for package, user_id in accounts:
                file.write(f"{package},{user_id}\n")

    @staticmethod
    def load_accounts():
        accounts = []
        if os.path.exists(FileManager.ACCOUNTS_FILE):
            with open(FileManager.ACCOUNTS_FILE, "r") as file:
                for line in file:
                    line = line.strip()
                    if line:
                        try:
                            package, user_id = line.split(",", 1)
                            globals()["_user_"][package] = user_id
                            accounts.append((package, user_id))
                        except ValueError:
                            print(f"\033[1;31m[ Shouko.dev ] - Invalid line format: {line}. Expected format 'package,user_id'.\033[0m")
        return accounts

    @staticmethod
    def find_userid_from_file(file_path):
        try:
            with open(file_path, 'r') as file:
                content = file.read()
                userid_start = content.find('"UserId":"')
                if userid_start == -1:
                    return None

                userid_start += len('"UserId":"')
                userid_end = content.find('"', userid_start)
                if userid_end == -1:
                    return None

                userid = content[userid_start:userid_end]
                return userid

        except IOError as e:
            print(f"\033[1;31m[ Shouko.dev ] - Error reading file: {e}\033[0m")
            return None

    @staticmethod
    def get_username(user_id):
        user = FileManager.load_saved_username(user_id)
        if user is not None:
            return user
        retry_attempts = 2
        for attempt in range(retry_attempts):
            try:
                url = f"https://users.roblox.com/v1/users/{user_id}"
                response = requests.get(url, timeout=10)
                response.raise_for_status()
                data = response.json()
                username = data.get("name", "Unknown")
                if username != "Unknown":
                    FileManager.save_username(user_id, username)
                    return username
            except requests.exceptions.RequestException as e:
                print(f"\033[1;31m[ Shouko.dev ] - Attempt {attempt + 1} failed for Roblox Users API: {e}\033[0m")
                time.sleep(2 ** attempt)

        for attempt in range(retry_attempts):
            try:
                url = f"https://users.roproxy.com/v1/users/{user_id}"
                response = requests.get(url, timeout=10)
                response.raise_for_status()
                data = response.json()
                username = data.get("name", "Unknown")
                if username != "Unknown":
                    FileManager.save_username(user_id, username)
                    return username
            except requests.exceptions.RequestException as e:
                print(f"\033[1;31m[ Shouko.dev ] - Attempt {attempt + 1} failed for RoProxy API: {e}\033[0m")
                time.sleep(2 ** attempt)

        return "Unknown"

    @staticmethod
    def save_username(user_id, username):
        try:
            if not os.path.exists("usernames.json"):
                with open("usernames.json", "w") as file:
                    json.dump({user_id: username}, file)
            else:
                with open("usernames.json", "r+") as file:
                    try:
                        data = json.load(file)
                    except json.JSONDecodeError:
                        data = {}
                    data[user_id] = username
                    file.seek(0)
                    json.dump(data, file)
                    file.truncate()
        except (IOError, json.JSONDecodeError) as e:
            print(f"\033[1;31m[ Shouko.dev ] - Error saving username: {e}\033[0m")

    @staticmethod
    def load_saved_username(user_id):
        try:
            with open("usernames.json", "r") as file:
                data = json.load(file)
                return data.get(user_id, None)
        except (FileNotFoundError, json.JSONDecodeError, IOError) as e:
            print(f"\033[1;31m[ Shouko.dev ] - Error loading username: {e}\033[0m")
            return None

    @staticmethod
    def download_file(url, destination, binary=False):
        try:
            response = requests.get(url, stream=True)
            if response.status_code == 200:
                mode = 'wb' if binary else 'w'
                with open(destination, mode) as file:
                    if binary:
                        shutil.copyfileobj(response.raw, file)
                    else:
                        file.write(response.text)
                print(f"\033[1;32m[ Shouko.dev ] - {os.path.basename(destination)} downloaded successfully.\033[0m")
                return destination
            else:
                error_message = f"Failed to download {os.path.basename(destination)}. Status code: {response.status_code}"
                print(f"\033[1;31m[ Shouko.dev ] - {error_message}\033[0m")
                Utilities.log_error(error_message)
                return None
        except requests.RequestException as e:
            error_message = f"Request exception while downloading {os.path.basename(destination)}: {e}"
            print(f"\033[1;31m[ Shouko.dev ] - {error_message}\033[0m")
            Utilities.log_error(error_message)
            return None
        except Exception as e:
            error_message = f"Unexpected error while downloading {os.path.basename(destination)}: {e}"
            print(f"\033[1;31m[ Shouko.dev ] - {error_message}\033[0m")
            Utilities.log_error(error_message)
            return None

    @staticmethod
    def _load_config():
        global webhook_url, device_name, webhook_interval, close_and_rejoin_delay, reset_tab_interval
        try:
            if os.path.exists(FileManager.CONFIG_FILE):
                with open(FileManager.CONFIG_FILE, "r") as file:
                    config = json.load(file)
                    webhook_url = config.get("webhook_url", None)
                    device_name = config.get("device_name", None)
                    webhook_interval = config.get("interval", float('inf'))
                    globals()["_disable_ui"] = config.get("disable_ui", "0")
                    globals()["check_exec_enable"] = config.get("check_executor", "1")
                    globals()["command_8_configured"] = config.get("command_8_configured", False)
                    globals()["lua_script_template"] = config.get("lua_script_template", None)
                    globals()["package_prefix"] = config.get("package_prefix", "com.roblox")
                    close_and_rejoin_delay = config.get("close_and_rejoin_delay", None)
                    reset_tab_interval = config.get("reset_tab_interval", None)
            else:
                webhook_url = None
                device_name = None
                webhook_interval = float('inf')
                globals()["_disable_ui"] = "0"
                globals()["check_exec_enable"] = "1"
                globals()["command_8_configured"] = False
                globals()["lua_script_template"] = None
                globals()["package_prefix"] = "com.roblox"
                close_and_rejoin_delay = None
                reset_tab_interval = None
        except Exception as e:
            print(f"\033[1;31m[ Shouko.dev ] - Error loading configuration: {e}\033[0m")
            Utilities.log_error(f"Error loading configuration: {e}")

    @staticmethod
    def save_config():
        try:
            config = {
                "webhook_url": webhook_url,
                "device_name": device_name,
                "interval": webhook_interval,
                "disable_ui": globals().get("_disable_ui", "0"),
                "check_executor": globals()["check_exec_enable"],
                "command_8_configured": globals().get("command_8_configured", False),
                "lua_script_template": globals().get("lua_script_template", None),
                "package_prefix": globals().get("package_prefix", "com.roblox"),
            }
            with open(FileManager.CONFIG_FILE, "w") as file:
                json.dump(config, file, indent=4, sort_keys=True)
            print("\033[1;32m[ Shouko.dev ] - Configuration saved successfully.\033[0m")
        except Exception as e:
            print(f"\033[1;31m[ Shouko.dev ] - Error saving configuration: {e}\033[0m")
            Utilities.log_error(f"Error saving configuration: {e}")

    @staticmethod
    def check_and_create_cookie_file():
        folder_path = os.path.dirname(os.path.abspath(__file__))
        cookie_file_path = os.path.join(folder_path, 'cookie.txt')
        if not os.path.exists(cookie_file_path):
            with open(cookie_file_path, 'w') as f:
                f.write("")

class SystemMonitor:
    @staticmethod
    def capture_screenshot():
        screenshot_path = "/storage/emulated/0/Download/screenshot.png"
        try:
            os.system(f"/system/bin/screencap -p {screenshot_path}")
            if not os.path.exists(screenshot_path):
                raise FileNotFoundError("Screenshot file was not created.")
            return screenshot_path
        except Exception as e:
            print(f"\033[1;31m[ Shouko.dev ] - Error capturing screenshot: {e}\033[0m")
            Utilities.log_error(f"Error capturing screenshot: {e}")
            return None

    @staticmethod
    def get_uptime():
        current_time = time.time()
        uptime_seconds = current_time - psutil.boot_time()
        days = int(uptime_seconds // (24 * 3600))
        hours = int((uptime_seconds % (24 * 3600)) // 3600)
        minutes = int((uptime_seconds % 3600) // 60)
        seconds = int(uptime_seconds % 60)
        return f"{days}d {hours}h {minutes}m {seconds}s"

    @staticmethod
    def roblox_processes():
        package_names = []
        package_namez = RobloxManager.get_roblox_packages()
        for proc in process_iter(['name', 'pid', 'memory_info', 'cpu_percent']):
            try:
                proc_name = proc.info['name']
                for package_name in package_namez:
                    if proc_name.lower() == package_name[-15:].lower():
                        mem_usage = proc.info['memory_info'].rss / (1024 ** 2)
                        mem_usage_rounded = round(mem_usage, 2)
                        cpu_usage = proc.cpu_percent(interval=1) / psutil.cpu_count(logical=True)
                        cpu_usage_rounded = round(cpu_usage, 2)
                        full_name = package_name
                        package_names.append(f"{full_name} (PID: {proc.pid}, CPU: {cpu_usage_rounded}%, MEM: {mem_usage_rounded}MB)")
                        break
            except (NoSuchProcess, AccessDenied, ZombieProcess):
                continue
        return package_names

    @staticmethod
    def get_memory_usage():
        try:
            process = Process(os.getpid())
            mem_info = process.memory_info()
            mem_usage_mb = mem_info.rss / (1024 ** 2)
            return round(mem_usage_mb, 2)
        except Exception as e:
            print(f"\033[1;31m[ Shouko.dev ] - Error getting memory usage: {e}\033[0m")
            Utilities.log_error(f"Error getting memory usage: {e}")
            return None

    @staticmethod
    def get_system_info():
        try:
            cpu_usage = cpu_percent(interval=1)
            memory_info = virtual_memory()
            system_info = {
                "cpu_usage": cpu_usage,
                "memory_total": round(memory_info.total / (1024 ** 3), 2),
                "memory_used": round(memory_info.used / (1024 ** 3), 2),
                "memory_percent": memory_info.percent,
                "uptime": SystemMonitor.get_uptime(),
                "roblox_packages": SystemMonitor.roblox_processes()
            }
            return system_info
        except Exception as e:
            print(f"\033[1;31m[ Shouko.dev ] - Error retrieving system information: {e}\033[0m")
            Utilities.log_error(f"Error retrieving system information: {e}")
            return False

class RobloxManager:
    @staticmethod
    def get_cookie():
        try:
            current_dir = os.getcwd()
            cookie_txt_path = os.path.join(current_dir, "cookie.txt")
            new_dir_path = os.path.join(current_dir, "Shouko.dev/Shoụko.dev - Data")
            new_cookie_path = os.path.join(new_dir_path, "cookie.txt")

            if not os.path.exists(new_dir_path):
                os.makedirs(new_dir_path)

            if not os.path.exists(cookie_txt_path):
                print("\033[1;31m[ Shouko.dev ] - cookie.txt not found in the current directory!\033[0m")
                Utilities.log_error("cookie.txt not found in the current directory.")
                return False

            cookies = []
            org = []

            with open(cookie_txt_path, "r") as file:
                for line in file.readlines():
                    parts = str(line).strip().split(":")
                    if len(parts) == 4:
                        ck = ":".join(parts[2:])
                    else:
                        ck = str(line).strip()
                    if ck.startswith("_|WARNING:"):
                        org.append(str(line).strip())
                        cookies.append(ck)

            if len(cookies) == 0:
                print("\033[1;31m[ Shouko.dev ] - No valid cookies found in cookie.txt. Please add cookies.\033[0m")
                Utilities.log_error("No valid cookies found in cookie.txt.")
                return False

            cookie = cookies.pop(0)
            original_line = org.pop(0)

            with open(new_cookie_path, "a") as new_file:
                new_file.write(original_line + "\n")

            with open(cookie_txt_path, "w") as file:
                file.write("\n".join(org))

            return cookie

        except Exception as e:
            print(f"\033[1;31m[ Shouko.dev ] - Error: {e}\033[0m")
            Utilities.log_error(f"Error in get_cookie: {e}")
            return False

    @staticmethod
    def verify_cookie(cookie_value):
        try:
            headers = {
                'Cookie': f'.ROBLOSECURITY={cookie_value}',
                'User-Agent': 'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Mobile Safari/537.36',
                'Referer': 'https://www.roblox.com/',
                'Origin': 'https://www.roblox.com',
                'Accept-Language': 'en-US,en;q=0.9',
                'Accept-Encoding': 'gzip, deflate, br',
                'Connection': 'keep-alive'
            }

            time.sleep(1)

            response = requests.get('https://users.roblox.com/v1/users/authenticated', headers=headers)

            if response.status_code == 200:
                print("\033[1;32m[ Shouko.dev ] - Cookie is valid! User is authenticated.\033[0m")
                return response.json().get("id", False)
            elif response.status_code == 401:
                print("\033[1;31m[ Shouko.dev ] - Invalid cookie. The user is not authenticated.\033[0m")
                return False
            else:
                error_message = f"Error verifying cookie: {response.status_code} - {response.text}"
                print(f"\033[1;31m[ Shouko.dev ] - {error_message}\033[0m")
                Utilities.log_error(error_message)
                return False

        except requests.RequestException as e:
            error_message = f"Request exception occurred while verifying cookie: {e}"
            print(f"\033[1;31m[ Shouko.dev ] - {error_message}\033[0m")
            Utilities.log_error(error_message)
            return False

        except Exception as e:
            error_message = f"Unexpected exception occurred while verifying cookie: {e}"
            print(f"\033[1;31m[ Shouko.dev ] - {error_message}\033[0m")
            Utilities.log_error(error_message)
            return False

    @staticmethod
    def check_user_online(user_id, cookie=None):
        max_retries = 2
        delay = 2
        body = {"userIds": [user_id]}
        headers = {"Content-Type": "application/json"}
        if cookie is not None:
            headers["Cookie"] = f".ROBLOSECURITY={cookie}"
        for attempt in range(max_retries):
            try:
                with requests.Session() as session:
                    primary_response = session.post("https://presence.roblox.com/v1/presence/users", headers=headers, json=body, timeout=7)
                primary_response.raise_for_status()
                primary_data = primary_response.json()
                primary_presence_type = primary_data["userPresences"][0]["userPresenceType"]
                return primary_presence_type

            except requests.exceptions.RequestException as e:
                print(f"\033[1;31mError checking online status for user {user_id} (Attempt {attempt + 1}) for Roblox API: {e}\033[0m")
                if attempt < max_retries - 1:
                    time.sleep(delay)
                    delay *= 2

        headers = {"Content-Type": "application/json"}
        for attempt in range(max_retries):
            try:
                with requests.Session() as session:
                    primary_response = session.post("https://presence.roproxy.com/v1/presence/users", headers=headers, json=body, timeout=7)
                primary_response.raise_for_status()
                primary_data = primary_response.json()
                primary_presence_type = primary_data["userPresences"][0]["userPresenceType"]
                return primary_presence_type

            except requests.exceptions.RequestException as e:
                print(f"\033[1;31mError checking online status for user {user_id} (Attempt {attempt + 1}) for RoProxy API: {e}\033[0m")
                if attempt < max_retries - 1:
                    time.sleep(delay)
                    delay *= 2
                else:
                    return None

    @staticmethod
    def get_roblox_packages():
        packages = []
        try:
            package_prefix = globals().get("package_prefix", "com.roblox")
            result = subprocess.run(f"pm list packages {package_prefix} | sed 's/package://'", shell=True, capture_output=True, text=True)
            if result.returncode == 0:
                for line in result.stdout.strip().splitlines():
                    name = line.strip()
                    packages.append(name)
            else:
                print(f"\033[1;31m[ Shouko.dev ] - Failed to retrieve packages with prefix {package_prefix}.\033[0m")
                Utilities.log_error(f"Failed to retrieve packages with prefix {package_prefix}. Return code: {result.returncode}")
        except Exception as e:
            print(f"\033[1;31m[ Shouko.dev ] - Error retrieving packages: {e}\033[0m")
            Utilities.log_error(f"Error retrieving packages: {e}")
        return packages

    @staticmethod
    def kill_roblox_processes():
        packages = RobloxManager.get_roblox_packages()
        running = SystemMonitor.roblox_processes()
        if not running:
            print("\033[1;32m[ Shouko.dev ] - No Roblox processes to kill.\033[0m")
            return
        for package_name in packages:
            if any(package_name in proc for proc in running):
                os.system(f"nohup /system/bin/am force-stop {package_name} > /dev/null 2>&1 &")
        time.sleep(2)

    @staticmethod
    def kill_roblox_process(package_name):
        print(f"\033[1;96m[ Shouko.dev ] - Killing Roblox process for {package_name}...\033[0m")
        try:
            subprocess.run(
                ["/system/bin/am", "force-stop", package_name],
                capture_output=True,
                text=True,
                check=True
            )
            print(f"\033[1;32m[ Shouko.dev ] - Killed process for {package_name}\033[0m")
            time.sleep(2)
        except subprocess.CalledProcessError as e:
            print(f"\033[1;31m[ Shouko.dev ] - Error killing process for {package_name}: {e}\033[0m")
            Utilities.log_error(f"Error killing process for {package_name}: {e}")

    @staticmethod
    def delete_cache_for_package(package_name):
        cache_path = f'/data/data/{package_name}/cache/'
        if os.path.exists(cache_path):
            os.system(f"rm -rf {cache_path}")
            print(f"\033[1;32m[ Shouko.dev ] - Cache cleared for {package_name}\033[0m")
        else:
            print(f"\033[1;93m[ Shouko.dev ] - No cache found for {package_name}\033[0m")

    @staticmethod
    def launch_roblox(package_name, server_link):
        try:
            RobloxManager.kill_roblox_process(package_name)
            time.sleep(2)

            with status_lock:
                globals()["_uid_"][globals()["_user_"][package_name]] = time.time()
                globals()["package_statuses"][package_name]["Status"] = f"\033[1;36mOpening Roblox for {package_name}...\033[0m"
                UIManager.update_status_table()

            subprocess.run([
                'am', 'start',
                '-a', 'android.intent.action.MAIN',
                '-n', f'{package_name}/com.roblox.client.startup.ActivitySplash'
            ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

            time.sleep(10)

            with status_lock:
                globals()["package_statuses"][package_name]["Status"] = f"\033[1;36mJoining Roblox for {package_name}...\033[0m"
                UIManager.update_status_table()

            subprocess.run([
                'am', 'start',
                '-a', 'android.intent.action.VIEW',
                '-n', f'{package_name}/com.roblox.client.ActivityProtocolLaunch',
                '-d', server_link
            ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

            time.sleep(20)
            with status_lock:
                globals()["package_statuses"][package_name]["Status"] = "\033[1;32mJoined Roblox\033[0m"
                UIManager.update_status_table()

        except Exception as e:
            error_message = f"Error launching Roblox for {package_name}: {e}"
            with status_lock:
                globals()["package_statuses"][package_name]["Status"] = f"\033[1;31m{error_message}\033[0m"
                UIManager.update_status_table()
            print(f"\033[1;31m[ Shouko.dev ] - {error_message}\033[0m")
            Utilities.log_error(error_message)

    @staticmethod
    def inject_cookies_and_appstorage():
        RobloxManager.kill_roblox_processes()
        db_url = "https://raw.githubusercontent.com/nghvit/module/refs/heads/main/import/Cookies"
        appstorage_url = "https://raw.githubusercontent.com/nghvit/module/refs/heads/main/import/appStorage.json"

        downloaded_db_path = FileManager.download_file(db_url, "Cookies.db", binary=True)
        downloaded_appstorage_path = FileManager.download_file(appstorage_url, "appStorage.json", binary=False)

        if not downloaded_db_path or not downloaded_appstorage_path:
            print("\033[1;31m[ Shouko.dev ] - Failed to download necessary files. Exiting.\033[0m")
            Utilities.log_error("Failed to download necessary files for cookie and appStorage injection.")
            return

        packages = RobloxManager.get_roblox_packages()
        if not packages:
            print("\033[1;31m[ Shouko.dev ] - No Roblox packages detected.\033[0m")
            return

        for package_name in packages:
            try:
                cookie = RobloxManager.get_cookie()
                if not cookie:
                    print(f"\033[1;31m[ Shouko.dev ] - Failed to retrieve a cookie for {package_name}. Skipping...\033[0m")
                    break

                user_id = RobloxManager.verify_cookie(cookie)
                if user_id:
                    print(f"\033[1;32m[ Shouko.dev ] - Cookie for {package_name} is valid! User ID: {user_id}\033[0m")
                else:
                    print(f"\033[1;31m[ Shouko.dev ] - Cookie for {package_name} is invalid. Skipping injection...\033[0m")
                    continue

                print(f"\033[1;32m[ Shouko.dev ] - Injecting cookie for {package_name}: {cookie}\033[0m")

                destination_db_dir = f"/data/data/{package_name}/app_webview/Default/"
                destination_appstorage_dir = f"/data/data/{package_name}/files/appData/LocalStorage/"
                os.makedirs(destination_db_dir, exist_ok=True)
                os.makedirs(destination_appstorage_dir, exist_ok=True)

                destination_db_path = os.path.join(destination_db_dir, "Cookies")
                shutil.copyfile(downloaded_db_path, destination_db_path)
                print(f"\033[1;32m[ Shouko.dev ] - Copied Cookies.db to {destination_db_path}\033[0m")

                destination_appstorage_path = os.path.join(destination_appstorage_dir, "appStorage.json")
                shutil.copyfile(downloaded_appstorage_path, destination_appstorage_path)
                print(f"\033[1;32m[ Shouko.dev ] - Copied appStorage.json to {destination_appstorage_path}\033[0m")

                RobloxManager.replace_cookie_value_in_db(destination_db_path, cookie)

            except Exception as e:
                error_message = f"Error injecting cookie for {package_name}: {e}"
                print(f"\033[1;31m[ Shouko.dev ] - {error_message}\033[0m")
                Utilities.log_error(error_message)

        print("\033[1;32m[ Shouko.dev ] - Opening all Roblox tabs...\033[0m")
        failed_packages = []
        for package_name in packages:
            try:
                print(f"\033[1;36m[ Shouko.dev ] - Launching {package_name}...\033[0m")
                cmd_splash = [
                    'am', 'start',
                    '-a', 'android.intent.action.MAIN',
                    '-n', f'{package_name}/com.roblox.client.startup.ActivitySplash'
                ]
                result_splash = subprocess.run(cmd_splash, capture_output=True, text=True)
                if result_splash.returncode != 0:
                    error_message = f"Failed to open Roblox for {package_name}: {result_splash.stderr}"
                    print(f"\033[1;31m[ Shouko.dev ] - {error_message}\033[0m")
                    Utilities.log_error(error_message)
                    failed_packages.append(package_name)
                else:
                    print(f"\033[1;32m[ Shouko.dev ] - Successfully launched {package_name}\033[0m")
            except Exception as e:
                error_message = f"Error launching {package_name}: {e}"
                print(f"\033[1;31m[ Shouko.dev ] - {error_message}\033[0m")
                Utilities.log_error(error_message)
                failed_packages.append(package_name)

        if failed_packages:
            print(f"\033[1;31m[ Shouko.dev ] - Failed to launch packages: {', '.join(failed_packages)}\033[0m")
        else:
            print("\033[1;32m[ Shouko.dev ] - Successfully launched all packages.\033[0m")

        print("\033[1;33m[ Shouko.dev ] - Waiting for all tabs to load (1 minute)...\033[0m")
        time.sleep(60)

        debug_mode = input("\033[1;93m[ Shouko.dev ] - Keep Roblox tabs open for debugging? (y/n): \033[0m").strip().lower()
        if debug_mode != 'y':
            print("\033[1;33m[ Shouko.dev ] - Closing all Roblox tabs after loading...\033[0m")
            RobloxManager.kill_roblox_processes()
            time.sleep(5)
        else:
            print("\033[1;33m[ Shouko.dev ] - Keeping Roblox tabs open for debugging.\033[0m")

        print("\033[1;32m[ Shouko.dev ] - Cookie and appStorage injection, followed by app launch, completed for all packages.\033[0m")

    @staticmethod
    def replace_cookie_value_in_db(db_path, new_cookie_value):
        try:
            conn = sqlite3.connect(db_path)
            cursor = conn.cursor()
            cursor.execute("UPDATE cookies SET value = ?, last_access_utc = ?, expires_utc = ? WHERE host_key = '.roblox.com' AND name = '.ROBLOSECURITY'", (new_cookie_value, int(time.time() + 11644473600) * 1000000, int(time.time() + 11644473600 + 31536000) * 1000000))
            conn.commit()
            conn.close()
            print("\033[1;32mCookie value replaced successfully in the database!\033[0m")
        except sqlite3.OperationalError as e:
            print(f"\033[1;31mDatabase error during cookie replacement: {e}\033[0m")
        except Exception as e:
            print(f"\033[1;31mError replacing cookie value in database: {e}\033[0m")

    @staticmethod
    def format_server_link(input_link):
        if 'roblox.com' in input_link:
            return input_link
        elif input_link.isdigit():
            return f'roblox://placeID={input_link}'
        else:
            print("\033[1;31m[ Shouko.dev ] - Invalid input! Please enter a valid game ID or private server link.\033[0m")
            return None

class WebhookManager:
    @staticmethod
    def start_webhook_thread():
        global webhook_thread, stop_webhook_thread
        if (webhook_thread is None or not webhook_thread.is_alive()) and not stop_webhook_thread:
            stop_webhook_thread = False
            webhook_thread = threading.Thread(target=WebhookManager.send_webhook)
            webhook_thread.start()

    @staticmethod
    def send_webhook():
        global stop_webhook_thread
        while not stop_webhook_thread:
            try:
                screenshot_path = SystemMonitor.capture_screenshot()
                if not screenshot_path:
                    continue

                info = SystemMonitor.get_system_info()
                if not info:
                    continue

                cpu = f"{info['cpu_usage']:.1f}%"
                mem_used = f"{info['memory_used']:.2f} GB"
                mem_total = f"{info['memory_total']:.2f} GB"
                mem_percent = f"{info['memory_percent']:.1f}%"
                uptime = info['uptime']
                roblox_count = len(info['roblox_packages'])
                roblox_status = f"Running: {roblox_count} instance{'s' if roblox_count != 1 else ''}"
                roblox_details = "\n".join(info['roblox_packages']) if info['roblox_packages'] else "None"

                tool_mem_usage = SystemMonitor.get_memory_usage()
                tool_mem_display = f"{tool_mem_usage} MB" if tool_mem_usage is not None else "Unavailable"

                if roblox_count > 0:
                    status_text = f"🟢 Online"
                else:
                    status_text = "🔴 Offline"

                random_color = random.randint(0, 16777215)

                embed = {
                    "color": random_color,
                    "title": "📈 System Status Monitor",
                    "description": f"Real-time report for **{device_name}**",
                    "fields": [
                        {"name": "🏷️ Device", "value": f"```{device_name}```", "inline": True},
                        {"name": "💾 Total Memory", "value": f"```{mem_total}```", "inline": True},
                        {"name": "⏰ Uptime", "value": f"```{uptime}```", "inline": True},
                        {"name": "⚡ CPU Usage", "value": f"```{cpu}```", "inline": True},
                        {"name": "📊 Memory Usage", "value": f"```{mem_used} ({mem_percent})```", "inline": True},
                        {"name": "🛠️ Tool Memory Usage", "value": f"```{tool_mem_display}```", "inline": True},
                        {"name": "🎮 Total Roblox Processes", "value": f"```{roblox_status}```", "inline": True},
                        {"name": "🔍 Roblox Details", "value": f"```{roblox_details}```", "inline": False},
                        {"name": "✅ Status", "value": f"```{status_text}```", "inline": True}
                    ],
                    "thumbnail": {"url": "https://i.imgur.com/5yXNxU4.png"},
                    "image": {"url": "attachment://screenshot.png"},
                    "footer": {"text": f"Made with 💖 by Shouko.dev | Join us at discord.gg/rokidmanager",
                               "icon_url": "https://i.imgur.com/5yXNxU4.png"},
                    "timestamp": datetime.now(timezone.utc).isoformat(),
                    "author": {"name": "Shouko.dev",
                               "url": "https://discord.gg/rokidmanager",
                               "icon_url": "https://i.imgur.com/5yXNxU4.png"}
                }

                with open(screenshot_path, "rb") as file:
                    response = requests.post(
                        webhook_url,
                        data={"payload_json": json.dumps({"embeds": [embed], "username": "Shouko.dev", "avatar_url": "https://i.imgur.com/5yXNxU4.png"})},
                        files={"file": ("screenshot.png", file)}
                    )

                if response.status_code not in (200, 204):
                    print(f"\033[1;31m[ Shouko.dev ] - Error sending device info: {response.status_code}\033[0m")
                    Utilities.log_error(f"Error sending webhook: Status code {response.status_code}")

            except Exception as e:
                print(f"\033[1;31m[ Shouko.dev ] - Webhook error: {e}\033[0m")
                Utilities.log_error(f"Error in webhook thread: {e}")

            time.sleep(webhook_interval * 60)

    @staticmethod
    def stop_webhook():
        global stop_webhook_thread
        stop_webhook_thread = True

    @staticmethod
    def setup_webhook():
        global webhook_url, device_name, webhook_interval, stop_webhook_thread
        try:
            stop_webhook_thread = True
            webhook_url = input("\033[1;35m[ Shouko.dev ] - Enter your Webhook URL: \033[0m")
            device_name = input("\033[1;35m[ Shouko.dev ] - Enter your device name: \033[0m")
            webhook_interval = int(input("\033[1;35m[ Shouko.dev ] - Enter the interval to send Webhook (minutes): \033[0m"))
            FileManager.save_config()
            stop_webhook_thread = False
            threading.Thread(target=WebhookManager.send_webhook).start()
        except Exception as e:
            print(f"\033[1;31m[ Shouko.dev ] - Error during webhook setup: {e}\033[0m")
            Utilities.log_error(f"Error during webhook setup: {e}")

class UIManager:
    @staticmethod
    def print_header(version):
        console = Console()
        header = Text(r"""
      _                   _             _          
     | |                 | |           | |          
 ___| |__   ___  _   _| | _____   __| | _____   __
/ __| '_ \ / _ \| | | | |/ / _ \ / _` |/ _ \ \ / /
\__ \ | | | (_) | |_| |   < (_) | (_| |  __/\ V / 
|___/_| |_|\___/ \__,_|_|\_\___(_)__,_|\___| \_/  
        """, style="bold yellow")

        config_file = os.path.join("Shouko.dev", "config.json")
        check_executor = "1"
        
        if os.path.exists(config_file):
            try:
                with open(config_file, "r") as f:
                    config = json.load(f)
                    check_executor = config.get("check_executor", "0")
            except Exception as e:
                console.print(f"[bold red][ Shouko.dev ] - Error reading {config_file}: {e}[/bold red]")

        console.print(header)
        console.print(f"[bold yellow]- Version: [/bold yellow][bold white]{version}[/bold white]")
        console.print(f"[bold yellow]- Credit: [/bold yellow][bold white]Shouko.dev[/bold white]")

        if check_executor == "1":
            console.print("[bold yellow]- Method: [/bold yellow][bold white]Check Executor[/bold white]")
        else:
            console.print("[bold yellow]- Method: [/bold yellow][bold white]Check Online[/bold white]")
        
        console.print("\n")

    @staticmethod
    def create_dynamic_menu(options):
        console = Console()

        table = Table(
            header_style="bold white",
            border_style="bright_white",
            box=ROUNDED
        )
        table.add_column("No", justify="center", style="bold cyan", width=6)
        table.add_column("Service Name", style="bold magenta", justify="left")

        for i, service in enumerate(options, start=1):
            table.add_row(f"[bold yellow][ {i} ][/bold yellow]", f"[bold blue]{service}[/bold blue]")

        panel = Panel(
            table,
            title="[bold yellow]discord.gg/ghmaDgNzDa - Beta Edition[/bold yellow]",
            border_style="yellow",
            box=ROUNDED
        )

        console.print(Align.left(panel))

    @staticmethod
    def create_dynamic_table(headers, rows):
        table = PrettyTable(field_names=headers, border=True, align="l")
        for huy in rows:
            table.add_row(list(huy))
        print(table)

    last_update_time = 0
    update_interval = 5

    @staticmethod
    def update_status_table():
        current_time = time.time()
        if current_time - UIManager.last_update_time < UIManager.update_interval:
            return
        
        cpu_usage = psutil.cpu_percent(interval=2)
        memory_info = psutil.virtual_memory()
        ram = round(memory_info.used / memory_info.total * 100, 2)
        title = f"CPU: {cpu_usage}% | RAM: {ram}%"

        table_packages = PrettyTable(
            field_names=["Package", "Username", "Package Status"],
            title=title,
            border=True,
            align="l"
        )

        for package, info in globals().get("package_statuses", {}).items():
            username = str(info.get("Username", "Unknown"))

            if username != "Unknown":
                obfuscated_username = "******" + username[6:] if len(username) > 6 else "******"
                username = obfuscated_username

            table_packages.add_row([
                str(package),
                username,
                str(info.get("Status", "Unknown"))
            ])

        Utilities.clear_screen()
        UIManager.print_header(version)
        print(table_packages)

class ExecutorManager:
    @staticmethod
    def detect_executors():
        console = Console()
        detected_executors = []

        for executor_name, base_path in executors.items():
            possible_autoexec_paths = [
                os.path.join(base_path, "Autoexec"),
                os.path.join(base_path, "Autoexecute"),
                os.path.join(base_path, "autoexec")
            ]

            for path in possible_autoexec_paths:
                if os.path.exists(path):
                    detected_executors.append(executor_name)
                    console.print(f"[bold green][ Shouko.dev ] - Detected executor: {executor_name}[/bold green]")
                    break

        return detected_executors
    
    @staticmethod
    def write_lua_script(detected_executors):
        console = Console()
        config_file = os.path.join("Shouko.dev", "checkui.lua")

        try:
            with open(config_file, "r") as f:
                lua_script_content = f.read()
        except Exception as e:
            console.print(f"[bold red][ Shouko.dev ] - Error reading config from {config_file}: {e}[/bold red]")
            return

        for executor_name in detected_executors:
            base_path = executors[executor_name]
            possible_autoexec_paths = [
                os.path.join(base_path, "Autoexec"),
                os.path.join(base_path, "Autoexecute"),
                os.path.join(base_path, "autoexec")
            ]

            lua_written = False

            if executor_name.upper() == "KRNL":
                autoruns_path = os.path.join("/storage/emulated/0/krnl/workspace/.storage", "autoruns.json")
                tabs_path = os.path.join("/storage/emulated/0/krnl/workspace/.storage/tabs", "check_executor.luau")

                if os.path.exists(autoruns_path):
                    with open(autoruns_path, "r") as f:
                        try:
                            autoruns_data = json.load(f)
                            if not isinstance(autoruns_data, list):
                                autoruns_data = []
                        except json.JSONDecodeError:
                            autoruns_data = []
                else:
                    autoruns_data = []

                if "check_executor" not in autoruns_data:
                    autoruns_data.append("check_executor")
                    try:
                        with open(autoruns_path, "w") as f:
                            json.dump(autoruns_data, f)
                        console.print(f"[bold green][ Shouko.dev ] - Added script into KRNL autoexec![/bold green]")
                    except Exception as e:
                        console.print(f"[bold red][ Shouko.dev ] - Error updating KRNL autoexec: {e}[/bold red]")
                        Utilities.log_error(f"Error updating KRNL autoexec: {e}")
                else:
                    console.print(f"[bold green][ Shouko.dev ] - Script already exists in KRNL autoexec![/bold green]")

                try:
                    os.makedirs(os.path.dirname(tabs_path), exist_ok=True)
                    with open(tabs_path, "w") as f:
                        f.write(lua_script_content)
                    lua_written = True
                    console.print(f"[bold green][ Shouko.dev ] - Lua script written successfully![/bold green]")
                except Exception as e:
                    console.print(f"[bold red][ Shouko.dev ] - Error writing Lua script to KRNL autoexec: {e}[/bold red]")
                    Utilities.log_error(f"Error writing Lua script to KRNL autoexec: {e}")

            if not lua_written:
                if executor_name.upper() == "DELTA":
                    target_path = os.path.join(base_path, "Autoexecute")
                    os.makedirs(target_path, exist_ok=True)
                    lua_script_path = os.path.join(target_path, "executor_check.lua")
                    try:
                        with open(lua_script_path, 'w') as file:
                            file.write(lua_script_content)
                        lua_written = True
                        console.print(f"[bold green][ Shouko.dev ] - Lua script written to: {lua_script_path}[/bold green]")
                    except Exception as e:
                        console.print(f"[bold red][ Shouko.dev ] - Error writing Lua script to {lua_script_path}: {e}[/bold red]")
                        Utilities.log_error(f"Error writing Lua script to {lua_script_path}: {e}")

                if not lua_written:
                    for path in possible_autoexec_paths:
                        if os.path.exists(path):
                            lua_script_path = os.path.join(path, "executor_check.lua")

                            try:
                                with open(lua_script_path, 'w') as file:
                                    file.write(lua_script_content)
                                lua_written = True
                                console.print(f"[bold green][ Shouko.dev ] - Lua script written to: {lua_script_path}[/bold green]")
                                break

                            except Exception as e:
                                console.print(f"[bold red][ Shouko.dev ] - Error writing Lua script to {lua_script_path}: {e}[/bold red]")
                                Utilities.log_error(f"Error writing Lua script to {lua_script_path}: {e}")

                    if not lua_written:
                        console.print(f"[bold yellow][ Shouko.dev ] - No valid path found to write Lua script for {executor_name}[/bold yellow]")

    @staticmethod
    def check_executor_status(package_name, continuous=True, max_wait_time=180):
        retry_timeout = time.time() + max_wait_time
        while True:
            for workspace in globals()["workspace_paths"]:
                id = globals()["_user_"][package_name]
                file_path = os.path.join(workspace, f"{id}.main")
                if os.path.exists(file_path):
                    return True
            if continuous and time.time() > retry_timeout:
                return False
            time.sleep(20)

    @staticmethod
    def check_executor_and_rejoin(package_name, server_link, next_package_event):
        user_id = globals()["_user_"][package_name]
        detected_executors = ExecutorManager.detect_executors()

        if detected_executors:
            globals()["package_statuses"][package_name]["Status"] = "\033[1;33mChecking executor...\033[0m"
            UIManager.update_status_table()
            while True:
                ExecutorManager.reset_executor_file(package_name)
                try:
                    start_time = time.time()
                    executor_loaded = False

                    while time.time() - start_time < 180:
                        if ExecutorManager.check_executor_status(package_name):
                            globals()["package_statuses"][package_name]["Status"] = "\033[1;32mExecutor has loaded successfully\033[0m"
                            UIManager.update_status_table()
                            executor_loaded = True
                            next_package_event.set()
                            break
                        time.sleep(20)  

                    if not executor_loaded:
                        globals()["package_statuses"][package_name]["Status"] = "\033[1;31mExecutor didn't load. Rejoining...\033[0m"
                        UIManager.update_status_table()
                        time.sleep(15)

                        ExecutorManager.reset_executor_file(package_name)
                        time.sleep(0.5)
                        RobloxManager.kill_roblox_process(package_name)
                        RobloxManager.delete_cache_for_package(package_name)
                        time.sleep(15)
                        print(f"\033[1;33m[ Shouko.dev ] - Rejoining {package_name}...\033[0m")
                        globals()["package_statuses"][package_name]["Status"] = "\033[1;36mRejoining\033[0m"
                        UIManager.update_status_table()
                        RobloxManager.launch_roblox(package_name, server_link)
                        globals()["package_statuses"][package_name]["Status"] = "\033[1;32mJoined Roblox\033[0m"
                        UIManager.update_status_table()

                except Exception as e:
                    globals()["package_statuses"][package_name]["Status"] = f"\033[1;31mError checking executor for {package_name}: {e}\033[0m"
                    UIManager.update_status_table()
                    time.sleep(10)

                    ExecutorManager.reset_executor_file(package_name)
                    time.sleep(2)
                    RobloxManager.kill_roblox_process(package_name)
                    RobloxManager.delete_cache_for_package(package_name)
                    time.sleep(10)
                    print(f"\033[1;33m[ Shouko.dev ] - Rejoining {package_name} after error...\033[0m")
                    globals()["package_statuses"][package_name]["Status"] = "\033[1;36mRejoining\033[0m"
                    UIManager.update_status_table()
                    RobloxManager.launch_roblox(package_name, server_link)
                    globals()["package_statuses"][package_name]["Status"] = "\033[1;32mJoined Roblox\033[0m"
                    UIManager.update_status_table()

        else:
            globals()["package_statuses"][package_name]["Status"] = f"\033[1;32mJoined without executor for {user_id}\033[0m"
            UIManager.update_status_table()
            next_package_event.set()

    @staticmethod
    def reset_executor_file(package_name):
        try:
            for workspace in globals()["workspace_paths"]:
                id = globals()["_user_"][package_name]
                file_path = os.path.join(workspace, f"{id}.main")
                if os.path.exists(file_path):
                    os.remove(file_path)
        except:
            pass

# --- CẤU HÌNH API SERVER V2 ---
raw_heartbeat_data = {}
heartbeat_lock = threading.Lock()
server_start_time = time.time()

class HeartbeatHandler(http.server.BaseHTTPRequestHandler):
    def _send_json(self, data):
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps(data).encode('utf-8'))

    def do_POST(self):
        if self.path in ['/api/heartbeat', '/heartbeat']:
            try:
                length = int(self.headers.get('Content-Length', 0))
                data = json.loads(self.rfile.read(length))
                user_id = data.get("userId")
                if user_id:
                    with heartbeat_lock:
                        data["server_received_time"] = time.time()
                        raw_heartbeat_data[user_id] = data
                self._send_json({"status": "ok"})
            except: self.send_error(400)
        else: self.send_error(404)

    def do_GET(self):
        if self.path == '/api/status':
            self._send_json({
                "status": "online", 
                "uptime": int(time.time() - server_start_time),
                "monitored": len(raw_heartbeat_data)
            })
        elif self.path == '/api/ping':
            self.send_response(200); self.wfile.write(b'pong')
        else: self.send_response(200)

    def log_message(self, format, *args): return

def start_heartbeat_server():
    """Khởi động Server API ngầm để nhận tin từ Lua"""
    try:
        # Cho phép dùng lại port ngay lập tức
        socketserver.TCPServer.allow_reuse_address = True
        
        # Bind vào 0.0.0.0 để nghe mọi kết nối
        server = socketserver.TCPServer(('0.0.0.0', 5000), HeartbeatHandler)
        
        # Chạy trong thread riêng
        t = threading.Thread(target=server.serve_forever, daemon=True)
        t.start()
        
    except OSError as e:
        if "Address already in use" in str(e):
            print("\033[1;33m[ Server ] Port 5000 is already active (OK).\033[0m")
        else:
            print(f"\033[1;31m[ Server ] Error starting server: {e}\033[0m")
    except Exception as e:
        print(f"\033[1;31m[ Server ] Unexpected error: {e}\033[0m")
                      
class Runner:
    BOOT_GRACE = 300
    TELEPORT_GRACE = 180
    TIMEOUT_LIMIT = 5
    launch_times = {}
    proc_cache = {}

    @classmethod
    def get_package_cpu(cls, package_name):
        try:
            proc = cls.proc_cache.get(package_name)
            if proc and proc.is_running(): return proc.cpu_percent(interval=0.1)
            for p in psutil.process_iter(['name', 'cmdline']):
                try:
                    if package_name in (p.info['cmdline'] or []) or package_name in (p.info['name'] or ''):
                        cls.proc_cache[package_name] = p
                        return p.cpu_percent(interval=0.1)
                except: continue
        except: pass
        return 0.0

    @classmethod
    def launch_package_sequentially(cls, server_links):
        # 1. Đảm bảo Server Heartbeat luôn chạy
        print("\033[1;36m[ Runner ] Đang khởi động Server Heartbeat...\033[0m")
        start_heartbeat_server()
        
        # 2. Tự động chép Script Lua (Nếu bật config)
        if globals().get("check_exec_enable") == "1":
            print("\033[1;36m[ Executor ] Đang kiểm tra và cài Script Heartbeat...\033[0m")
            detected = ExecutorManager.detect_executors()
            if detected:
                # Đảm bảo script trong bộ nhớ là bản mới nhất
                if globals().get("lua_script_template"):
                    ExecutorManager.write_lua_script(detected)
                else:
                    print("\033[1;33m[ Executor ] Chưa có Script Lua trong bộ nhớ (Hãy vào Menu 5 để cài lại).\033[0m")
            else:
                print("\033[1;33m[ Executor ] Không tìm thấy thư mục Executor nào (Kiểm tra quyền bộ nhớ).\033[0m")

        # 3. Vòng lặp Launch từng acc
        for package_name, server_link in server_links:
            user_id = globals()["_user_"].get(package_name, "Unknown")
            if user_id == "Unknown": continue
            
            # Reset cache process cũ để đo CPU chính xác
            if package_name in cls.proc_cache: del cls.proc_cache[package_name]
            
            # Reset trạng thái cũ
            with status_lock:
                globals()["package_statuses"][package_name] = {
                    "Username": FileManager.get_username(user_id),
                    "Status": "\033[1;33mPreparing Launch...\033[0m"
                }

            print(f"\033[1;32m[ Shouko.dev ] - Launching: {package_name}\033[0m")
            
            # Gọi hàm launch của RobloxManager
            RobloxManager.launch_roblox(package_name, server_link)
            
            # Ghi nhận thời gian bắt đầu chạy (để tính Boot Grace)
            cls.launch_times[user_id] = time.time()
            
            # Cập nhật trạng thái Booting
            with status_lock:
                globals()["package_statuses"][package_name]["Status"] = "\033[1;33mBooting (Grace Period 5m)...\033[0m"
            
            # Nghỉ 15s để tránh lag máy khi mở nhiều acc liên tục
            time.sleep(15)
            

    @classmethod
    def monitor_presence(cls, server_links, stop_event):
        low_cpu_start = {}
        while not stop_event.is_set():
            try:
                now = time.time()
                for pkg, _ in server_links:
                    uid = globals()["_user_"].get(pkg)
                    if not uid: continue
                    
                    hb = {}
                    with heartbeat_lock:
                        if uid in raw_heartbeat_data: hb = raw_heartbeat_data[uid]
                    
                    st = "\033[1;30mUnknown\033[0m"
                    rejoin = False
                    
                    if not hb:
                        lt = cls.launch_times.get(uid, 0)
                        if now - lt < cls.BOOT_GRACE:
                            rem = int(cls.BOOT_GRACE - (now - lt))
                            cpu = cls.get_package_cpu(pkg)
                            st = f"\033[1;33mBooting ({rem}s) | CPU: {cpu:.1f}%\033[0m"
                            
                            if (now - lt > 20) and cpu < 20.0: # Sửa 3.0 -> 20.0 (Dưới 20%)
    if uid not in low_cpu_start: low_cpu_start[uid] = now
    elif now - low_cpu_start[uid] > 15: # Sửa 40 -> 15 (Quá 15s)
        st = f"\033[1;31mFROZEN/LAG ({cpu:.1f}% for 15s)\033[0m"
        rejoin = True
        
                            else:
                                if uid in low_cpu_start: del low_cpu_start[uid]
                        else:
                            st = "\033[1;31mNO SIGNAL (Dead)\033[0m"; rejoin = True
                    else:
                        if uid in low_cpu_start: del low_cpu_start[uid]
                        lt = hb.get("server_received_time", 0)
                        rst = hb.get("status", "ALIVE")
                        diff = now - lt
                        
                        if rst == "TELEPORT":
                            if diff < cls.TELEPORT_GRACE: st = f"\033[1;35mTeleporting ({int(diff)}s)\033[0m"
                            else: st = "\033[1;31mStuck Teleport\033[0m"; rejoin = True
                        elif rst == "SHUTDOWN":
                            st = "\033[1;31mGame Closed\033[0m"; rejoin = True
                        else:
                            if diff > cls.TIMEOUT_LIMIT:
                                lt_launch = cls.launch_times.get(uid, 0)
                                if now - lt_launch < cls.BOOT_GRACE: st = "\033[1;33mLag/Booting\033[0m"
                                else: st = f"\033[1;31mCRASHED ({int(diff)}s)\033[0m"; rejoin = True
                            else: st = "\033[1;32mStable (Alive)\033[0m"

                    with status_lock:
                        if pkg in globals()["package_statuses"]:
                            globals()["package_statuses"][pkg]["Status"] = st
                    
                    if rejoin:
                        with heartbeat_lock:
                            if uid in raw_heartbeat_data: del raw_heartbeat_data[uid]
                        if uid in low_cpu_start: del low_cpu_start[uid]
                        if pkg in cls.proc_cache: del cls.proc_cache[pkg]
                        
                        link = dict(server_links).get(pkg)
                        if link:
                            RobloxManager.kill_roblox_process(pkg)
                            RobloxManager.delete_cache_for_package(pkg)
                            time.sleep(2)
                            with status_lock: globals()["package_statuses"][pkg]["Status"] = "\033[1;36mRejoining...\033[0m"
                            threading.Thread(target=RobloxManager.launch_roblox, args=(pkg, link), daemon=True).start()
                            cls.launch_times[uid] = time.time()
                            time.sleep(5)
            except: pass
            time.sleep(1)

    @staticmethod
    def force_rejoin(links, interval, stop):
        start = time.time()
        while not stop.is_set():
            if interval != float('inf') and (time.time() - start >= interval):
                 RobloxManager.kill_roblox_processes(); start = time.time(); time.sleep(5)
                 Runner.launch_package_sequentially(links)
            time.sleep(60)

    @staticmethod
    def update_status_table_periodically():
        while True: UIManager.update_status_table(); time.sleep(2)
        
def check_activation_status():
    try:
        response = requests.get("https://raw.githubusercontent.com/nghvit/module/refs/heads/main/status/customize", timeout=5)
        response.raise_for_status()
        content = response.text.strip()
        if content == "true":
            print("\033[1;32m[ Shouko.dev ] - Activation status: Enabled. Proceeding with tool execution.\033[0m")
            return True
        elif content == "false":
            print("\033[1;31m[ Shouko.dev ] - Activation status: Disabled. Tool execution halted.\033[0m")
            return False
        else:
            print(f"\033[1;31m[ Shouko.dev ] - Invalid activation status received: {content}. Halting execution.\033[0m")
            Utilities.log_error(f"Invalid activation status: {content}")
            return False
    except requests.RequestException as e:
        print(f"\033[1;31m[ Shouko.dev ] - Error checking activation status: {e}\033[0m")
        Utilities.log_error(f"Error checking activation status: {e}")
        return False

def set_android_id(android_id):
    try:
        subprocess.run(["settings", "put", "secure", "android_id", android_id], check=True)
    except Exception as e:
        Utilities.log_error(f"Failed to set Android ID: {e}")

def auto_change_android_id():
    global auto_android_id_enabled, auto_android_id_value
    while auto_android_id_enabled:
        if auto_android_id_value:
            set_android_id(auto_android_id_value)
        time.sleep(2)  

def main():
    global stop_webhook_thread, webhook_interval
    global auto_android_id_enabled, auto_android_id_thread, auto_android_id_value

    if not check_activation_status():
        print("\033[1;31m[ Shouko.dev ] - Exiting due to activation status check failure.\033[0m")
        return
    
    FileManager._load_config()
    
    if not globals().get("command_8_configured", False):
        globals()["check_exec_enable"] = "1"
        globals()["lua_script_template"] = 'task.spawn(function()local a=tostring(game.Players.LocalPlayer.UserId)..".main"while true do pcall(function()if isfile(a)then delfile(a)end; local success,err=pcall(function()writefile(a,"https://discord.gg/FcEGmkNDDe")end)while not success do task.wait(1); success,err=pcall(function()writefile(a,"https://discord.gg/FcEGmkNDDe")end)end end) task.wait(10) end end)'
        config_file = os.path.join("Shouko.dev", "checkui.lua")
        try:
            os.makedirs("Shouko.dev", exist_ok=True)
            with open(config_file, "w") as f:
                f.write(globals()["lua_script_template"])
            print("\033[1;32m[ Shouko.dev ] - Default script saved to checkui.lua\033[0m")
        except Exception as e:
            print(f"\033[1;31m[ Shouko.dev ] - Error saving default script to {config_file}: {e}\033[0m")
            Utilities.log_error(f"Error saving default script to {config_file}: {e}")
        FileManager.save_config()

    if webhook_interval is None:
        print("\033[1;31m[ Shouko.dev ] - Webhook interval not set, disabled.\033[0m")
        webhook_interval = float('inf')
    if webhook_url and device_name and webhook_interval != float('inf'):
        WebhookManager.start_webhook_thread()
    else:
        print("\033[1;33m[ Shouko.dev ] - Webhook not configured or disabled.\033[0m")

    stop_main_event = threading.Event()

    while True:
        Utilities.clear_screen()
        UIManager.print_header(version)
        FileManager.check_and_create_cookie_file()

        menu_options = [
            "Start Auto Rejoin (Auto setup User ID)",
            "Setup Game ID for Packages",
            "Auto Login with Cookie",
            "Enable Discord Webhook",
            "Auto Check User Setup",
            "Configure Package Prefix",
            "Auto Change Android ID"
        ]

        UIManager.create_dynamic_menu(menu_options)
        setup_type = input("\033[1;93m[ Shouko.dev ] - Enter command: \033[0m")
        
        if setup_type == "1":
            try:
                FileManager.setup_user_ids()
                globals()["accounts"] = FileManager.load_accounts()
                if not globals()["accounts"]:
                    print("\033[1;31mNo User IDs found.\033[0m"); input("Enter..."); continue
                
                server_links = FileManager.load_server_links()
                globals()["_uid_"] = {}
                if not server_links:
                    print("\033[1;31mNo Game ID setup.\033[0m"); input("Enter..."); continue

                fr_input = input("\033[1;93mForce rejoin (min/q): \033[0m")
                fr_int = float('inf') if fr_input.lower() == 'q' else int(fr_input) * 60

                RobloxManager.kill_roblox_processes(); time.sleep(2)
                Runner.launch_package_sequentially(server_links)
                globals()["is_runner_ez"] = True

                t1 = threading.Thread(target=Runner.monitor_presence, args=(server_links, stop_main_event), daemon=True)
                t2 = threading.Thread(target=Runner.force_rejoin, args=(server_links, fr_int, stop_main_event), daemon=True)
                t3 = threading.Thread(target=Runner.update_status_table_periodically, daemon=True)
                
                t1.start(); t2.start(); t3.start()

                while not stop_main_event.is_set(): time.sleep(100)

            except Exception as e:
                print(f"Error: {e}"); input("Enter..."); continue
                
        if setup_type == "2":
            try:
                print("\033[1;32m[ Shouko.dev ] - Auto Setup User IDs from appStorage.json...\033[0m")
                packages = RobloxManager.get_roblox_packages()
                accounts = []

                for package_name in packages:
                    file_path = f'/data/data/{package_name}/files/appData/LocalStorage/appStorage.json'
                    try:
                        user_id = FileManager.find_userid_from_file(file_path)
                        if user_id and user_id != "-1":
                            accounts.append((package_name, user_id))
                            print(f"\033[96m[ Shouko.dev ] - Found UserId for {package_name}: {user_id}\033[0m")
                        else:
                            print(f"\033[1;31m[ Shouko.dev ] - UserId not found for {package_name}.\033[0m")
                    except Exception as e:
                        print(f"\033[1;31m[ Shouko.dev ] - Error reading file for {package_name}: {e}\033[0m")
                        Utilities.log_error(f"Error reading appStorage.json for {package_name}: {e}")

                if accounts:
                    FileManager.save_accounts(accounts)
                    print("\033[1;32m[ Shouko.dev ] - User IDs saved!\033[0m")
                else:
                    print("\033[1;31m[ Shouko.dev ] - No User IDs found.\033[0m")
                    input("\033[1;32mPress Enter to return...\033[0m")
                    continue

                print("\033[93m[ Shouko.dev ] - Select game:\033[0m")
                games = [
                    "1. Blox Fruits", "2. Grow A Garden", "3. King Legacy", "4. Fisch",
                    "5. Bee Swarm Simulator", "6. Anime Last Stand", "7. Dead Rails Alpha",
                    "8. All Star Tower Defense X", "9. 99 Nights In The Forest", "10. Murder Mystery 2",
                    "11. Steal A Brainrot", "12. Blue Lock Rivals", "13. Arise Crossover", "14. Other game or Private Server Link"
                ]
                for game in games:
                    print(f"\033[96m{game}\033[0m")

                choice = input("\033[93m[ Shouko.dev ] - Enter choice: \033[0m").strip()
                game_ids = {
                    "1": "2753915549", "2": "126884695634066", "3": "4520749081", "4": "16732694052",
                    "5": "1537690962", "6": "12886143095", "7": "116495829188952", "8": "17687504411",
                    "9": "79546208627805", "10": "142823291", "11": "109983668079237", "12": "18668065416",
                    "13": "87039211657390"
                }

                if choice in game_ids:
                    server_link = game_ids[choice]
                elif choice == "14":
                    server_link = input("\033[93m[ Shouko.dev ] - Enter game ID or private server link: \033[0m")
                else:
                    print("\033[1;31m[ Shouko.dev ] - Invalid choice.\033[0m")
                    input("\033[1;32mPress Enter to return...\033[0m")
                    continue

                formatted_link = RobloxManager.format_server_link(server_link)
                if formatted_link:
                    server_links = [(package_name, formatted_link) for package_name, _ in accounts]
                    FileManager.save_server_links(server_links)
                else:
                    print("\033[1;31m[ Shouko.dev ] - Invalid server link.\033[0m")

            except Exception as e:
                print(f"\033[1;31m[ Shouko.dev ] - Error: {e}\033[0m")
                Utilities.log_error(f"Setup error: {e}")
            
            input("\033[1;32mPress Enter to return...\033[0m")
            continue

        elif setup_type == "3":
            RobloxManager.inject_cookies_and_appstorage()
            input("\033[1;32m\nPress Enter to exit...\033[0m")
            continue

        elif setup_type == "4":
            WebhookManager.setup_webhook()
            input("\033[1;32m\nPress Enter to exit...\033[0m")
            continue

        elif setup_type == "5":
            try:
                # Script Lua Heartbeat V2 (Compressed - One Line)
                LUA_SRC = r"""local TOOL_URL="http://127.0.0.1:5000/api/heartbeat";local req=(syn and syn.request)or(http and http.request)or http_request or request;if not req then return end;local Plr=game:GetService("Players").LocalPlayer;if not Plr then return end;local UID=tostring(Plr.UserId);local function send(s)pcall(function()req({Url=TOOL_URL,Method="POST",Headers={["Content-Type"]="application/json"},Body=game:GetService("HttpService"):JSONEncode({userId=UID,status=s,placeId=game.PlaceId,jobId=game.JobId})})end)end;Plr.OnTeleport:Connect(function()send("TELEPORT")end);game:BindToClose(function()send("SHUTDOWN");task.wait(0.5)end);task.spawn(function()send("ALIVE");while true do task.wait(2);send("ALIVE")end end)"""
                
                print("\033[1;35m[1]\033[1;32m Heartbeat Check (Recommended)\033[0m \033[1;35m[2]\033[1;36m Online Check (API Roblox)\033[0m")
                choice = input("\033[1;93mSelect (1-2): \033[0m").strip()
                
                if choice == "2":
                    globals()["check_exec_enable"] = "0"
                    globals()["lua_script_template"] = None
                    print("\033[1;36m[ Shouko.dev ] - Set to Online Check Mode.\033[0m")
                else:
                    globals()["check_exec_enable"] = "1"
                    globals()["lua_script_template"] = LUA_SRC
                    print("\033[1;32m[ Shouko.dev ] - Set to Heartbeat Mode.\033[0m")

                # Cập nhật file script
                cfg_path = os.path.join("Shouko.dev", "checkui.lua")
                os.makedirs("Shouko.dev", exist_ok=True)
                
                if globals()["lua_script_template"]:
                    with open(cfg_path, "w") as f: f.write(globals()["lua_script_template"])
                    print(f"\033[1;32m[ Shouko.dev ] - Script updated to: {cfg_path}\033[0m")
                else:
                    if os.path.exists(cfg_path): os.remove(cfg_path)
                
                globals()["command_8_configured"] = True
                FileManager.save_config()
                print("\033[1;32m[ Shouko.dev ] - Configuration saved.\033[0m")
            
            except Exception as e:
                print(f"\033[1;31m[ Shouko.dev ] - Error: {e}\033[0m")
            
            input("\033[1;32mPress Enter to return...\033[0m")
            continue
                                    
        elif setup_type == "6":
            try:
                current_prefix = globals().get("package_prefix", "com.roblox")
                print(f"\033[1;32m[ Shouko.dev ] - Current package prefix: {current_prefix}\033[0m")
                new_prefix = input("\033[1;93m[ Shouko.dev ] - Enter new package prefix (or press Enter to keep current): \033[0m").strip()
                
                if new_prefix:
                    globals()["package_prefix"] = new_prefix
                    FileManager.save_config()
                    print(f"\033[1;32m[ Shouko.dev ] - Package prefix updated to: {new_prefix}\033[0m")
                else:
                    print(f"\033[1;33m[ Shouko.dev ] - Package prefix unchanged: {current_prefix}\033[0m")
            except Exception as e:
                print(f"\033[1;31m[ Shouko.dev ] - Error setting package prefix: {e}\033[0m")
                Utilities.log_error(f"Error setting package prefix: {e}")
                input("\033[1;32mPress Enter to return...\033[0m")
                continue
            input("\033[1;32mPress Enter to return...\033[0m")
            continue

        elif setup_type == "7":
            global auto_android_id_enabled, auto_android_id_thread, auto_android_id_value
            if not auto_android_id_enabled:
                android_id = input("\033[1;93m[ Shouko.dev ] - Enter Android ID to spam set: \033[0m").strip()
                if not android_id:
                    print("\033[1;31m[ Shouko.dev ] - Android ID cannot be empty.\033[0m")
                    input("\033[1;32mPress Enter to return...\033[0m")
                    continue
                auto_android_id_value = android_id
                auto_android_id_enabled = True
                if auto_android_id_thread is None or not auto_android_id_thread.is_alive():
                    auto_android_id_thread = threading.Thread(target=auto_change_android_id, daemon=True)
                    auto_android_id_thread.start()
                print("\033[1;32m[ Shouko.dev ] - Auto change Android ID enabled.\033[0m")
            else:
                auto_android_id_enabled = False
                print("\033[1;31m[ Shouko.dev ] - Auto change Android ID disabled.\033[0m")
            input("\033[1;32mPress Enter to return...\033[0m")
            continue

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"\033[1;31m[ Shouko.dev ] - Error during initialization: {e}\033[0m")
        Utilities.log_error(f"Initialization error: {e}")
        raise
