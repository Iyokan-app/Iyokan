#!/bin/bash

set -e
set -x

VERSION=5.0
FFMPEGFLAGS=(
  --enable-gpl
  --enable-version3
  --enable-static
  --disable-shared
  --disable-programs
  --disable-doc
  --disable-avdevice
  --disable-postproc
  --pkg-config-flags="--static"
  --disable-network
  --disable-videotoolbox
  --disable-vaapi
  --disable-appkit
)

if which yasm || which nasm; then
  true
else
  FFMPEGFLAGS+=(--disable-x86asm)
fi

mkdir -p FFmpeg/src
curl https://ffmpeg.org/releases/ffmpeg-$VERSION.tar.bz2 -o FFmpeg/ffmpeg-$VERSION.tar.bz2
tar -xf FFmpeg/ffmpeg-$VERSION.tar.bz2 -C FFmpeg/src
cd FFmpeg/src/ffmpeg-$VERSION
./configure "${FFMPEGFLAGS[@]}" --prefix=../..
make -j8 install
