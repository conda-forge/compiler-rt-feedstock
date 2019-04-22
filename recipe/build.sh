if [[ "$target_platform" == "osx-64" ]]; then
    export CONDA_BUILD_SYSROOT_BACKUP=${CONDA_BUILD_SYSROOT}
    conda install -p $BUILD_PREFIX --quiet --yes clangxx_osx-64=${cxx_compiler_version}
    export CONDA_BUILD_SYSROOT=${CONDA_BUILD_SYSROOT_BACKUP}
    EXTRA_CMAKE_ARGS="-DDARWIN_osx_ARCHS=x86_64 -DDARWIN_osxsim_ARCHS=x86_64"
fi

# Prep build
cp -R "${PREFIX}/lib/cmake/llvm" "${PREFIX}/lib/cmake/modules/"

mkdir build
cd build

cmake \
    -G "Unix Makefiles" \
    -DCMAKE_BUILD_TYPE="Release" \
    -DCMAKE_PREFIX_PATH:PATH="${PREFIX}" \
    -DCMAKE_INSTALL_PREFIX:PATH="${PREFIX}" \
    -DCMAKE_RUNTIME_OUTPUT_DIRECTORY:PATH="${PREFIX}/lib" \
    -DCMAKE_ARCHIVE_OUTPUT_DIRECTORY:PATH="${PREFIX}/lib" \
    -DCMAKE_MODULE_PATH:PATH="${PREFIX}/lib/cmake" \
    -DLLVM_CONFIG_PATH:PATH="${PREFIX}/bin/llvm-config" \
    -DPYTHON_EXECUTABLE:PATH="${BUILD_PREFIX}/bin/python" \
    ${EXTRA_CMAKE_ARGS} \
    "${SRC_DIR}"

# Build step
make -j$CPU_COUNT

# Install step
make install -j$CPU_COUNT

# Clean up after build
rm -rf "${PREFIX}/lib/cmake/modules"
