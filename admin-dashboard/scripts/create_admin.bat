@echo off
echo Creating Admin Account for Medical App Dashboard
echo ================================================
echo.

REM Check if we're in the scripts directory
if exist "create_admin_standalone.dart" (
    echo Running standalone script from scripts directory...
    dart run create_admin_standalone.dart
) else (
    echo Running standalone script from project root...
    dart run scripts/create_admin_standalone.dart
)

echo.
echo Script completed. Press any key to exit...
pause > nul 