@echo on

mkdir build
cd build

set BUILD_CONFIG=Release
set "CC=clang-cl.exe"
set "CXX=clang-cl.exe"
set "INSTALL_PREFIX=%LIBRARY_PREFIX%\lib\clang\%PKG_VERSION%"

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

mkdir %PREFIX%\lib\clang\%PKG_VERSION%\lib\windows
copy %INSTALL_PREFIX%\lib\windows\* %PREFIX%\lib\clang\%PKG_VERSION%\lib\windows\
