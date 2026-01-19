@echo off
echo ========================================
echo Firebase Distribution Troubleshooting
echo ========================================
echo.

echo Setting active Firebase project...
firebase use knot-29668

echo.
echo ========================================
echo Checking tester groups...
echo ========================================
echo.

firebase appdistribution:groups:list

echo.
echo ========================================
echo If "Beta Testers" group doesn't exist:
echo 1. Go to Firebase Console
echo 2. App Distribution -^> Testers ^& Groups
echo 3. Create group named "Beta Testers"
echo 4. Add tester email addresses
echo ========================================
echo.

echo ========================================
echo Re-distributing latest build...
echo ========================================
echo.

if not exist "build\app\outputs\flutter-apk\app-debug.apk" (
    echo APK not found. Building now...
    C:\flutter\flutter\bin\flutter.bat build apk --debug
)

set /p RELEASE_NOTES="Enter release notes (or press Enter for default): "
if "%RELEASE_NOTES%"=="" set RELEASE_NOTES=Re-sending build - %date% %time%

echo.
echo Distributing to Firebase...
firebase appdistribution:distribute build\app\outputs\flutter-apk\app-debug.apk ^
  --project knot-29668 ^
  --app 1:548250171926:android:b11829f2d5aa45e4de5337 ^
  --groups "beta-testers" ^
  --release-notes "%RELEASE_NOTES%"

if %errorlevel% neq 0 (
    echo.
    echo ========================================
    echo Distribution failed!
    echo ========================================
    echo.
    echo Common issues:
    echo 1. Group "Beta Testers" doesn't exist - create it in Firebase Console
    echo 2. No testers in group - add tester emails
    echo 3. Testers haven't accepted invitation - they need to accept first
    echo.
    echo Check: https://console.firebase.google.com/project/knot-29668/appdistribution
    echo.
    pause
    exit /b 1
)

echo.
echo ========================================
echo Distribution successful!
echo ========================================
echo.
echo Next steps:
echo 1. Check Firebase Console: https://console.firebase.google.com/project/knot-29668/appdistribution/releases
echo 2. Verify testers are "Active" (not "Pending")
echo 3. Testers should receive email within a few minutes
echo.
pause
