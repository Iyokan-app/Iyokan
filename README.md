# Iyokan

## Compilation

If you are on an Intel Mac or cross compilation, please make sure you have `nasm` or `yasm` installed. Otherwise FFmpeg will be compiled with `--disable-x86asm`.
Or if you are using M1 Mac, for compiling universal ffmpeg library,
you should add `--universal` flag

```shell
./build_ffmpeg.sh --universal
```

Then run in Xcode.
