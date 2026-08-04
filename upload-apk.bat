@echo off
echo === Upload APK sur Firebase App Distribution ===
echo.
firebase appdistribution:distribute "C:\All-projects\2026\Otaku_verse\app\build\app\outputs\flutter-apk\app-release.apk" --app 1:446776488013:android:fd1f2b2d79c92db412ac04 --groups testers --project otaku-verse-6e05e
echo.
echo === Termine ! ===
pause
