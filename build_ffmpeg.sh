#!/bin/bash

set -e

CLEAN_ON_FAILED=YES
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
  --universal             build universal library
  --[no-]clean-on-failed  remove FFmpeg folder if any error happened
  -f=FLAG, --flag=FLAG    add ffmpeg flag when build configuration
  --cwd=DIR               set compiling folder
  -c, --clean             clean up FFmpeg folder
  --prefix=PREFIX         FFmpeg library install path

USAGE
}

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
    -f=*|--flag=)
      FFMPEGFLAGS+=("${i#*=}")
      ;;
    --cwd=*)
      cd "${i#*=}"
      CWD="$(pwd)"
      ;;
    -c|--clean)
      rm -r "$CWD/FFmpeg"
      exit 1
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

mkdir -p FFmpeg/src
curl -C - https://ffmpeg.org/releases/ffmpeg-$VERSION.tar.bz2 -o FFmpeg/ffmpeg-$VERSION.tar.bz2
tar -xf FFmpeg/ffmpeg-$VERSION.tar.bz2 -C FFmpeg/src

pushd FFmpeg/src/ffmpeg-$VERSION
make clean || true
./configure "${FFMPEGFLAGS[@]}" --prefix=../../"$PREFIX"
make -j8 install
popd
