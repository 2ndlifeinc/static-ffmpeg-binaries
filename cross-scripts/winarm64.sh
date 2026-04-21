#!/bin/bash

# Cross-compile ffmpeg + all deps for aarch64-w64-mingw32 (Windows ARM64).
# Must run inside mstorsjo/llvm-mingw toolchain image.

set -e
set -x

: "${REPO_SRC:?REPO_SRC must point to the checked-out repo}"
: "${OUT_DIR:?OUT_DIR must be set (where ffmpeg.exe + ffprobe.exe will land)}"

TRIPLE=aarch64-w64-mingw32
PREFIX=/opt/cross-winarm64
WORK=/tmp/winarm64-build

export CC="$TRIPLE-clang"
export CXX="$TRIPLE-clang++"
export AR="$TRIPLE-ar"
export RANLIB="$TRIPLE-ranlib"
export STRIP="$TRIPLE-strip"
export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig"
export PKG_CONFIG="pkg-config --static"

mkdir -p "$PREFIX" "$WORK" "$OUT_DIR"
cd "$WORK"

MESON_CROSS="$WORK/meson-cross.txt"
cat > "$MESON_CROSS" <<EOF
[binaries]
c = '$TRIPLE-clang'
cpp = '$TRIPLE-clang++'
ar = '$TRIPLE-ar'
ranlib = '$TRIPLE-ranlib'
strip = '$TRIPLE-strip'
pkgconfig = 'pkg-config'
windres = '$TRIPLE-windres'

[host_machine]
system = 'windows'
cpu_family = 'aarch64'
cpu = 'aarch64'
endian = 'little'
EOF

version() { "$REPO_SRC"/get-version.sh "$1"; }

# --- libvpx ---
vpx_tag=$(version libvpx)
git clone --depth 1 https://chromium.googlesource.com/webm/libvpx -b "$vpx_tag"
(cd libvpx && \
  ./configure \
    --prefix="$PREFIX" \
    --target=arm64-win64-gcc \
    --disable-unit-tests --disable-examples --disable-tools --disable-docs \
    --enable-vp8 --enable-vp9 \
    --enable-static --disable-shared && \
  make -j"$(nproc)" && make install)

# --- svt-av1 (encoder, optional but cheap) ---
svt_tag=$(version svt-av1)
git clone --depth 1 https://gitlab.com/AOMediaCodec/SVT-AV1 -b "$svt_tag"
cmake -S SVT-AV1 -B SVT-AV1-build \
  -DCMAKE_SYSTEM_NAME=Windows \
  -DCMAKE_SYSTEM_PROCESSOR=ARM64 \
  -DCMAKE_C_COMPILER="$CC" -DCMAKE_CXX_COMPILER="$CXX" \
  -DCMAKE_INSTALL_PREFIX="$PREFIX" \
  -DBUILD_SHARED_LIBS=OFF -DBUILD_TESTING=OFF -DBUILD_APPS=OFF -DCOVERAGE=OFF
make -C SVT-AV1-build -j"$(nproc)"
make -C SVT-AV1-build install

# --- x264 ---
x264_tag=$(version x264)
git clone https://code.videolan.org/videolan/x264.git x264
(cd x264 && git checkout "$x264_tag" && \
  ./configure --prefix="$PREFIX" --host="$TRIPLE" --cross-prefix="$TRIPLE-" \
    --enable-static --disable-cli --disable-opencl && \
  make -j"$(nproc)" && make install)

# --- x265 ---
x265_tag=$(version x265)
git clone --depth 1 https://bitbucket.org/multicoreware/x265_git.git x265 -b "$x265_tag"
cmake -S x265/source -B x265-build \
  -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_SYSTEM_PROCESSOR=ARM64 \
  -DCMAKE_C_COMPILER="$CC" -DCMAKE_CXX_COMPILER="$CXX" \
  -DCMAKE_INSTALL_PREFIX="$PREFIX" \
  -DENABLE_SHARED=OFF -DENABLE_CLI=OFF -DENABLE_ASSEMBLY=ON
make -C x265-build -j"$(nproc)"
make -C x265-build install

# --- lame ---
lame_tag=$(version lame)
curl -L -o lame.tar.gz "https://downloads.sourceforge.net/project/lame/lame/$lame_tag/lame-$lame_tag.tar.gz"
tar xf lame.tar.gz && mv "lame-$lame_tag" lame
(cd lame && \
  ./configure --prefix="$PREFIX" --host="$TRIPLE" \
    --disable-shared --enable-static --disable-frontend && \
  make -j"$(nproc)" && make install)

# --- opus ---
opus_tag=$(version opus)
git clone --depth 1 https://gitlab.xiph.org/xiph/opus.git -b "$opus_tag"
(cd opus && ./autogen.sh && \
  ./configure --prefix="$PREFIX" --host="$TRIPLE" \
    --disable-shared --enable-static --disable-extra-programs && \
  make -j"$(nproc)" && make install)

# --- mbedtls ---
mbedtls_tag=$(version mbedtls)
git clone --depth 1 --recursive https://github.com/Mbed-TLS/mbedtls.git -b "$mbedtls_tag"
cmake -S mbedtls -B mbedtls-build \
  -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_SYSTEM_PROCESSOR=ARM64 \
  -DCMAKE_C_COMPILER="$CC" -DCMAKE_CXX_COMPILER="$CXX" \
  -DCMAKE_INSTALL_PREFIX="$PREFIX" \
  -DUSE_SHARED_MBEDTLS_LIBRARY=OFF -DENABLE_TESTING=OFF -DENABLE_PROGRAMS=OFF
make -C mbedtls-build -j"$(nproc)"
make -C mbedtls-build install

# --- dav1d ---
dav1d_tag=$(version dav1d)
git clone --depth 1 https://code.videolan.org/videolan/dav1d.git -b "$dav1d_tag"
meson setup dav1d-build dav1d \
  --cross-file "$MESON_CROSS" \
  --prefix="$PREFIX" --buildtype=release --default-library=static \
  -Denable_tools=false -Denable_tests=false -Denable_examples=false
ninja -C dav1d-build
ninja -C dav1d-build install

# --- libaom ---
aom_tag=$(version aom)
git clone --depth 1 https://aomedia.googlesource.com/aom -b "$aom_tag"
cmake -S aom -B aom-build \
  -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_SYSTEM_PROCESSOR=ARM64 \
  -DCMAKE_C_COMPILER="$CC" -DCMAKE_CXX_COMPILER="$CXX" \
  -DCMAKE_INSTALL_PREFIX="$PREFIX" \
  -DBUILD_SHARED_LIBS=OFF -DENABLE_TESTS=OFF -DENABLE_EXAMPLES=OFF -DENABLE_DOCS=OFF \
  -DCONFIG_RUNTIME_CPU_DETECT=1
make -C aom-build -j"$(nproc)"
make -C aom-build install

# --- ffmpeg ---
ffmpeg_tag=$(version ffmpeg)
git clone --depth 1 https://git.ffmpeg.org/ffmpeg.git -b "$ffmpeg_tag"
(cd ffmpeg && \
  ./configure \
    --prefix="$PREFIX" \
    --target-os=mingw32 --arch=aarch64 --cpu=armv8-a \
    --enable-cross-compile \
    --cross-prefix="$TRIPLE-" \
    --cc="$CC" --cxx="$CXX" \
    --pkg-config-flags="--static" \
    --extra-cflags="-I$PREFIX/include" \
    --extra-ldflags="-L$PREFIX/lib" \
    --disable-ffplay \
    --enable-libvpx --enable-libsvtav1 --enable-libdav1d --enable-libaom \
    --enable-libx264 --enable-libx265 --enable-libmp3lame --enable-libopus \
    --enable-mbedtls \
    --enable-runtime-cpudetect --enable-gpl --enable-version3 --enable-static && \
  make -j"$(nproc)")

cp ffmpeg/ffmpeg.exe  "$OUT_DIR/ffmpeg-win-arm64.exe"
cp ffmpeg/ffprobe.exe "$OUT_DIR/ffprobe-win-arm64.exe"
"$STRIP" "$OUT_DIR/ffmpeg-win-arm64.exe" "$OUT_DIR/ffprobe-win-arm64.exe"
ls -la "$OUT_DIR"
