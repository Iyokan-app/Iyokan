# Iyokan

## Compilation

If you are on an Intel Mac or cross compilation, please make sure you have `nasm` or `yasm` installed. Otherwise FFmpeg will be compiled with `--disable-x86asm`.

Or if you are using M1 Mac, for compiling universal ffmpeg library,
you should add `--universal` flag.

This script will compile debug version by default, if you what a release version, add `--release` flag.

```shell
./build_ffmpeg.sh --release --universal
```

Then run in Xcode.
