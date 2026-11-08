#!/bin/bash
mkdir -p openwrt

# 自动从 iStoreOS 官方固件站获取最新版本（x86_64 efi 版）
MIRROR_URL="https://fw.koolcenter.com/iStoreOS/x86_64_efi/"

# 从镜像站目录列表里抓取最新版文件名（按版本号+日期排序取最后一个）
FILE_NAME=$(curl -s "$MIRROR_URL" | \
  grep -oE 'istoreos-[0-9]+\.[0-9]+\.[0-9]+-[0-9]+-x86-64-squashfs-combined-efi\.img\.gz' | \
  sort -u | sort -t- -k2,2V -k3,3 | tail -1)

if [[ -z "$FILE_NAME" ]]; then
  echo "错误：未能从镜像站获取最新版本文件名"
  exit 1
fi

OUTPUT_PATH="openwrt/istoreos.img.gz"
DOWNLOAD_URL="${MIRROR_URL}${FILE_NAME}"

echo "检测到最新版本: $FILE_NAME"
echo "下载地址: $DOWNLOAD_URL"
echo "下载文件: $FILE_NAME -> $OUTPUT_PATH"
curl -L --fail -o "$OUTPUT_PATH" "$DOWNLOAD_URL"

if [[ $? -eq 0 ]]; then
  echo "下载istoreos成功!"
  echo "正在解压为:istoreos.img"
  gzip -d openwrt/istoreos.img.gz
  ls -lh openwrt/
  echo "准备合成 istoreos 安装器"
else
  echo "下载失败！"
  exit 1
fi

mkdir -p output
# 记录本次构建的固件版本，供 workflow 生成 Release 标题/摘要
echo "$FILE_NAME" > output/version.txt
docker run --privileged --rm \
        -v $(pwd)/output:/output \
        -v $(pwd)/supportFiles:/supportFiles:ro \
        -v $(pwd)/openwrt/istoreos.img:/mnt/istoreos.img \
        debian:buster \
        /supportFiles/istoreos/build.sh
