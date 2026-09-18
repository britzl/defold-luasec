@echo off
setlocal EnableExtensions
REM Builds the OpenSSL static libraries bundled in luasec\lib\x86_64-win32 and luasec\lib\x86-win32.
REM
REM Requirements (all on PATH): Visual Studio 2022+ with C++ tools (x64 and x86), Perl (Strawberry),
REM NASM, curl and tar. Run from a regular command prompt; vcvarsall is invoked per platform.
REM
REM Usage:
REM   scripts\build_openssl.bat                       build x86_64-win32 and x86-win32
REM   scripts\build_openssl.bat x86_64-win32          build one platform
REM
REM Headers and options.c are NOT touched here; they come from the macOS build (scripts/build_openssl.sh).

if "%OPENSSL_VERSION%"=="" set OPENSSL_VERSION=4.0.2
set OPENSSL_FLAGS=no-ui-console no-apps no-stdio no-tests no-async no-shared no-docs no-filenames no-gost no-legacy no-module no-ssl-trace

set ROOT=%~dp0..
for %%i in ("%ROOT%") do set ROOT=%%~fi
set WORK=%ROOT%\build\openssl
set TARBALL=openssl-%OPENSSL_VERSION%.tar.gz
set TARBALL_URL=https://github.com/openssl/openssl/releases/download/openssl-%OPENSSL_VERSION%/%TARBALL%

for %%t in (perl nasm curl tar) do (
    where %%t >nul 2>&1 || (echo [build_openssl] %%t not found on PATH & exit /b 1)
)

set VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe
if not exist "%VSWHERE%" (echo [build_openssl] vswhere.exe not found, is Visual Studio installed? & exit /b 1)
set VSINSTALL=
for /f "usebackq delims=" %%i in (`"%VSWHERE%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do set VSINSTALL=%%i
if "%VSINSTALL%"=="" (echo [build_openssl] Visual Studio with C++ tools not found & exit /b 1)
set VCVARSALL=%VSINSTALL%\VC\Auxiliary\Build\vcvarsall.bat

if not exist "%WORK%" mkdir "%WORK%"
if not exist "%WORK%\%TARBALL%" (
    echo [build_openssl] downloading %TARBALL_URL%
    curl -sSL -o "%WORK%\%TARBALL%" %TARBALL_URL% || exit /b 1
    curl -sSL -o "%WORK%\%TARBALL%.sha256" %TARBALL_URL%.sha256 || exit /b 1
)
set EXPECTED=
set ACTUAL=
for /f "usebackq" %%h in ("%WORK%\%TARBALL%.sha256") do if "%EXPECTED%"=="" set EXPECTED=%%h
for /f "usebackq delims=" %%h in (`certutil -hashfile "%WORK%\%TARBALL%" SHA256 ^| findstr /v /i "hash CertUtil"`) do if "%ACTUAL%"=="" set ACTUAL=%%h
set ACTUAL=%ACTUAL: =%
if /i not "%ACTUAL%"=="%EXPECTED%" (echo [build_openssl] checksum mismatch for %TARBALL% & exit /b 1)

set PLATFORMS=%*
if "%PLATFORMS%"=="" set PLATFORMS=x86_64-win32 x86-win32
for %%p in (%PLATFORMS%) do (
    call :build %%p || exit /b 1
)
exit /b 0

:build
set PLATFORM=%1
if "%PLATFORM%"=="x86_64-win32" (
    set ARCH=x64
    set TARGET=VC-WIN64A
) else if "%PLATFORM%"=="x86-win32" (
    set ARCH=x86
    set TARGET=VC-WIN32
) else (
    echo [build_openssl] unknown platform: %PLATFORM%
    exit /b 1
)
set SRC=%WORK%\src\%PLATFORM%
set OUT=%WORK%\out\%PLATFORM%
echo [build_openssl] building %PLATFORM% (%TARGET%)
if exist "%SRC%" rmdir /s /q "%SRC%"
if exist "%OUT%" rmdir /s /q "%OUT%"
mkdir "%SRC%"
tar xzf "%WORK%\%TARBALL%" -C "%SRC%" --strip-components=1 || exit /b 1
setlocal
call "%VCVARSALL%" %ARCH% || exit /b 1
cd /d "%SRC%"
perl Configure %TARGET% %OPENSSL_FLAGS% --prefix="%OUT%" --openssldir="%OUT%\ssl" --libdir=lib || exit /b 1
nmake || exit /b 1
nmake install_sw || exit /b 1
endlocal
if not exist "%ROOT%\luasec\lib\%PLATFORM%" mkdir "%ROOT%\luasec\lib\%PLATFORM%"
copy /y "%OUT%\lib\libssl.lib" "%ROOT%\luasec\lib\%PLATFORM%\" >nul || exit /b 1
copy /y "%OUT%\lib\libcrypto.lib" "%ROOT%\luasec\lib\%PLATFORM%\" >nul || exit /b 1
echo [build_openssl] %PLATFORM%: libs copied to luasec\lib\%PLATFORM%
exit /b 0
