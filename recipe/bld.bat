@echo on
setlocal enabledelayedexpansion

mkdir build
cd build

:: strip off ".rcX" suffixes, which are not part of the installation path
set PKG_VERSION=%PKG_VERSION:.rc1=%
set PKG_VERSION=%PKG_VERSION:.rc2=%
set PKG_VERSION=%PKG_VERSION:.rc3=%
set PKG_VERSION=%PKG_VERSION:.rc4=%
set PKG_VERSION=%PKG_VERSION:.rc5=%

set BUILD_CONFIG=Release
set "CC=clang-cl.exe"
set "CXX=clang-cl.exe"

for /f "tokens=1 delims=." %%i in ("%PKG_VERSION%") do (
  set "MAJOR_VER=%%i"
)

set "INSTALL_PREFIX=%LIBRARY_PREFIX%\lib\clang\%MAJOR_VER%"

cmake -G Ninja ^
    -DCMAKE_BUILD_TYPE="Release" ^
    -DCMAKE_PREFIX_PATH:PATH="%LIBRARY_PREFIX%" ^
    -DCMAKE_INSTALL_PREFIX:PATH="%INSTALL_PREFIX%" ^
    -DCMAKE_MODULE_PATH:PATH="%LIBRARY_LIB%\cmake" ^
    -DLLVM_CONFIG_PATH:PATH="%LIBRARY_BIN%\llvm-config.exe" ^
    -DLLVM_EXTERNAL_LIT="%LIBRARY_BIN%\lit" ^
    -DCOMPILER_RT_STANDALONE_BUILD=1 ^
    "%SRC_DIR%"\compiler-rt
if %ERRORLEVEL% neq 0 exit 1

:: Build step
cmake --build .
if %ERRORLEVEL% neq 0 exit 1

:: Install step
cmake --install .
if %ERRORLEVEL% neq 0 exit 1

FOR /F "tokens=* USEBACKQ" %%F IN (`clang -print-resource-dir`) DO (
    set "RESOURCE_DIR=%%F"
)
if "!RESOURCE_DIR!" NEQ "%INSTALL_PREFIX%" (
    echo "Wrong install prefix (%INSTALL_PREFIX%). Should match !RESOURCE_DIR!"
    exit 1
)

:: Also install into %PREFIX%\lib (!= %PREFIX%\Library\lib, the default on win)
:: because compiler-rt_win-64 is noarch and needs to be installable on linux,
:: where we don't want the "\Library"; aside from removing that directory,
:: the paths are the same. Separation into proper outputs happens in the recipe.
set "INSTALL_PREFIX_NOARCH=%PREFIX%\lib\clang\%MAJOR_VER%"
mkdir %INSTALL_PREFIX_NOARCH%\lib\windows
copy %INSTALL_PREFIX%\lib\windows\* %INSTALL_PREFIX_NOARCH%\lib\windows\
