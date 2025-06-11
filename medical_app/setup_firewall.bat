@echo off
echo ================================================
echo Setting up Windows Firewall for AI Service
echo ================================================

echo Adding firewall rule for Flask server on port 5000...
netsh advfirewall firewall add rule name="Medical App AI Service" dir=in action=allow protocol=TCP localport=5000

echo.
echo Firewall rule added successfully!
echo The AI service should now be accessible from Android devices.
echo.
echo Server will be available at:
echo - http://localhost:5000 (local)
echo - http://192.168.0.100:5000 (from Android device)
echo.
pause 