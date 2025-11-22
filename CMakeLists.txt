cmake_minimum_required(VERSION 3.16)
project(Hydra LANGUAGES C CXX)

option(BUILD_LIBHYDRA "Build libhydra static library" ON)
option(BUILD_POSIX_TOOLS "Build POSIX-only tools (blit_smoketest, drm_info)" ON)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS OFF)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

if(MSVC)
    add_compile_options(/W3)
else()
    add_compile_options(-Wall -Wextra)
endif()

if(BUILD_LIBHYDRA)
    add_library(libhydra STATIC
        drivers/libhydra/hydra.c
    )
    target_include_directories(libhydra PUBLIC
        drivers/libhydra
        drivers/linux/uapi
    )
endif()

if(BUILD_POSIX_TOOLS AND UNIX)
    add_executable(hydra_blit_smoketest scripts/hydra_blit_smoketest.c)
    target_include_directories(hydra_blit_smoketest PRIVATE drivers/linux/uapi)

    find_package(PkgConfig)
    if(PkgConfig_FOUND)
        pkg_check_modules(LIBDRM libdrm)
    endif()
    if(LIBDRM_FOUND)
        add_executable(hydra_drm_info scripts/hydra_drm_info.c)
        target_include_directories(hydra_drm_info PRIVATE drivers/linux/uapi ${LIBDRM_INCLUDE_DIRS})
        target_link_libraries(hydra_drm_info PRIVATE ${LIBDRM_LIBRARIES})
    endif()
endif()
