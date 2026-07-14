@echo off
cls

taskkill /im java.exe /f 2>nul
@REM taskkill /im dart.exe /f 2>nul
if %errorlevel% equ 0 (
    timeout 3
)

echo 正在清理 build\app\intermediates\assets 目录...
rmdir /s /q "build\app\intermediates\assets"

echo 正在清理 build\app\intermediates\merged_native_libs\release 目录...
rmdir /s /q "build\app\intermediates\merged_native_libs\release"

echo 正在清理 build\app\intermediates\native_symbol_tables 目录...
rmdir /s /q "build\app\intermediates\native_symbol_tables"

echo 正在清理 build\app\intermediates\incremental\packageRelease\tmp 目录...
rmdir /s /q "build\app\intermediates\incremental\packageRelease\tmp"

echo 正在清理 build\app\outputs 目录...
rmdir /s /q "build\app\outputs"

echo 正在运行 flutter build apk...
call flutter build apk --verbose

if %errorlevel% equ 0 (
    cls
    echo APK 构建成功！
) else (
    echo Flutter 构建失败！
    pause
)
