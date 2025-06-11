@echo off
echo ================================================
echo   TEMPORARILY DISABLE WINDOWS FIREWALL
echo ================================================
echo.
echo ⚠️  This will temporarily disable Windows Firewall
echo    for testing the AI service connection.
echo.
echo 🔐 Remember to turn it back on after testing!
echo.
pause
echo.
echo Disabling Windows Firewall...
netsh advfirewall set allprofiles state off
echo.
echo ✅ Windows Firewall disabled temporarily
echo.
echo 📱 Now test from your Android device:
echo    http://192.168.0.100:5000/health
echo.
echo 🔄 To re-enable firewall later, run:
echo    netsh advfirewall set allprofiles state on
echo.
echo ================================================
pause 