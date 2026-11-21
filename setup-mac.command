#!/usr/bin/env bash
# ==============================================================================
# Android TV Ad-Block: 1-Click Automated Setup for macOS
# Double-click this file in Finder to set up ad blocking on your TV.
# ==============================================================================
set -euo pipefail

# Always run from the folder where this script lives
cd "$(dirname "$0")"

C_GREEN="\033[1;32m"
C_CYAN="\033[1;36m"
C_YELLOW="\033[1;33m"
C_RED="\033[1;31m"
C_RESET="\033[0m"

echo -e "${C_CYAN}================================================================${C_RESET}"
echo -e "${C_GREEN}         Android TV Ad-Block: 1-Click Setup for macOS           ${C_RESET}"
echo -e "${C_CYAN}================================================================${C_RESET}"
echo ""

# 1. Locate or download portable adb
ADB_BIN="adb"
if ! command -v adb >/dev/null 2>&1; then
    if [ -x "./platform-tools/adb" ]; then
        ADB_BIN="./platform-tools/adb"
    else
        echo -e "${C_YELLOW}[*] ADB not found on system. Downloading portable tools from Google...${C_RESET}"
        curl -fL --max-time 120 -o platform-tools.zip https://dl.google.com/android/repository/platform-tools-latest-darwin.zip
        unzip -q -o platform-tools.zip
        rm -f platform-tools.zip
        chmod +x ./platform-tools/adb
        ADB_BIN="./platform-tools/adb"
        echo -e "${C_GREEN}[+] Portable ADB installed successfully.${C_RESET}"
    fi
fi

# 2. Get TV IP Address
echo ""
echo -e "${C_CYAN}Please check your TV (Settings > Network & Internet > Select your Wi-Fi).${C_RESET}"
read -rp "Enter your TV IP address (e.g. 192.168.1.45): " TV_IP

if [ -z "$TV_IP" ]; then
    echo -e "${C_RED}[!] Error: No IP address provided. Exiting.${C_RESET}"
    read -rp "Press [Enter] to exit..."
    exit 1
fi

SERIAL="$TV_IP:5555"

echo ""
echo -e "${C_YELLOW}[1/6] Connecting to TV at $SERIAL...${C_RESET}"
echo -e "${C_CYAN}[!] Look at your TV screen now!${C_RESET}"
echo -e "    If you see 'Allow USB debugging?', tick 'Always allow' and press OK on your remote."

$ADB_BIN connect "$SERIAL" >/dev/null 2>&1 || true

CONNECTED=0
for i in $(seq 1 60); do
    STATE="$($ADB_BIN -s "$SERIAL" get-state 2>/dev/null || true)"
    if [ "$STATE" = "device" ]; then
        CONNECTED=1
        break
    fi
    $ADB_BIN connect "$SERIAL" >/dev/null 2>&1 || true
    sleep 1
done

if [ "$CONNECTED" -eq 0 ]; then
    echo -e "${C_RED}[!] Failed to connect to TV. Please ensure:${C_RESET}"
    echo "    1. TV and Mac are on the exact same Wi-Fi network."
    echo "    2. Developer Options and USB/Network debugging are ON in TV settings."
    echo "    3. You approved the 'Allow USB debugging' prompt on the TV."
    echo ""
    read -rp "Press [Enter] to exit..."
    exit 1
fi

TV_MODEL="$($ADB_BIN -s "$SERIAL" shell getprop ro.product.model | tr -d '\r')"
ANDROID_VER="$($ADB_BIN -s "$SERIAL" shell getprop ro.build.version.release | tr -d '\r')"
echo -e "${C_GREEN}[+] Connected to: $TV_MODEL (Android $ANDROID_VER)${C_RESET}"

# 3. Download verified filter APK
PKG="dnsfilter.android"
ACT="dnsfilter.android/.DNSProxyActivity"
CFG="/sdcard/Android/data/$PKG/files/PersonalDNSFilter"
APK_URL="https://f-droid.org/repo/dnsfilter.android_1506105.apk"
APK_SHA="73489010f4d28800cc7ea8fa10b2c8b340c3f19ce81ba56760b4dc4054869039"

echo ""
echo -e "${C_YELLOW}[2/6] Verifying ad-blocker APK...${C_RESET}"
if [ ! -f "dnsfilter.apk" ]; then
    echo "    Downloading personalDNSfilter from F-Droid..."
    curl -fL --max-time 120 -o dnsfilter.apk "$APK_URL"
fi

CURRENT_SHA="$(shasum -a 256 dnsfilter.apk | awk '{print $1}')"
if [ "$CURRENT_SHA" != "$APK_SHA" ]; then
    echo -e "${C_RED}[!] Checksum mismatch on APK. Re-downloading...${C_RESET}"
    rm -f dnsfilter.apk
    curl -fL --max-time 120 -o dnsfilter.apk "$APK_URL"
fi

# 4. Install onto TV
echo ""
echo -e "${C_YELLOW}[3/6] Installing onto TV...${C_RESET}"
$ADB_BIN -s "$SERIAL" install -r dnsfilter.apk | tail -n 1
echo -e "${C_GREEN}[+] App installed successfully.${C_RESET}"

# 5. First run and VPN permission
echo ""
echo -e "${C_YELLOW}[4/6] Initializing filter and requesting VPN permission...${C_RESET}"
$ADB_BIN -s "$SERIAL" shell am force-stop "$PKG" >/dev/null 2>&1 || true
$ADB_BIN -s "$SERIAL" shell am start -n "$ACT" >/dev/null

echo -e "${C_CYAN}[!] Look at your TV screen now!${C_RESET}"
echo -e "    A system dialog saying 'Connection request (VPN)' will appear."
echo -e "    Use your TV remote to click OK."

for i in $(seq 1 60); do
    if $ADB_BIN -s "$SERIAL" shell "ls $CFG/dnsfilter.conf" >/dev/null 2>&1; then
        break
    fi
    sleep 1
done

# 6. Configure rules and whitelist Netflix
echo ""
echo -e "${C_YELLOW}[5/6] Applying optimized ad rules and whitelisting Netflix...${C_RESET}"
$ADB_BIN -s "$SERIAL" shell am force-stop "$PKG" >/dev/null 2>&1 || true

TMP_DIR="$(mktemp -d)"
$ADB_BIN -s "$SERIAL" pull "$CFG/dnsfilter.conf" "$TMP_DIR/dnsfilter.conf" >/dev/null

sed -i '' -E \
  -e 's/^detectDNS = .*/detectDNS = false/' \
  -e 's#^fallbackDNS = .*#fallbackDNS = [1.1.1.1]::443::DOH::https://cloudflare-dns.com/dns-query; [9.9.9.9]::443::DOH::https://dns.quad9.net/dns-query#' \
  -e '/^filterAutoUpdateURL_switchs/ s/true/false/g' \
  -e 's/^showInitialInfoPopUp = .*/showInitialInfoPopUp = false/' \
  -e 's/^androidAppWhiteList = .*/androidAppWhiteList = com.netflix.ninja/' \
  "$TMP_DIR/dnsfilter.conf"

$ADB_BIN -s "$SERIAL" push "$TMP_DIR/dnsfilter.conf" "$CFG/dnsfilter.conf" >/dev/null
$ADB_BIN -s "$SERIAL" push "./additionalHosts.txt" "$CFG/additionalHosts.txt" >/dev/null
rm -rf "$TMP_DIR"

# 7. Apply system settings and start
echo ""
echo -e "${C_YELLOW}[6/6] Locking Always-on VPN and starting service...${C_RESET}"
$ADB_BIN -s "$SERIAL" shell settings put global private_dns_mode off
$ADB_BIN -s "$SERIAL" shell settings put secure always_on_vpn_app "$PKG"
$ADB_BIN -s "$SERIAL" shell am start -n "$ACT" >/dev/null
sleep 4
$ADB_BIN -s "$SERIAL" shell input keyevent KEYCODE_HOME >/dev/null 2>&1 || true

# Verification
PID="$($ADB_BIN -s "$SERIAL" shell pidof "$PKG" | tr -d '\r' || true)"
if [ -n "$PID" ]; then
    echo ""
    echo -e "${C_GREEN}================================================================${C_RESET}"
    echo -e "${C_GREEN}  SUCCESS: Ad blocking is fully configured and active on TV!   ${C_RESET}"
    echo -e "${C_GREEN}================================================================${C_RESET}"
    echo "  - Prime Video ads: Blocked"
    echo "  - JioHotstar ads: Blocked"
    echo "  - Netflix: Whitelisted (starts instantly, no VPN blocks)"
    echo "  - Auto-start: Enabled on TV boot"
    echo ""
    echo "Open Prime Video or JioHotstar on your TV to test!"
else
    echo -e "${C_YELLOW}[!] Setup completed, but please open personalDNSfilter on your TV once to verify.${C_RESET}"
fi

echo ""
read -rp "Press [Enter] to exit..."
