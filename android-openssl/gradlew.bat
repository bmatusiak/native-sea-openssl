@echo off
rem Minimal gradlew fallback for Windows: try system gradle, otherwise instruct user
where gradle >nul 2>&1
if %ERRORLEVEL%==0 (
  gradle %*
) else (
  echo Gradle not found. Please install Gradle or use the Gradle wrapper on Unix.
  exit /b 1
)
