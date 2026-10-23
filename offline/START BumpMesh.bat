@echo off
title BumpMesh (offline), close this window to stop
cd /d "%~dp0"
if not exist "bumpmesh-server.exe" goto missing
if not exist "app\index.html" goto missing
bumpmesh-server.exe
goto end
:missing
echo.
echo   Some BumpMesh files are missing.
echo   Please extract the WHOLE BumpMesh-Offline folder from the zip
echo   and run this file from inside it.
echo.
pause
:end
