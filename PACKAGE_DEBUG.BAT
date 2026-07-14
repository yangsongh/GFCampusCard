@echo off
cls

taskkill /im java.exe /f 2>nul
if %errorlevel% equ 0 (
    timeout 3
)

echo 正在清理 build\app\intermediates\assets 目录...
rmdir /s /q "build\app\intermediates\assets"

echo 正在清理 build\app\intermediates\merged_native_libs 目录...
rmdir /s /q "build\app\intermediates\merged_native_libs"

@REM echo 正在清理 build\app\intermediates\native_symbol_tables 目录...
@REM rmdir /s /q "build\app\intermediates\native_symbol_tables"

echo 正在清理 build\app\intermediates\stripped_native_libs 目录
rmdir /s /q "build\app\intermediates\stripped_native_libs"

echo 正在清理 build\app\intermediates\incremental\packageDebug\tmp 目录...
rmdir /s /q "build\app\intermediates\incremental\packageDebug\tmp"

echo 正在清理 build\app\outputs 目录...
rmdir /s /q "build\app\outputs"

