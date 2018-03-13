#!/usr/bin/env bash

# From https://gist.github.com/foozmeat/5154962
# Also https://github.com/x2on/OpenSSL-for-iPhone

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DEVELOPER=`xcode-select -print-path`
PLATFORM="iPhoneOS"
SDK_VERSION="11.2"
OPENSSL_DIR="openssl-OpenSSL_1_1_0e"
OUT_BASEDIR="${SCRIPTDIR}/${OPENSSL_DIR}/build"

export $PLATFORM
export CROSS_TOP="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
export CROSS_SDK="${PLATFORM}${SDK_VERSION}.sdk"
export BUILD_TOOLS="${DEVELOPER}"

function pcall {
	"$@"
	local status=$?
	if [ $status -ne 0 ]; then
		echo "Error"
		exit $status
	fi
	return $status
}

build() {
	ARCH=$1
	OUT="${OUT_BASEDIR}/${ARCH}"
	export CC="${BUILD_TOOLS}/usr/bin/gcc -arch ${ARCH}"

	pcall cd "${OPENSSL_DIR}"
	pcall rm -rf "${OUT}"
	pcall mkdir -p "${OUT}"
	pcall ./Configure iphoneos-cross no-async --prefix="${OUT}" --openssldir="${OUT}"
	# add -isysroot to CC=
	pcall sed -ie "s!^CFLAG=!CFLAG=-isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} -miphoneos-version-min=${SDK_VERSION} !" "Makefile"

	pcall make
	pcall make install
	pcall make clean
	#pcall make test
	pcall cd ..
}

build armv7
build arm64

pcall lipo ${OUT_BASEDIR}/armv7/lib/libcrypto.a ${OUT_BASEDIR}/arm64/lib/libcrypto.a -create -output libcrypto.a
pcall lipo ${OUT_BASEDIR}/armv7/lib/libssl.a ${OUT_BASEDIR}/arm64/lib/libssl.a -create -output libssl.a
