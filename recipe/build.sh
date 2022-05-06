#!/bin/bash
set -ex

if [[ "$target_platform" == osx-* ]]; then
    ls -al ${CONDA_BUILD_SYSROOT}
    CMAKE_ARGS="$CMAKE_ARGS -DDARWIN_osx_ARCHS=x86_64;arm64 -DCOMPILER_RT_ENABLE_IOS=Off"
    CMAKE_ARGS="$CMAKE_ARGS -DDARWIN_macosx_CACHED_SYSROOT=${CONDA_BUILD_SYSROOT} -DDARWIN_macosx_OVERRIDE_SDK_VERSION=${MACOSX_SDK_VERSION}"
    unset CFLAGS
    unset CXXFLAGS
    ln -sf $(which $LIPO) $BUILD_PREFIX/bin/lipo
    ln -sf $(which $LD) $BUILD_PREFIX/bin/ld
    # Use the system libc++ which has dual arch
    cp ${CONDA_BUILD_SYSROOT}/usr/lib/libc++.tbd ${PREFIX}/lib/
    rm ${PREFIX}/lib/libc++.dylib
fi

if [[ "$CONDA_BUILD_CROSS_COMPILATION" == "1" ]]; then
    CMAKE_ARGS="$CMAKE_ARGS -DLLVM_BINARY_DIR=${PREFIX} -DLLVM_TOOLS_BINARY_DIR=${PREFIX}/bin -DLLVM_LIBRARY_DIR=${PREFIX}/lib"
    CMAKE_ARGS="$CMAKE_ARGS -DLLVM_INCLUDE_DIR=${PREFIX}/include -DLLVM_CONFIG_PATH=${BUILD_PREFIX}/bin/llvm-config"
    CMAKE_ARGS="$CMAKE_ARGS -DLLVM_XRAY_LDFLAGS=-L${PREFIX}/lib -DLLVM_TESTINGSUPPORT_LDFLAGS=-L${PREFIX}/lib"
    CMAKE_ARGS="$CMAKE_ARGS -DLLVM_CMAKE_PATH=${PREFIX}/lib/cmake/llvm -DLLVM_TABLEGEN_EXE=${BUILD_PREFIX}/bin/llvm-tblgen"
fi

if [[ "$target_platform" == linux* ]]; then
    export CFLAGS="$CFLAGS -D__STDC_FORMAT_MACROS=1"
    export CPPFLAGS="$CPPFLAGS -D__STDC_FORMAT_MACROS=1"
    export CXXFLAGS="$CXXFLAGS -D__STDC_FORMAT_MACROS=1"
fi

mkdir build
cd build

if [[ "${PKG_VERSION}" == *rc* ]]; then
  export PKG_VERSION=${PKG_VERSION::${#PKG_VERSION}-4}
fi

INSTALL_PREFIX=${PREFIX}/lib/clang/${PKG_VERSION}

# make sure we use our pre-built libcxx, see
# https://github.com/llvm/llvm-project/blame/llvmorg-14.0.0/compiler-rt/CMakeLists.txt#L178-L181
export CMAKE_CXX_FLAGS="$CMAKE_CXX_FLAGS -stdlib=libcxx"
# the following option is confusingly named; it means not rebuild libcxx, see
# https://github.com/llvm/llvm-project/blame/llvmorg-14.0.0/compiler-rt/CMakeLists.txt#L607-L608
CMAKE_ARGS="$CMAKE_ARGS -DCOMPILER_RT_USE_LIBCXX=OFF"

# point compiler-rt to correct C++ stdlib
if [[ "$target_platform" == osx-* ]]; then
    CMAKE_ARGS="$CMAKE_ARGS -DCOMPILER_RT_HAS_LIBCXX=1"
else
    CMAKE_ARGS="$CMAKE_ARGS -DCOMPILER_RT_HAS_LIBSTDCXX=1"
fi

cmake \
    -G "Unix Makefiles" \
    -DCMAKE_BUILD_TYPE="Release" \
    -DLLVM_CONFIG_PATH="$PREFIX/bin/llvm-config" \
    -DLLVM_EXTERNAL_LIT="$PREFIX/bin/lit" \
    -DCOMPILER_RT_STANDALONE_BUILD=1 \
    ${CMAKE_ARGS} \
    -DCMAKE_PREFIX_PATH:PATH="${PREFIX}" \
    -DCMAKE_INSTALL_PREFIX:PATH="${INSTALL_PREFIX}" \
    -DCMAKE_RUNTIME_OUTPUT_DIRECTORY:PATH="${INSTALL_PREFIX}/lib" \
    -DCMAKE_ARCHIVE_OUTPUT_DIRECTORY:PATH="${INSTALL_PREFIX}/lib" \
    -DCMAKE_MODULE_PATH:PATH="${PREFIX}/lib/cmake" \
    -DCOMPILER_RT_DEFAULT_TARGET_TRIPLE=$HOST \
    "${SRC_DIR}"/compiler-rt

# Build step
make -j$CPU_COUNT VERBOSE=1 -k

# Install step
make install -j$CPU_COUNT

# Clean up after build
rm -rf "${PREFIX}/lib/libc++.tbd"
