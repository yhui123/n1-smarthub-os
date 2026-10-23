@echo off
chcp 65001 >nul
title N1-SmartHub-OS 一键推送到 GitHub
echo ========================================================
echo    🚀 正在将 N1 固件源码推送到你的 GitHub 仓库...
echo ========================================================
echo.
cd /d "I:\Users\11239\.gemini\antigravity\scratch\n1-firmware-builder"
git push -u origin main
if %errorlevel% equ 0 (
    echo.
    echo ========================================================
    echo    🎉 推送成功！现在请打开 GitHub Actions 开启云端编译：
    echo    https://github.com/yhui123/n1-smarthub-os/actions
    echo ========================================================
) else (
    echo.
    echo ❌ 推送遇到问题，请检查是否已在弹出的浏览器中完成登录授权。
)
echo.
pause
