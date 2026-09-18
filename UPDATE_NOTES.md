# OpenSSL update notes
Current version is 4.0.2. OpenSSL is built as static libraries with the following options:
* no-ui-console
* no-apps
* no-stdio
* no-tests
* no-async (need to avoid usage of private functions on Apple platform. More details [issue](https://github.com/sonountaleban/defold-luasec/issues/4)
* no-shared
* no-docs
* no-filenames
* no-gost
* no-legacy
* no-module
* no-ssl-trace

The ENGINE API was removed in OpenSSL 4.0, so the `no-engine`, `no-afalgeng`, `no-capieng`, `no-padlockeng` and
`no-static-engine` options used for 3.x are no longer needed. `no-deprecated` must NOT be used: LuaSec still relies on
APIs that are only deprecated (see `LSEC_API_OPENSSL_*` in `luasec/include/compat.h` for the version switches).

Option's descriptions can be found [here](https://github.com/openssl/openssl/blob/master/INSTALL.md#enable-and-disable-features).

## Building
The version, options, deployment targets and NDK path are defined at the top of the build scripts. Both scripts
download and verify the release tarball into `build/openssl/`, build every target from a fresh source tree and copy the
resulting libraries into `luasec/lib/<platform>/`.

### macOS, iOS, iOS simulator, Android, Linux (macOS host)
Requirements: Xcode, Android NDK r25 (`ANDROID_NDK_ROOT`, defaults to `~/Library/Android/sdk/ndk/25.1.8937393`) and a
running Docker (Linux libs are built inside the Defold extender image
`europe-west1-docker.pkg.dev/extender-426409/extender-public-registry/extender-linux-env:latest`, which is multi-arch:
`--platform linux/amd64` for `x86_64-linux` and `--platform linux/arm64` for `arm64-linux`).
```sh
scripts/build_openssl.sh                  # all platforms below
scripts/build_openssl.sh arm64_sim-ios    # a single platform
scripts/build_openssl.sh headers          # refresh luasec/include/openssl (see below)
```

| Defold platform | Configure target | Extra flags |
|---|---|---|
| `arm64-osx` | `darwin64-arm64-cc` | `-mmacosx-version-min=11.0` |
| `x86_64-osx` | `darwin64-x86_64-cc` | `-mmacosx-version-min=10.13` |
| `arm64-ios` | `ios64-xcrun` | `-miphoneos-version-min=11.0` |
| `arm64_sim-ios` | `iossimulator-arm64-xcrun` | `-mios-simulator-version-min=11.0` (clang raises it to 14.0, the minimum for Apple silicon simulators) |
| `armv7-android` | `android-arm` | `-D__ANDROID_API__=19` |
| `arm64-android` | `android-arm64` | `-D__ANDROID_API__=21` |
| `x86_64-linux` | `linux-x86_64` | built in docker (`linux/amd64`) |
| `arm64-linux` | `linux-aarch64` | built in docker (`linux/arm64`) |

Every target is configured as `./Configure <target> <options> <extra flags> --prefix=build/openssl/out/<platform> --libdir=lib`
followed by `make` and `make install_sw`. The iOS simulator libraries must be built against the iPhoneSimulator SDK:
device libraries are tagged for iOS and cannot be linked into a simulator binary.

Patches in `scripts/patches/openssl-<version>-*.patch` are applied to the extracted sources before configuring.
Currently `openssl-4.0.2-poly1305-sve2-visibility.patch` backports the upstream fix for the SVE2 Poly1305 symbol
visibility (openssl/openssl#32132): without it the arm64 Android engine (a shared library) fails to link with
`relocation R_AARCH64_ADR_PREL_PG_HI21 cannot be used against symbol 'poly1305_blocks_sve2'`. It is included in
OpenSSL 4.0.3+, remove the patch when updating past 4.0.2.

### Windows (Windows host)
Requirements are described [here](https://github.com/openssl/openssl/blob/master/NOTES-WINDOWS.md#requirement-details):
Visual Studio with C++ tools (x64 and x86), Perl, NASM, plus `curl` and `tar` on PATH.
```bat
scripts\build_openssl.bat                 # x86_64-win32 (VC-WIN64A) and x86-win32 (VC-WIN32)
scripts\build_openssl.bat x86_64-win32    # a single platform
```
The script runs `vcvarsall.bat` for each architecture, then `perl Configure`, `nmake` and `nmake install_sw`.
It only updates `luasec\lib\x86_64-win32\*.lib` and `luasec\lib\x86-win32\*.lib`, and applies no patches
(the current one is aarch64-only).

## Headers
`luasec/include/openssl` holds a single copy of the headers for all platforms, taken from the `arm64-osx` build
(`scripts/build_openssl.sh headers` replaces the whole directory). `configuration.h` and `opensslv.h` are generated,
so make sure they come from the new version.

## Generate options.c
After updating the header files, regenerate `options.c`, which lists the `SSL_OP_*` options exposed by LuaSec:
```sh
lua options.lua -g ./luasec/include/openssl/ssl.h "OpenSSL 4.0.2" > ./luasec/src/options.c
```

## Checking the result
* Version: `strings luasec/lib/<platform>/libcrypto.a | grep "OpenSSL 4"` and `OPENSSL_VERSION_STR` in `luasec/include/openssl/opensslv.h`.
* Apple platform tags: `otool -l luasec/lib/<platform>/libcrypto.a | grep -A3 LC_BUILD_VERSION` (`platform 1` macOS, `2` iOS, `7` iOS simulator).
* Deprecated API usage in the extension sources:
  `clang++ -fsyntax-only -x c++ -DOPENSSL_NO_DEPRECATED -Iluasec/include -I<defoldsdk>/sdk/include -I<defoldsdk>/include luasec/src/*.c luasec/src/luasec.cpp`
* Build the test project with bob for every platform (the extender compiles the extension against the new libraries).
* Automated client/server tests: build a headless macOS engine and run a server and a client, e.g.
  `LUASEC_TEST=dhparam.server ./dmengine_headless` and `LUASEC_TEST=dhparam.client ./dmengine_headless`
  (certificates must be generated first, see README.md).
