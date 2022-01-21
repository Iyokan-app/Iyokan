FFMPEGFLAGS = --enable-gpl \
			  --enable-version3 \
			  --enable-static \
			  --disable-shared \
			  --disable-programs \
			  --disable-doc \
			  --disable-avdevice \
			  --disable-swscale \
			  --disable-postproc \
			  --pkg-config-flags="--static" \
			  --disable-network \
			  --disable-videotoolbox \
			  --disable-vaapi \
			  --disable-appkit \
			  --prefix=..

# --disable-debug

SOURCEDIR = src
LIB = lib
HEADERS = include

install: src
	cd $(SOURCEDIR) && ./configure $(FFMPEGFLAGS)
	cd $(SOURCEDIR) && make -j8 && make install
	rm -rf share

src:
	[[ -d dir ]] || git clone https://git.ffmpeg.org/ffmpeg.git $(SOURCEDIR)
	cd $(SOURCEDIR) && git pull --rebase

.PHONY: clean

clean:
	rm -rf $(LIB)
	rm -rf $(HEADERS)
