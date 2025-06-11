@echo off
echo ================================================
echo   Adding Firewall Rule for AI Service
echo ================================================
echo.
echo Adding rule to allow connections on port 5000...
netsh advfirewall firewall add rule name="Medical App AI Service" dir=in action=allow protocol=TCP localport=5000
echo.
if %errorlevel% equ 0 (
    echo ✅ Firewall rule added successfully!
    echo Your Android device should now be able to connect.
) else (
    echo ❌ Failed to add firewall rule.
    echo Please run this file as Administrator.
)
echo.
echo Testing server connection...
curl -s http://192.168.0.100:5000/health
echo.
echo ================================================
echo   Instructions:
echo ================================================
echo 1. Right-click this file and select "Run as administrator"
echo 2. Test the connection from your Android device browser:
echo    http://192.168.0.100:5000/health
echo 3. If successful, restart your Flutter app
echo ================================================
pause 