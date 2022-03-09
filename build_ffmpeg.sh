#!/bin/bash

set -e

CLEAN_ON_FAILED=YES
ENABLE_DEBUG=YES
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
CWD="$SCRIPT_DIR"
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

usage() {
  cat<<USAGE
Script for building FFmpeg library

  $0 [--no-clean-on-failed] [--universal]

  -h, --help              show this help
  -g, --debug             enable FFmpeg debugging
  --release               disable debugging compilation
  --universal             build universal library
  --[no-]clean-on-failed  remove FFmpeg folder if any error happened
  -f=FLAG, --flag=FLAG    add ffmpeg flag when build configuration
  --cwd=DIR               set compiling folder
  -c, --clean             clean up FFmpeg folder
  --prefix=PREFIX         FFmpeg library install path

USAGE
}

cd "$SCRIPT_DIR"

for i in "$@"; do
  case $i in
    --universal)
      UNIVERSAL=YES
      ;;
    --prefix=*)
      PREFIX="${i#*=}"
      ;;
    --clean-on-failed)
      CLEAN_ON_FAILED=YES
      ;;
    --no-clean-on-failed)
      CLEAN_ON_FAILED=NO
      ;;
    -g|--debug)
      ENABLE_DEBUG=YES
      ;;
    --release)
      ENABLE_DEBUG=NO
      ;;
    -f=*|--flag=)
      FFMPEGFLAGS+=("${i#*=}")
      ;;
    --cwd=*)
      cd "${i#*=}"
      CWD="$(pwd)"
      ;;
    -c|--clean)
      rm -r "$CWD/FFmpeg" || true
      exit 0
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      echo "Unknown option $i"
      usage
      exit 1
      ;;
    *)
      ;;
  esac
done

if [[ $CLEAN_ON_FAILED = YES ]]; then
  function error_handler() {
    set +x
    echo "we meet an error when installing" >&2
    echo "remove FFmpeg folder" >&2
    rm -r "$CWD/FFmpeg"
    exit 1
  }
  trap error_handler ERR
  trap error_handler INT
fi

if [[ ! $(which yasm) && ! $(which nasm) ]]; then
  FFMPEGFLAGS+=(--disable-x86asm)
fi
if [[ $ENABLE_DEBUG = YES ]]; then
  # https://stackoverflow.com/questions/9211163/debugging-ffmpeg/60963911#60963911
  FFMPEGFLAGS+=(
    --disable-optimizations
    --extra-cflags="-Og"
    --extra-cflags="-fno-omit-frame-pointer"
    --enable-debug="3"
    --extra-cflags="-fno-inline"
  )
fi

set -x

mkdir -p FFmpeg/src
curl -C - https://ffmpeg.org/releases/ffmpeg-$VERSION.tar.bz2 -o FFmpeg/ffmpeg-$VERSION.tar.bz2
tar -xf FFmpeg/ffmpeg-$VERSION.tar.bz2 -C FFmpeg/src

pushd FFmpeg/src/ffmpeg-$VERSION
make clean 2>/dev/null || true
./configure "${FFMPEGFLAGS[@]}" --prefix=../../"$PREFIX"
make -j8 install
popd

if [[ $UNIVERSAL = YES && $(arch) = arm64 ]]; then
  arch -x86_64 bash "${BASH_SOURCE[0]}" --cwd="$CWD" --no-clean-on-failed --prefix=x86_64
  mkdir -p FFmpeg/lib-universal
  for lib in FFmpeg/lib/*.a; do
    lib="${lib##*/}"
    lipo -create FFmpeg/lib/"$lib" FFmpeg/x86_64/lib/"$lib" -output FFmpeg/lib-universal/"$lib"
  done
  mv -f FFmpeg/lib FFmpeg/lib-arm64
  mv FFmpeg/lib-universal FFmpeg/lib
fi
