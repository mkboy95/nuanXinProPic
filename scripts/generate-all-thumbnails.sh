#!/usr/bin/env bash
# ========================================
# 全系列缩略图和预览图生成脚本
# ========================================
# 功能：为所有系列（desktop/mobile/avatar）生成缩略图和预览图

set -e

# 目录配置
PROJECT_ROOT="."
WALLPAPER_DIR="$PROJECT_ROOT/wallpaper"
THUMBNAIL_DIR="$PROJECT_ROOT/thumbnail"
PREVIEW_DIR="$PROJECT_ROOT/preview"

# 缩略图配置
THUMB_WIDTH=350
THUMB_QUALITY=75

# 预览图配置
PREVIEW_WIDTH=1920
PREVIEW_QUALITY=78

# 水印配置
WATERMARK_ENABLED=true
WATERMARK_TEXT="暖心"
WATERMARK_OPACITY=40

# 检查 ImageMagick 是否可用
if command -v magick &> /dev/null; then
    IMAGEMAGICK_CMD="magick"
    echo "ImageMagick v7 found"
elif command -v convert &> /dev/null; then
    IMAGEMAGICK_CMD="convert"
    echo "ImageMagick found (convert)"
else
    echo "Error: ImageMagick not found"
    exit 1
fi

# 生成预览图函数
generate_preview() {
    local source_file="$1"
    local output_file="$2"
    
    mkdir -p "$(dirname "$output_file")"
    
    $IMAGEMAGICK_CMD "$source_file" \
        -resize "${PREVIEW_WIDTH}x>" \
        -quality "$PREVIEW_QUALITY" \
        -strip \
        "$output_file" 2>/dev/null
}

# 生成缩略图函数
generate_thumbnail() {
    local source_file="$1"
    local output_file="$2"
    
    mkdir -p "$(dirname "$output_file")"
    
    if [ "$WATERMARK_ENABLED" = true ]; then
        # 计算水印字体大小
        THUMB_WATERMARK_FONT_SIZE=$((THUMB_WIDTH * 2 / 100))
        WATERMARK_ALPHA=$(awk "BEGIN {printf \"%.2f\", $WATERMARK_OPACITY / 100}")
        WATERMARK_COLOR="rgba(255,255,255,$WATERMARK_ALPHA)"
        
        # 尝试设置字体
        WATERMARK_FONT=""
        if [ "$(uname)" = "Linux" ]; then
            for font in "Noto-Sans-CJK-SC-Medium" "Noto-Sans-CJK-SC" "WenQuanYi-Micro-Hei"; do
                if $IMAGEMAGICK_CMD -list font 2>/dev/null | grep -qi "$font"; then
                    WATERMARK_FONT="$font"
                    break
                fi
            done
            [ -z "$WATERMARK_FONT" ] && WATERMARK_FONT="Noto-Sans-CJK-SC-Medium"
        fi
        
        if $IMAGEMAGICK_CMD "$source_file" \
            -resize "${THUMB_WIDTH}x>" \
            -font "$WATERMARK_FONT" \
            -pointsize "$THUMB_WATERMARK_FONT_SIZE" \
            -fill "$WATERMARK_COLOR" \
            -gravity "southeast" \
            -annotate -25x-25+20+40 "$WATERMARK_TEXT" \
            -gravity "southwest" \
            -annotate 0x0+20+40 "$WATERMARK_TEXT" \
            -quality "$THUMB_QUALITY" \
            -strip \
            "$output_file" 2>/dev/null; then
            return 0
        fi
    fi
    
    # 无水印版本
    $IMAGEMAGICK_CMD "$source_file" \
        -resize "${THUMB_WIDTH}x>" \
        -quality "$THUMB_QUALITY" \
        -strip \
        "$output_file" 2>/dev/null
}

# 处理图片函数
process_image() {
    local file="$1"
    
    # 解析路径
    local rel_path="${file#$WALLPAPER_DIR/}"
    local series="${rel_path%%/*}"
    local rest="${rel_path#*/}"
    local filename=$(basename "$file")
    local filename_noext="${filename%.*}"
    
    # 构建输出路径
    local thumb_file="$THUMBNAIL_DIR/$series/$rest"
    thumb_file="${thumb_file%.*}.webp"
    
    local preview_file="$PREVIEW_DIR/$series/$rest"
    preview_file="${preview_file%.*}.webp"
    
    # 检查是否已存在
    if [ -f "$thumb_file" ] && [ -f "$preview_file" ]; then
        return
    fi
    
    # 生成缩略图和预览图
    echo "Processing: $rel_path"
    generate_thumbnail "$file" "$thumb_file"
    generate_preview "$file" "$preview_file"
}

# 处理所有系列
for series in desktop mobile avatar; do
    series_dir="$WALLPAPER_DIR/$series"
    if [ -d "$series_dir" ]; then
        echo "Processing $series series..."
        find "$series_dir" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | while read -r file; do
            process_image "$file"
        done
    fi
done

echo "All images processed!"