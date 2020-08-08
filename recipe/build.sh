set -x

if [[ "$target_platform" == "osx-arm64" ]]; then
    EXTRA_CMAKE_ARGS="-DDARWIN_osx_ARCHS=x86_64;arm64 -DCOMPILER_RT_ENABLE_IOS=Off -DCMAKE_OSX_DEPLOYMENT_TARGET=10.16 -DCOMPILER_RT_BUILD_SANITIZERS=no"
    EXTRA_CMAKE_ARGS="$EXTRA_CMAKE_ARGS -DDARWIN_macosx_CACHED_SYSROOT=${CONDA_BUILD_SYSROOT} -DCMAKE_LIBTOOL=$LIBTOOL -DCOMPILER_RT_BUILD_XRAY=no"
    export CC=$PREFIX/bin/clang
    export CXX=$PREFIX/bin/clang++
    unset CFLAGS
    unset CXXFLAGS
    rm -rf $LD
fi
if [[ "$target_platform" == linux* ]]; then
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
    ${EXTRA_CMAKE_ARGS} \
    "${SRC_DIR}"

# Build step
make -j$CPU_COUNT VERBOSE=1

# Install step
make install -j$CPU_COUNT

# Clean up after build
rm -rf "${PREFIX}/lib/cmake/modules"
