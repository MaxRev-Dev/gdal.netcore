# Overlay of the upstream libaec port, identical to the pinned baseline
# (vcpkg c3867e71, libaec 1.1.6) except that the source is fetched from GitHub
# instead of gitlab.dkrz.de.
#
# Why: gitlab.dkrz.de answers CI runners with HTTP 429 for minutes at a time,
# which fails the whole vcpkg install on linux-arm64 and both macOS jobs. The
# host is fine from a normal IP, so this is rate limiting aimed at cloud CI
# ranges; retry tuning does not get past it.
#
# Deutsches-Klimarechenzentrum/libaec is the same project - vcpkg upstream has
# itself since moved this port to vcpkg_from_github against that repo. The v1.1.6
# tag there is byte-identical in content to the GitLab archive; only the archive
# hash differs, because GitHub and GitLab generate tarballs differently.
#
# Remove this overlay once the vcpkg baseline is new enough to carry the
# GitHub-based port (libaec >= 1.1.7).
vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO Deutsches-Klimarechenzentrum/libaec
    REF "v${VERSION}"
    SHA512 76df7501d1b7d91a43b525ba828f092f18d83f8ab09a9331e5758f93942a9758ad580baca8f9316b92a98639bde2e23cacbc2f33f52d0dd98ce7efe412cf43cd
    HEAD_REF master
)

string(COMPARE EQUAL "${VCPKG_LIBRARY_LINKAGE}" "static" BUILD_STATIC)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DBUILD_STATIC_LIBS=${BUILD_STATIC}
        -Dlibaec_INSTALL_CMAKEDIR=share/${PORT}
)
vcpkg_cmake_install()
vcpkg_copy_pdbs()
vcpkg_cmake_config_fixup()
vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/share/libaec/libaec-config.cmake"
    "if(libaec_USE_STATIC_LIBS)"
    "if(\"${BUILD_STATIC}\") # forced by vcpkg"
)

# Compatibility with user's CMake < 3.18 (vcpkg claims support for >= 3.16):
# Make imported targets global so that libaec-config.cmake can create ALIAS targets.
set(_target_file "libaec_shared-targets")
if(BUILD_STATIC)
    set(_target_file "libaec_static-targets")
endif()
file(READ "${CURRENT_PACKAGES_DIR}/share/libaec/${_target_file}.cmake" libaec_targets)
string(REGEX REPLACE " (SHARED|STATIC) IMPORTED" " \\1 IMPORTED \${libaec_maybe_global}" libaec_targets "${libaec_targets}")
file(WRITE "${CURRENT_PACKAGES_DIR}/share/libaec/${_target_file}.cmake" "set(libaec_maybe_global \"\")
if(CMAKE_VERSION VERSION_LESS 3.18)
    set(libaec_maybe_global \"GLOBAL\")
endif()
${libaec_targets}
"
)

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

file(INSTALL "${CURRENT_PORT_DIR}/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE.txt")
