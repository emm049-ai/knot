@echo off
echo ========================================
echo Firebase App Distribution
echo ========================================
echo.

echo Building APK...
C:\flutter\flutter\bin\flutter.bat build apk --debug

if %errorlevel% neq 0 (
    echo.
    echo Build failed! Check errors above.
    pause
    exit /b 1
)

echo.
echo Build successful!
echo.

set /p RELEASE_NOTES="Enter release notes (or press Enter for default): "
if "%RELEASE_NOTES%"=="" set RELEASE_NOTES=New build - %date% %time%

echo.
echo Distributing to Firebase App Distribution...
echo Release notes: %RELEASE_NOTES%
echo.

firebase appdistribution:distribute build\app\outputs\flutter-apk\app-debug.apk ^
  --project knot-29668 ^
  --app 1:548250171926:android:b11829f2d5aa45e4de5337 ^
  --groups "beta-testers" ^
  --release-notes "%RELEASE_NOTES%"

if %errorlevel% neq 0 (
    echo.
    echo Distribution failed! Make sure:
    echo 1. Firebase CLI is installed: npm install -g firebase-tools
    echo 2. You're logged in: firebase login
    echo 3. Tester group "Beta Testers" exists in Firebase Console
    pause
    exit /b 1
)

echo.
echo ========================================
echo Distribution successful!
echo ========================================
echo Android testers will receive an email with download link.
echo.
echo NOTE: iOS testers cannot install Android APK files.
echo       They need an iOS build (.ipa file).
echo       See IOS_DISTRIBUTION_GUIDE.md for options.
echo.
pause
