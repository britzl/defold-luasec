# OpenSSL update notes
Current version is 3.4.1. OpenSSL was built with the following options:
* no-ui-console
* no-apps
* no-stdio
* no-tests
* no-async (need to avoid usage of private functions on Apple platform. More details [issue](https://github.com/sonountaleban/defold-luasec/issues/4)
* no-shared
* no-docs
* no-afalgeng
* no-autoerrinit
* no-capieng
* no-engine
* no-err
* no-filenames
* no-gost
* no-legacy
* no-module
* no-padlockeng
* no-ssl-trace
* no-static-engine

Option's descriptions can be found [here](https://github.com/openssl/openssl/blob/master/INSTALL.md#enable-and-disable-features).

## Building
In most cases, the $OUTPUT_DIR variable is used as the base output directory for OpenSSL installation.
Running `make clean` after installation removes temporary build files, ensuring a clean workspace for future builds.

### Linux
The Docker image (europe-west1-docker.pkg.dev/extender-426409/extender-public-registry/extender-linux-env:latest) can be used for compile OpenSSL. As $OUTPUT_DIR you should use any mounted to the docker container directory. Here is commands for it (tested on arm64 host):
```sh
docker run --platform linux/amd64 -it -v <path-to-openssl-folder>:/build europe-west1-docker.pkg.dev/extender-426409/extender-public-registry/extender-linux-env:latest /bin/sh
cd /build
./Configure linux-x86_64 no-ui-console no-apps no-stdio no-tests no-async no-shared no-docs no-afalgeng no-autoerrinit no-capieng no-engine no-err no-filenames no-gost no-legacy no-module no-padlockeng no-ssl-trace no-static-engine --prefix="$OUTPUT_DIR/linux/x64"
make
make install
make clean
exit

docker run --platform linux/amd64 -it -v <path-to-openssl-folder>:/build europe-west1-docker.pkg.dev/extender-426409/extender-public-registry/extender-linux-env:latest /bin/sh
./Configure linux-aarch64 no-ui-console no-apps no-stdio no-tests no-async no-shared no-docs no-afalgeng no-autoerrinit no-capieng no-engine no-err no-filenames no-gost no-legacy no-module no-padlockeng no-ssl-trace no-static-engine --prefix="$OUTPUT_DIR/linux/arm64"
make
make install
make clean
```

### Android
```sh
./Configure android-arm no-ui-console no-apps no-stdio no-tests no-async no-shared no-docs no-afalgeng no-autoerrinit no-capieng no-engine no-err no-filenames no-gost no-legacy no-module no-padlockeng no-ssl-trace no-static-engine --prefix="$OUTPUT_DIR/android/armv7" -D__ANDROID_API__=19
make
make install
make clean
./Configure android-arm64 no-ui-console no-apps no-stdio no-tests no-async no-shared no-docs no-afalgeng no-autoerrinit no-capieng no-engine no-err no-filenames no-gost no-legacy no-module no-padlockeng no-ssl-trace no-static-engine --prefix="$OUTPUT_DIR/android/arm64" -D__ANDROID_API__=21
make
make install
make clean
```

### iOS
```sh
export IOS_DEPLOYMENT_TARGET=11.0
export CROSS_TOP="$(xcrun --sdk iphoneos --show-sdk-path)/../../"
export CROSS_SDK="iPhoneOS.sdk"
export CC="xcrun --sdk iphoneos clang -arch arm64 -mios-version-min=$IOS_DEPLOYMENT_TARGET"
./Configure ios64-cross no-ui-console no-apps no-stdio no-tests no-async no-shared no-docs no-afalgeng no-autoerrinit no-capieng no-engine no-err no-filenames no-gost no-legacy no-module no-padlockeng no-ssl-trace no-static-engine --prefix="$OUTPUT_DIR/ios/arm64"
make
make install
unset CROSS_TOP
unset CROSS_SDK
unset CC
```

### MacOS
```sh
export MACOSX_DEPLOYMENT_TARGET=10.13
export CFLAGS="-mmacosx-version-min=$MACOSX_DEPLOYMENT_TARGET"
export LDFLAGS="-mmacosx-version-min=$MACOSX_DEPLOYMENT_TARGET"
./Configure darwin64-x86_64-cc no-ui-console no-apps no-stdio no-tests no-async no-shared no-docs no-afalgeng no-autoerrinit no-capieng no-engine no-err no-filenames no-gost no-legacy no-module no-padlockeng no-ssl-trace no-static-engine --prefix="$OUTPUT_DIR/macos/x64"
make
make install
make clean
./Configure darwin64-arm64-cc no-ui-console no-apps no-stdio no-tests no-async no-shared no-docs no-afalgeng no-autoerrinit no-capieng no-engine no-err no-filenames no-gost no-legacy no-module no-padlockeng no-ssl-trace no-static-engine --prefix="$OUTPUT_DIR/macos/arm64"
make
make install
make clean
unset CFLAGS
unset LDFLAGS
```

### Windows
It is important to meet the requirements described [here](https://github.com/openssl/openssl/blob/master/NOTES-WINDOWS.md#requirement-details).
```sh
perl Configure VC-WIN64A no-ui-console no-apps no-stdio no-tests no-async no-shared no-docs no-afalgeng no-autoerrinit no-capieng no-engine no-err no-filenames no-gost no-legacy no-module no-padlockeng no-ssl-trace no-static-engine --prefix="......."
nmake
nmake install
nmake clean
perl Configure VC-WIN32 no-ui-console no-apps no-stdio no-tests no-async no-shared no-docs no-afalgeng no-autoerrinit no-capieng no-engine no-err no-filenames no-gost no-legacy no-module no-padlockeng no-ssl-trace no-static-engine --prefix="......."
nmake
nmake install
nmake clean
```

## Generate options.c
After updating the header files and static libraries, you need to regenerate `options.c`, which contains OpenSSL configuration options used by the LuaSec extension. Run following command:
```sh
lua options.lua -g ./luasec/include/openssl/ssl.h > ./luasec/src/options.c 
```