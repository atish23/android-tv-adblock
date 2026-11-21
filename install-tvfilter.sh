#!/bin/bash
# Installs and configures personalDNSfilter (open source, from F-Droid) on an Android TV
# over ADB, with our own ad rules and no AdGuard. Run from a laptop on the same Wi-Fi.
#
# Usage:  ./install-tvfilter.sh <TV_IP>
# Needs:  adb, curl, shasum (macOS) or sha256sum (Linux). Developer options and
#         network debugging already switched on in the TV.
# Changes on the TV: installs one app, writes that app's settings, turns Private DNS off,
#         sets Always-on VPN to the app. Undo steps are printed at the end.
set -euo pipefail

TV="${1:?usage: $0 <tv-ip>}"
SERIAL="$TV:5555"
HERE="$(cd "$(dirname "$0")" && pwd)"

# Pinned build we tested. If F-Droid no longer serves it, see README section "Newer version".
APK_URL="${APK_URL:-https://f-droid.org/repo/dnsfilter.android_1506105.apk}"
APK_SHA256="${APK_SHA256:-73489010f4d28800cc7ea8fa10b2c8b340c3f19ce81ba56760b4dc4054869039}"
PKG="dnsfilter.android"
ACT="dnsfilter.android/.DNSProxyActivity"
CFG="/sdcard/Android/data/$PKG/files/PersonalDNSFilter"

command -v adb >/dev/null || { echo "adb not found. Install Android platform tools first."; exit 1; }
[ -f "$HERE/additionalHosts.txt" ] || { echo "additionalHosts.txt must sit next to this script."; exit 1; }
sha() { if command -v sha256sum >/dev/null; then sha256sum "$1" | awk '{print $1}'; else shasum -a 256 "$1" | awk '{print $1}'; fi; }

echo "== 1/7 Connect to $SERIAL (accept the Allow USB debugging prompt on the TV, tick Always allow)"
adb connect "$SERIAL" >/dev/null 2>&1 || true
for i in $(seq 1 90); do
  [ "$(adb -s "$SERIAL" get-state 2>/dev/null || true)" = "device" ] && break
  adb connect "$SERIAL" >/dev/null 2>&1 || true
  sleep 1
  [ "$i" = 90 ] && { echo "Could not connect. Check the IP, that debugging is on, and approve the TV prompt."; exit 1; }
done
export ANDROID_SERIAL="$SERIAL"
echo "   connected: $(adb shell getprop ro.product.model | tr -d '\r') / Android $(adb shell getprop ro.build.version.release | tr -d '\r')"

echo "== 2/7 Download and verify the app"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
curl -fL --max-time 180 -o "$TMP/dnsfilter.apk" "$APK_URL"
GOT="$(sha "$TMP/dnsfilter.apk")"
if [ "$GOT" != "$APK_SHA256" ]; then
  echo "SHA-256 mismatch. Expected $APK_SHA256 got $GOT"
  echo "Do not continue unless you verified a newer F-Droid build yourself (README: Newer version)."
  exit 1
fi

echo "== 3/7 Install"
adb install -r "$TMP/dnsfilter.apk" | tail -1

echo "== 4/7 First start (creates the settings files). On the TV, press OK on the connection (VPN) request."
adb shell am force-stop "$PKG" || true
adb shell am start -n "$ACT" >/dev/null
for i in $(seq 1 90); do
  adb shell "ls $CFG/dnsfilter.conf" >/dev/null 2>&1 && break
  sleep 1
  [ "$i" = 90 ] && { echo "Settings files never appeared. Open the app on the TV once, then re-run."; exit 1; }
done
for i in $(seq 1 120); do
  adb shell dumpsys connectivity 2>/dev/null | grep -q "DnsAddresses: \[ /10.10.10.10" && break
  sleep 1
  [ "$i" = 120 ] && echo "   (VPN not detected yet; press OK on the TV or press Start in the app)"
done

echo "== 5/7 Write our settings and rules"
adb shell am force-stop "$PKG"
adb pull "$CFG/dnsfilter.conf" "$TMP/dnsfilter.conf.orig" >/dev/null
cp "$TMP/dnsfilter.conf.orig" "$TMP/dnsfilter.conf"
# portable in-place edit (works with GNU and BSD sed)
sed -E \
  -e 's/^detectDNS = .*/detectDNS = false/' \
  -e 's#^fallbackDNS = .*#fallbackDNS = [1.1.1.1]::443::DOH::https://cloudflare-dns.com/dns-query; [9.9.9.9]::443::DOH::https://dns.quad9.net/dns-query#' \
  -e '/^filterAutoUpdateURL_switchs/ s/true/false/g' \
  -e 's/^showInitialInfoPopUp = .*/showInitialInfoPopUp = false/' \
  "$TMP/dnsfilter.conf.orig" > "$TMP/dnsfilter.conf"
adb push "$TMP/dnsfilter.conf" "$CFG/dnsfilter.conf" >/dev/null
adb push "$HERE/additionalHosts.txt" "$CFG/additionalHosts.txt" >/dev/null
echo "   saved a copy of the original settings at: $HERE/dnsfilter.conf.orig"
cp "$TMP/dnsfilter.conf.orig" "$HERE/dnsfilter.conf.orig"

echo "== 6/7 System settings (Private DNS off, Always-on VPN)"
adb shell settings put global private_dns_mode off
adb shell settings put secure always_on_vpn_app "$PKG"
adb shell am start -n "$ACT" >/dev/null
sleep 8
adb shell input keyevent KEYCODE_HOME || true

echo "== 7/7 Verify"
PID="$(adb shell pidof "$PKG" | tr -d '\r' || true)"
DNS="$(adb shell dumpsys connectivity | grep -oE 'DnsAddresses: \[ /10\.10\.10\.10' | head -1 || true)"
PRIV="$(adb shell settings get global private_dns_mode | tr -d '\r')"
AOV="$(adb shell settings get secure always_on_vpn_app | tr -d '\r')"
echo "   filter process : ${PID:-NOT RUNNING}"
echo "   VPN DNS active : ${DNS:+yes}${DNS:-NO}"
echo "   private_dns    : $PRIV (should be off)"
echo "   always_on_vpn  : $AOV (should be $PKG)"
if [ -n "$PID" ] && [ -n "$DNS" ]; then
  echo "OK. Now restart your streaming apps and test (README section 8)."
else
  echo "NOT READY: open the app on the TV (adb shell am start -n $ACT), press Start, press OK on the VPN request, then re-check."
fi
cat <<EOF

Undo:
  adb -s $SERIAL shell settings delete secure always_on_vpn_app
  adb -s $SERIAL shell pm uninstall $PKG
EOF
