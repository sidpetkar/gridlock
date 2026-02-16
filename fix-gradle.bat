@echo off
echo Fixing Gradle Cache Corruption...
echo.

echo Step 1: Stopping Gradle daemon...
call gradlew --stop
timeout /t 2 /nobreak >nul

echo Step 2: Cleaning Gradle cache...
rmdir /s /q "%USERPROFILE%\.gradle\caches\8.12\transforms" 2>nul
timeout /t 1 /nobreak >nul

echo Step 3: Cleaning Flutter build...
call flutter clean
timeout /t 2 /nobreak >nul

echo Step 4: Getting dependencies...
call flutter pub get
timeout /t 2 /nobreak >nul

echo.
echo Done! Now try: flutter run
echo.
pause
