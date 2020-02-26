mkdir build
if errorlevel 1 exit 1

cd build
if errorlevel 1 exit 1

set BUILD_CONFIG=Release
if errorlevel 1 exit 1

set "CC=cl.exe"
set "CXX=cl.exe"

cmake ^
    -G "NMake Makefiles" ^
    -DCMAKE_BUILD_TYPE="Release" ^
    -DCMAKE_PREFIX_PATH:PATH="%LIBRARY_PREFIX%" ^
    -DCMAKE_INSTALL_PREFIX:PATH="%LIBRARY_PREFIX%" ^
    -DCMAKE_RUNTIME_OUTPUT_DIRECTORY:PATH="%LIBRARY_BIN%" ^
    -DCMAKE_ARCHIVE_OUTPUT_DIRECTORY:PATH="%LIBRARY_LIB%" ^
    -DCMAKE_MODULE_PATH:PATH="%LIBRARY_LIB%\cmake" ^
    -DLLVM_CONFIG_PATH:PATH="%LIBRARY_BIN%\llvm-config.exe" ^
    "%SRC_DIR%"
if errorlevel 1 exit 1

:: Build step
nmake
if errorlevel 1 exit 1

:: Install step
nmake install
if errorlevel 1 exit 1

