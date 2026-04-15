@echo off
chcp 65001 >nul
echo ========================================
echo 本地壁纸处理脚本
 echo ========================================
echo.

:: 检查 Node.js 是否安装
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo 错误：未安装 Node.js，请先安装 Node.js 14+
    echo 下载地址：https://nodejs.org/
    pause
    exit /b 1
)

:: 检查 Git 是否安装
git --version >nul 2>&1
if %errorlevel% neq 0 (
    echo 错误：未安装 Git，请先安装 Git
    echo 下载地址：https://git-scm.com/
    pause
    exit /b 1
)

:: 获取当前目录
set "PROJECT_ROOT=%~dp0"
set "PROJECT_ROOT=%PROJECT_ROOT:~0,-1%"

:: 检查是否在正确的目录
dir /b "%PROJECT_ROOT%\wallpaper" >nul 2>&1
if %errorlevel% neq 0 (
    echo 错误：请在图床仓库根目录运行此脚本
    pause
    exit /b 1
)

echo 项目目录：%PROJECT_ROOT%
echo.

:: 步骤 1：更新时间戳
echo 步骤 1：更新时间戳文件...
echo.

:: 检查 timestamps-backup-all.txt 是否存在
if not exist "%PROJECT_ROOT%\timestamps-backup-all.txt" (
    echo 提示：timestamps-backup-all.txt 不存在，将创建新文件
    type nul > "%PROJECT_ROOT%\timestamps-backup-all.txt"
)

:: 扫描新增图片并更新时间戳
set "TIMESTAMP=%date:~0,4%%date:~5,2%%date:~8,2%%time:~0,2%%time:~3,2%%time:~6,2%"
set "NEW_TAG=v1.0.%TIMESTAMP%"

echo 扫描新增图片...
echo.

:: 扫描 desktop 目录
for /r "%PROJECT_ROOT%\wallpaper\desktop" %%f in (*.jpg *.jpeg *.png *.webp) do (
    call :process_file "%%f" "desktop"
)

:: 扫描 mobile 目录
for /r "%PROJECT_ROOT%\wallpaper\mobile" %%f in (*.jpg *.jpeg *.png *.webp) do (
    call :process_file "%%f" "mobile"
)

:: 扫描 avatar 目录
for /r "%PROJECT_ROOT%\wallpaper\avatar" %%f in (*.jpg *.jpeg *.png *.webp) do (
    call :process_file "%%f" "avatar"
)

echo.
echo 时间戳更新完成
set "NEW_TAG_FILE=%PROJECT_ROOT%\new_tag.txt"
echo %NEW_TAG% > "%NEW_TAG_FILE%"
echo.

:: 步骤 2：处理 metadata
echo 步骤 2：处理 metadata...
echo.

node "%PROJECT_ROOT%\scripts\process-metadata.js" "%PROJECT_ROOT%" "%NEW_TAG%" --force
if %errorlevel% neq 0 (
    echo 错误：处理 metadata 失败
    pause
    exit /b 1
)

echo.
echo metadata 处理完成

:: 步骤 3：提交更改（可选）
echo.
echo 步骤 3：是否提交更改到 Git？
echo 1. 是
 echo 2. 否
set /p choice=请选择：
if "%choice%" equ "1" (
    echo 提交更改到 Git...
    cd "%PROJECT_ROOT%"
    git add wallpaper/ metadata/ data/ timestamps-backup-all.txt
    git commit -m "chore: add custom wallpapers"
    git push
    if %errorlevel% neq 0 (
        echo 警告：Git 提交失败，请手动处理
    ) else (
        echo Git 提交成功
    )
    cd /d "%~dp0"
)

echo.
echo ========================================
echo 本地壁纸处理完成！
echo ========================================
echo 你的壁纸已成功添加到图床，并更新了前端数据文件。
echo 现在你可以访问你的壁纸网站查看新添加的壁纸。
echo.
echo 注意：如果是首次运行，可能需要等待几分钟让网站缓存更新。
echo.
pause
exit /b 0

:process_file
set "FILE_PATH=%~1"
set "SERIES=%~2"

:: 计算相对路径
set "REL_PATH=%FILE_PATH:%PROJECT_ROOT%\wallpaper\%SERIES%\=%"
set "REL_PATH=%REL_PATH:/=/%"

:: 构建 key
set "KEY=%SERIES%|%REL_PATH%"

:: 检查是否已存在记录
findstr /C:"%KEY%|" "%PROJECT_ROOT%\timestamps-backup-all.txt" >nul
if %errorlevel% eq 0 (
    goto :eof
)

:: 获取当前时间戳（秒）
for /f "tokens=*" %%a in ('powershell -command "[int](Get-Date -UFormat %%s)"') do set "TIMESTAMP_SEC=%%a"

:: 添加到时间戳文件
echo %KEY%|%TIMESTAMP_SEC%|%NEW_TAG% >> "%PROJECT_ROOT%\timestamps-backup-all.txt"
echo 新增：%REL_PATH%
goto :eof