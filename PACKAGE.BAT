@echo off

echo 正在停止 Gradle 任务...
cd android
call gradlew --stop
cd ..

echo 正在清理...
call flutter clean

echo 正在运行 flutter build apk...
call flutter build apk --android-skip-build-dependency-validation

if %errorlevel% equ 0 (
    echo APK 构建成功！
) else (
    echo APK 构建失败！
)
