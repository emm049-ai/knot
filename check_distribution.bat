@echo off
echo ========================================
echo Checking Firebase App Distribution
echo ========================================
echo.

echo Checking if you're logged in...
firebase login:list

echo.
echo ========================================
echo Checking recent releases...
echo ========================================
echo.

firebase appdistribution:releases:list --app 1:548250171926:android:b11829f2d5aa45e4de5337 --limit 5

echo.
echo ========================================
echo Checking tester groups...
echo ========================================
echo.

firebase appdistribution:groups:list

echo.
echo ========================================
echo If you see errors above, try:
echo 1. firebase login
echo 2. Create "Beta Testers" group in Firebase Console
echo 3. Add tester emails to the group
echo ========================================
echo.
pause
