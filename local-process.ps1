# 本地壁纸处理脚本（PowerShell 版本）

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "本地壁纸处理脚本" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 检查 Node.js 是否安装
try {
    Get-Command node -ErrorAction Stop
    Write-Host "Node.js 已安装" -ForegroundColor Green
} catch {
    Write-Host "错误：未安装 Node.js，请先安装 Node.js 14+" -ForegroundColor Red
    Write-Host "下载地址：https://nodejs.org/" -ForegroundColor Yellow
    pause
    exit 1
}

# 检查 Git 是否安装
try {
    Get-Command git -ErrorAction Stop
    Write-Host "Git 已安装" -ForegroundColor Green
} catch {
    Write-Host "错误：未安装 Git，请先安装 Git" -ForegroundColor Red
    Write-Host "下载地址：https://git-scm.com/" -ForegroundColor Yellow
    pause
    exit 1
}

# 获取当前目录
$PROJECT_ROOT = Get-Location

# 检查是否在正确的目录
if (-not (Test-Path "$PROJECT_ROOT\wallpaper")) {
    Write-Host "错误：请在图床仓库根目录运行此脚本" -ForegroundColor Red
    pause
    exit 1
}

Write-Host "项目目录：$PROJECT_ROOT" -ForegroundColor Cyan
Write-Host ""

# 步骤 1：更新时间戳
Write-Host "步骤 1：更新时间戳文件..." -ForegroundColor Cyan
Write-Host ""

# 检查 timestamps-backup-all.txt 是否存在
if (-not (Test-Path "$PROJECT_ROOT\timestamps-backup-all.txt")) {
    Write-Host "提示：timestamps-backup-all.txt 不存在，将创建新文件" -ForegroundColor Yellow
    New-Item -ItemType File -Path "$PROJECT_ROOT\timestamps-backup-all.txt" -Force | Out-Null
}

# 生成新的 tag
$TIMESTAMP = Get-Date -Format "yyyyMMddHHmmss"
$NEW_TAG = "v1.0.$TIMESTAMP"

Write-Host "扫描新增图片..." -ForegroundColor Cyan
Write-Host ""

# 扫描函数
function Process-File($file, $series) {
    $REL_PATH = $file.FullName.Replace("$PROJECT_ROOT\wallpaper\$series\", "")
    $KEY = "$series|$REL_PATH"
    
    # 检查是否已存在记录
    $existing = Get-Content "$PROJECT_ROOT\timestamps-backup-all.txt" | Where-Object { $_ -like "$KEY|*" }
    if ($existing) {
        return
    }
    
    # 获取当前时间戳（秒）
    $TIMESTAMP_SEC = [int](Get-Date -UFormat %s)
    
    # 添加到时间戳文件
    "$KEY|$TIMESTAMP_SEC|$NEW_TAG" | Add-Content "$PROJECT_ROOT\timestamps-backup-all.txt"
    Write-Host "新增：$REL_PATH" -ForegroundColor Green
}

# 扫描 desktop 目录
get-childitem "$PROJECT_ROOT\wallpaper\desktop" -Recurse -File | Where-Object { $_.Extension -match '\.(jpg|jpeg|png|webp)$' } | ForEach-Object { Process-File $_ "desktop" }

# 扫描 mobile 目录
get-childitem "$PROJECT_ROOT\wallpaper\mobile" -Recurse -File | Where-Object { $_.Extension -match '\.(jpg|jpeg|png|webp)$' } | ForEach-Object { Process-File $_ "mobile" }

# 扫描 avatar 目录
get-childitem "$PROJECT_ROOT\wallpaper\avatar" -Recurse -File | Where-Object { $_.Extension -match '\.(jpg|jpeg|png|webp)$' } | ForEach-Object { Process-File $_ "avatar" }

Write-Host ""
Write-Host "时间戳更新完成" -ForegroundColor Green
$NEW_TAG | Out-File "$PROJECT_ROOT\new_tag.txt" -Force
Write-Host ""

# 步骤 2：处理 metadata
Write-Host "步骤 2：处理 metadata..." -ForegroundColor Cyan
Write-Host ""

try {
    & node "$PROJECT_ROOT\scripts\process-metadata.js" "$PROJECT_ROOT" "$NEW_TAG" --force
    Write-Host ""nWrite-Host "metadata 处理完成" -ForegroundColor Green
} catch {
    Write-Host "错误：处理 metadata 失败" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Yellow
    pause
    exit 1
}

# 步骤 3：提交更改（可选）
Write-Host ""
Write-Host "步骤 3：是否提交更改到 Git？" -ForegroundColor Cyan
Write-Host "1. 是"
Write-Host "2. 否"
$choice = Read-Host "请选择"
if ($choice -eq "1") {
    Write-Host "提交更改到 Git..." -ForegroundColor Cyan
    try {
        git add wallpaper/ metadata/ data/ timestamps-backup-all.txt
        git commit -m "chore: add custom wallpapers"
        git push
        Write-Host "Git 提交成功" -ForegroundColor Green
    } catch {
        Write-Host "警告：Git 提交失败，请手动处理" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "本地壁纸处理完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "你的壁纸已成功添加到图床，并更新了前端数据文件。" -ForegroundColor Yellow
Write-Host "现在你可以访问你的壁纸网站查看新添加的壁纸。" -ForegroundColor Yellow
Write-Host ""nWrite-Host "注意：如果是首次运行，可能需要等待几分钟让网站缓存更新。" -ForegroundColor Yellow
Write-Host ""
pause
exit 0