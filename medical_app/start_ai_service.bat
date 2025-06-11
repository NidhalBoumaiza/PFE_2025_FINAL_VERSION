@echo off
echo ========================================
echo Medical App AI Service Starter
echo ========================================
echo.

REM Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python is not installed or not in PATH
    echo Please install Python 3.8 or higher from https://python.org
    pause
    exit /b 1
)

echo Python is installed
echo.

REM Install dependencies
echo Installing Python dependencies...
pip install -r requirements.txt

echo.
echo Starting AI Service...
echo The service will be available at:
echo - Local: http://localhost:5000
echo - Android Emulator: http://10.0.2.2:5000
echo.
echo Press Ctrl+C to stop the service
echo.

REM Start the AI service
python start_ai_service.py

pause 