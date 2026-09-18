#!/usr/bin/env bash
# Builds the OpenSSL static libraries bundled in luasec/lib/<platform>/ (macOS host).
#
# Usage:
#   scripts/build_openssl.sh                 build every platform listed in ALL_PLATFORMS
#   scripts/build_openssl.sh <platform>...   build only the given Defold platforms
#   scripts/build_openssl.sh headers         refresh luasec/include/openssl from the arm64-osx build
#
# Windows libs are built with scripts/build_openssl.bat on a Windows host.
# Linux libs are built inside the Defold extender docker image (Docker must be running).
# See UPDATE_NOTES.md for details.
set -euo pipefail

OPENSSL_VERSION="${OPENSSL_VERSION:-4.0.2}"
OPENSSL_FLAGS="no-ui-console no-apps no-stdio no-tests no-async no-shared no-docs no-filenames no-gost no-legacy no-module no-ssl-trace"

IOS_MIN_VERSION=11.0
MACOS_X86_64_MIN_VERSION=10.13
MACOS_ARM64_MIN_VERSION=11.0
ANDROID_ARMV7_API=19
ANDROID_ARM64_API=21
ANDROID_NDK_ROOT="${ANDROID_NDK_ROOT:-$HOME/Library/Android/sdk/ndk/25.1.8937393}"
LINUX_IMAGE="europe-west1-docker.pkg.dev/extender-426409/extender-public-registry/extender-linux-env:latest"

ALL_PLATFORMS="arm64-osx x86_64-osx arm64-ios arm64_sim-ios armv7-android arm64-android x86_64-linux arm64-linux"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$ROOT/build/openssl"
LIB_DIR="$ROOT/luasec/lib"
INCLUDE_DIR="$ROOT/luasec/include/openssl"
TARBALL="openssl-$OPENSSL_VERSION.tar.gz"
TARBALL_URL="https://github.com/openssl/openssl/releases/download/openssl-$OPENSSL_VERSION/$TARBALL"
JOBS="$(sysctl -n hw.ncpu 2>/dev/null || nproc)"

log() { echo "[build_openssl] $*"; }

download() {
    mkdir -p "$WORK"
    if [ ! -f "$WORK/$TARBALL" ]; then
        log "downloading $TARBALL_URL"
        curl -sSL -o "$WORK/$TARBALL" "$TARBALL_URL"
        curl -sSL -o "$WORK/$TARBALL.sha256" "$TARBALL_URL.sha256"
    fi
    local expected actual
    expected="$(awk '{print $1}' "$WORK/$TARBALL.sha256")"
    actual="$(shasum -a 256 "$WORK/$TARBALL" | awk '{print $1}')"
    [ "$expected" = "$actual" ] || { log "checksum mismatch for $TARBALL"; exit 1; }
}

extract() {
    local platform=$1
    rm -rf "$WORK/src/$platform" "$WORK/out/$platform"
    mkdir -p "$WORK/src/$platform"
    tar xzf "$WORK/$TARBALL" -C "$WORK/src/$platform" --strip-components=1
    for p in "$ROOT"/scripts/patches/openssl-"$OPENSSL_VERSION"-*.patch; do
        [ -f "$p" ] || continue
        log "$platform: applying $(basename "$p")"
        patch -p1 -d "$WORK/src/$platform" < "$p"
    done
}

copy_libs() {
    local platform=$1
    mkdir -p "$LIB_DIR/$platform"
    cp "$WORK/out/$platform/lib/libssl.a" "$WORK/out/$platform/lib/libcrypto.a" "$LIB_DIR/$platform/"
    log "$platform: libs copied to $LIB_DIR/$platform"
}

# build_native <platform> <configure target> [extra Configure args...]
build_native() {
    local platform=$1 target=$2
    shift 2
    extract "$platform"
    (
        cd "$WORK/src/$platform"
        ./Configure "$target" $OPENSSL_FLAGS "$@" --prefix="$WORK/out/$platform" --libdir=lib
        make -j"$JOBS"
        make install_sw
    )
    copy_libs "$platform"
}

# build_linux <platform> <docker arch> <configure target>
build_linux() {
    local platform=$1 arch=$2 target=$3
    extract "$platform"
    docker run --rm --platform "linux/$arch" -v "$WORK:/build" -w "/build/src/$platform" "$LINUX_IMAGE" \
        bash -c "./Configure $target $OPENSSL_FLAGS --prefix=/build/out/$platform --libdir=lib && make -j\$(nproc) && make install_sw"
    copy_libs "$platform"
}

build_android() {
    local platform=$1 target=$2 api=$3
    [ -d "$ANDROID_NDK_ROOT" ] || { log "ANDROID_NDK_ROOT not found: $ANDROID_NDK_ROOT"; exit 1; }
    local host_tag
    host_tag="$(ls "$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt")"
    export ANDROID_NDK_ROOT
    PATH="$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/$host_tag/bin:$PATH" \
        build_native "$platform" "$target" "-D__ANDROID_API__=$api"
}

build_platform() {
    local platform=$1
    log "building $platform"
    case "$platform" in
        arm64-osx)      build_native "$platform" darwin64-arm64-cc "-mmacosx-version-min=$MACOS_ARM64_MIN_VERSION" ;;
        x86_64-osx)     build_native "$platform" darwin64-x86_64-cc "-mmacosx-version-min=$MACOS_X86_64_MIN_VERSION" ;;
        arm64-ios)      build_native "$platform" ios64-xcrun "-miphoneos-version-min=$IOS_MIN_VERSION" ;;
        arm64_sim-ios)  build_native "$platform" iossimulator-arm64-xcrun "-mios-simulator-version-min=$IOS_MIN_VERSION" ;;
        armv7-android)  build_android "$platform" android-arm "$ANDROID_ARMV7_API" ;;
        arm64-android)  build_android "$platform" android-arm64 "$ANDROID_ARM64_API" ;;
        x86_64-linux)   build_linux "$platform" amd64 linux-x86_64 ;;
        arm64-linux)    build_linux "$platform" arm64 linux-aarch64 ;;
        *) log "unknown platform: $platform"; exit 1 ;;
    esac
}

copy_headers() {
    local src="$WORK/out/arm64-osx/include/openssl"
    [ -d "$src" ] || { log "build arm64-osx first ($src missing)"; exit 1; }
    rm -rf "$INCLUDE_DIR"
    cp -R "$src" "$INCLUDE_DIR"
    log "headers copied to $INCLUDE_DIR"
}

if [ "${1:-}" = "headers" ]; then
    copy_headers
    exit 0
fi

download
for platform in ${@:-$ALL_PLATFORMS}; do
    build_platform "$platform"
done
