@echo off
rem ==============================================================================
rem Android TV Ad-Block: 1-Click Automated Setup for Windows
rem Double-click this file to set up ad blocking on your TV.
rem ==============================================================================
setlocal EnableDelayedExpansion
cd /d "%~dp0"
chcp 65001 >nul

cls
echo ================================================================
echo         Android TV Ad-Block: 1-Click Setup for Windows
echo ================================================================
echo.

rem 1. Locate or download portable adb
set "ADB_BIN=adb"
where adb >nul 2>&1
if %errorlevel% neq 0 (
    if exist "platform-tools\adb.exe" (
        set "ADB_BIN=platform-tools\adb.exe"
    ) else (
        echo [*] ADB not found on system. Downloading portable tools from Google...
        powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri 'https://dl.google.com/android/repository/platform-tools-latest-windows.zip' -OutFile 'platform-tools.zip'"
        powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -Path 'platform-tools.zip' -DestinationPath '.' -Force"
        if exist platform-tools.zip del platform-tools.zip
        set "ADB_BIN=platform-tools\adb.exe"
        echo [+] Portable ADB installed successfully.
    )
)

rem 2. Get TV IP Address
echo.
echo Please check your TV (Settings ^> Network ^& Internet ^> Select your Wi-Fi).
set /p TV_IP="Enter your TV IP address (e.g. 192.168.1.45): "

if "%TV_IP%"=="" (
    echo [!] Error: No IP address provided. Exiting.
    pause
    exit /b 1
)

set "SERIAL=%TV_IP%:5555"

echo.
echo [1/6] Connecting to TV at %SERIAL%...
echo [!] Look at your TV screen now!
echo     If you see 'Allow USB debugging?', tick 'Always allow' and press OK on your remote.

"%ADB_BIN%" connect "%SERIAL%" >nul 2>&1

set "CONNECTED=0"
for /L %%i in (1,1,60) do (
    for /f "tokens=*" %%a in ('"%ADB_BIN%" -s "%SERIAL%" get-state 2^>nul') do (
        if "%%a"=="device" set "CONNECTED=1"
    )
    if "!CONNECTED!"=="1" goto :connected
    "%ADB_BIN%" connect "%SERIAL%" >nul 2>&1
    timeout /t 1 >nul
)

:connected
if "!CONNECTED!"=="0" (
    echo [!] Failed to connect to TV. Please ensure:
    echo     1. TV and PC are on the exact same Wi-Fi network.
    echo     2. Developer Options and USB/Network debugging are ON in TV settings.
    echo     3. You approved the 'Allow USB debugging' prompt on the TV.
    echo.
    pause
    exit /b 1
)

for /f "tokens=*" %%a in ('"%ADB_BIN%" -s "%SERIAL%" shell getprop ro.product.model 2^>nul') do set "TV_MODEL=%%a"
for /f "tokens=*" %%a in ('"%ADB_BIN%" -s "%SERIAL%" shell getprop ro.build.version.release 2^>nul') do set "ANDROID_VER=%%a"
echo [+] Connected to: %TV_MODEL% (Android %ANDROID_VER%)

rem 3. Download verified filter APK
set "PKG=dnsfilter.android"
set "ACT=dnsfilter.android/.DNSProxyActivity"
set "CFG=/sdcard/Android/data/%PKG%/files/PersonalDNSFilter"
set "APK_URL=https://f-droid.org/repo/dnsfilter.android_1506105.apk"
set "APK_SHA=73489010f4d28800cc7ea8fa10b2c8b340c3f19ce81ba56760b4dc4054869039"

echo.
echo [2/6] Verifying ad-blocker APK...
if not exist "dnsfilter.apk" (
    echo     Downloading personalDNSfilter from F-Droid...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri '%APK_URL%' -OutFile 'dnsfilter.apk'"
)
call :check_sha
if "!SHA_OK!"=="0" (
    echo [!] Checksum mismatch. Re-downloading once...
    del dnsfilter.apk >nul 2>&1
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri '%APK_URL%' -OutFile 'dnsfilter.apk'"
    call :check_sha
)
if "!SHA_OK!"=="0" (
    del dnsfilter.apk >nul 2>&1
    echo [!] Checksum still does not match. Stopping, nothing was installed.
    pause
    exit /b 1
)
echo [+] APK checksum verified.

rem 4. Install onto TV
echo.
echo [3/6] Installing onto TV...
"%ADB_BIN%" -s "%SERIAL%" install -r dnsfilter.apk > install.log 2>&1
findstr /c:"Success" install.log >nul
if errorlevel 1 (
    echo [!] Install failed:
    type install.log
    del install.log >nul 2>&1
    pause
    exit /b 1
)
del install.log >nul 2>&1
echo [+] App installed successfully.

rem 5. First run and VPN permission
echo.
echo [4/6] Initializing filter and requesting VPN permission...
"%ADB_BIN%" -s "%SERIAL%" shell am force-stop "%PKG%" >nul 2>&1
"%ADB_BIN%" -s "%SERIAL%" shell am start -n "%ACT%" >nul

echo [!] Look at your TV screen now!
echo     A system dialog saying 'Connection request (VPN)' will appear.
echo     Use your TV remote to click OK.

for /L %%i in (1,1,60) do (
    "%ADB_BIN%" -s "%SERIAL%" shell "ls %CFG%/dnsfilter.conf" >nul 2>&1
    if !errorlevel! equ 0 goto :config_ready
    timeout /t 1 >nul
)

:config_ready

rem 6. Configure rules and whitelist Netflix
echo.
echo [5/6] Applying optimized ad rules and whitelisting Netflix...
"%ADB_BIN%" -s "%SERIAL%" shell am force-stop "%PKG%" >nul 2>&1

"%ADB_BIN%" -s "%SERIAL%" pull "%CFG%/dnsfilter.conf" "dnsfilter.conf" >nul

powershell -NoProfile -ExecutionPolicy Bypass -Command "(Get-Content 'dnsfilter.conf') -replace '^detectDNS = .*', 'detectDNS = false' -replace '^fallbackDNS = .*', 'fallbackDNS = [1.1.1.1]::443::DOH::https://cloudflare-dns.com/dns-query; [9.9.9.9]::443::DOH::https://dns.quad9.net/dns-query' -replace 'filterAutoUpdateURL_switchs(.*)true', 'filterAutoUpdateURL_switchs$1false' -replace '^showInitialInfoPopUp = .*', 'showInitialInfoPopUp = false' -replace '^androidAppWhiteList = .*', 'androidAppWhiteList = com.netflix.ninja' | Set-Content 'dnsfilter.conf'"

"%ADB_BIN%" -s "%SERIAL%" push "dnsfilter.conf" "%CFG%/dnsfilter.conf" >nul
"%ADB_BIN%" -s "%SERIAL%" push "additionalHosts.txt" "%CFG%/additionalHosts.txt" >nul
if exist "dnsfilter.conf" del "dnsfilter.conf"

rem 7. Apply system settings and start
echo.
echo [6/6] Locking Always-on VPN and starting service...
"%ADB_BIN%" -s "%SERIAL%" shell settings put global private_dns_mode off
"%ADB_BIN%" -s "%SERIAL%" shell settings put secure always_on_vpn_app "%PKG%"
"%ADB_BIN%" -s "%SERIAL%" shell am start -n "%ACT%" >nul
timeout /t 4 >nul
"%ADB_BIN%" -s "%SERIAL%" shell input keyevent KEYCODE_HOME >nul 2>&1

set "PID="
for /f "tokens=*" %%a in ('"%ADB_BIN%" -s "%SERIAL%" shell pidof %PKG% 2^>nul') do set "PID=%%a"
echo.
if defined PID (
    echo ================================================================
    echo   SUCCESS: Ad blocking is fully configured and active on TV!
    echo ================================================================
    echo   - Prime Video ads: Blocked
    echo   - JioHotstar ads: Blocked
    echo   - Netflix: Whitelisted, starts instantly, no VPN blocks
    echo   - Auto-start: Enabled on TV boot
    echo.
    echo Open Prime Video or JioHotstar on your TV to test!
) else (
    echo [!] Setup finished, but the filter is not running yet.
    echo     Open personalDNSfilter on the TV, press Start, and press OK on the VPN request.
)
echo.
pause
exit /b 0

:check_sha
set "SHA_OK=0"
for /f "usebackq tokens=*" %%h in (`powershell -NoProfile -Command "(Get-FileHash -Algorithm SHA256 'dnsfilter.apk').Hash.ToLower()"`) do (
    if /i "%%h"=="%APK_SHA%" set "SHA_OK=1"
)
exit /b 0
