if [[ "$cross_platform" == "osx-64" ]]; then
    EXTRA_CMAKE_ARGS="-DDARWIN_osx_ARCHS=x86_64 -DCOMPILER_RT_ENABLE_IOS=Off -DCMAKE_OSX_DEPLOYMENT_TARGET=10.9"
    export MACOSX_DEPLOYMENT_TARGET=10.9
fi
if [[ "$cross_platform" == "osx-arm64" ]]; then
    EXTRA_CMAKE_ARGS="-DDARWIN_osx_ARCHS=arm64;arm64e -DCOMPILER_RT_ENABLE_IOS=Off -DCMAKE_OSX_DEPLOYMENT_TARGET=10.16"
    export MACOSX_DEPLOYMENT_TARGET=11.0
fi
if [[ "$cross_platform" == osx* ]]; then
    EXTRA_CMAKE_ARGS="$EXTRA_CMAKE_ARGS -DDARWIN_macosx_CACHED_SYSROOT=${CONDA_BUILD_SYSROOT} -DCMAKE_LIBTOOL=$LIBTOOL -DCMAKE_LINKER=ld64.lld"
    LDFLAGS="$LDFLAGS -fuse-ld=lld"
    export CC=$PREFIX/bin/clang
    export CXX=$PREFIX/bin/clang++
fi
if [[ "$cross_platform" == linux* ]]; then
    export CFLAGS="$CFLAGS -D__STDC_FORMAT_MACROS=1"
    export CPPFLAGS="$CPPFLAGS -D__STDC_FORMAT_MACROS=1"
    export CXXFLAGS="$CXXFLAGS -D__STDC_FORMAT_MACROS=1"
fi

# Prep build
cp -R "${PREFIX}/lib/cmake/llvm" "${PREFIX}/lib/cmake/modules/"

mkdir build
cd build

INSTALL_PREFIX=${PREFIX}/lib/clang/${PKG_VERSION}

cmake \
    -G "Unix Makefiles" \
    -DCMAKE_BUILD_TYPE="Release" \
    -DCMAKE_PREFIX_PATH:PATH="${PREFIX}" \
    -DCMAKE_INSTALL_PREFIX:PATH="${INSTALL_PREFIX}" \
    -DCMAKE_RUNTIME_OUTPUT_DIRECTORY:PATH="${INSTALL_PREFIX}/lib" \
    -DCMAKE_ARCHIVE_OUTPUT_DIRECTORY:PATH="${INSTALL_PREFIX}/lib" \
    -DCMAKE_MODULE_PATH:PATH="${PREFIX}/lib/cmake" \
    -DLLVM_CONFIG_PATH:PATH="${PREFIX}/bin/llvm-config" \
    -DPYTHON_EXECUTABLE:PATH="${BUILD_PREFIX}/bin/python" \
    -DCMAKE_LINKER="$LD" \
    ${EXTRA_CMAKE_ARGS} \
    "${SRC_DIR}"

# Build step
make -j$CPU_COUNT VERBOSE=1

# Install step
make install -j$CPU_COUNT

# Clean up after build
rm -rf "${PREFIX}/lib/cmake/modules"
