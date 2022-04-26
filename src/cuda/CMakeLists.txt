CMAKE_MINIMUM_REQUIRED(VERSION 2.8)

FIND_PACKAGE(CUDA REQUIRED)

INCLUDE("${CMAKE_MODULE_PATH}/FindNVVM.cmake")

# Disables running cuda_compute_check.c when build windows using remote
OPTION(CUDA_COMPUTE_DETECT "Run autodetection of CUDA Architecture" ON)
MARK_AS_ADVANCED(CUDA_COMPUTE_DETECT)

IF(CUDA_COMPUTE_DETECT AND NOT DEFINED COMPUTES_DETECTED_LIST)
    INCLUDE("${CMAKE_MODULE_PATH}/CUDACheckCompute.cmake")
ENDIF()

IF(    CUDA_COMPUTE_20
    OR CUDA_COMPUTE_30
    OR CUDA_COMPUTE_32
    OR CUDA_COMPUTE_35
    OR CUDA_COMPUTE_50
    OR CUDA_COMPUTE_52
    OR CUDA_COMPUTE_53
    )
    SET(FALLBACK OFF)
ELSE()
    SET(FALLBACK ON)
ENDIF()

LIST(LENGTH COMPUTES_DETECTED_LIST COMPUTES_LEN)
IF(${COMPUTES_LEN} EQUAL 0 AND ${FALLBACK})
    MESSAGE(STATUS "No computes detected. Fall back to 20, 30, 50")
    LIST(APPEND COMPUTES_DETECTED_LIST "20" "30" "50")
ENDIF()

LIST(LENGTH COMPUTES_DETECTED_LIST COMPUTES_LEN)
MESSAGE(STATUS "Number of Computes Detected = ${COMPUTES_LEN}")

FOREACH(COMPUTE_DETECTED ${COMPUTES_DETECTED_LIST})
    SET(CUDA_COMPUTE_${COMPUTE_DETECTED} ON CACHE BOOL "" FORCE)
ENDFOREACH()

MACRO(SET_COMPUTE VERSION)
    SET(CUDA_GENERATE_CODE_${VERSION} "-gencode arch=compute_${VERSION},code=sm_${VERSION}")
    SET(CUDA_GENERATE_CODE ${CUDA_GENERATE_CODE} ${CUDA_GENERATE_CODE_${VERSION}})
    LIST(APPEND COMPUTE_VERSIONS "${VERSION}")
    MESSAGE(STATUS "Setting Compute ${VERSION} to ON")
ENDMACRO(SET_COMPUTE)

# Iterate over compute versions. Create variables and enable computes if needed
FOREACH(VER 20 30 32 35 50 52 53)
    OPTION(CUDA_COMPUTE_${VER} "CUDA Compute Capability ${VER}" OFF)
    MARK_AS_ADVANCED(CUDA_COMPUTE_${VER})
    IF(${CUDA_COMPUTE_${VER}})
        SET_COMPUTE(${VER})
    ENDIF()
ENDFOREACH()

IF(UNIX)
    SET(CUDA_NVCC_FLAGS ${CUDA_NVCC_FLAGS} -Xcompiler -fvisibility=hidden)
    REMOVE_DEFINITIONS(-std=c++0x)
ENDIF()

ADD_DEFINITIONS(-DAF_CUDA)

INCLUDE_DIRECTORIES(
    ${CMAKE_INCLUDE_PATH}
    ${CUDA_INCLUDE_DIRS}
    "${CMAKE_SOURCE_DIR}/src/common"
    "${CMAKE_SOURCE_DIR}/src/cuda"
    ${CUDA_NVVM_INCLUDE_DIR}
    )

FILE(GLOB headers
    "../common/*.hpp"
    "../common/*.h"
     "*.hpp"
     "*.h")

FILE(GLOB sources
    "../common/*.cpp"
    "*.cu"
    )

SOURCE_GROUP(cuda\\Headers FILES ${headers})
SOURCE_GROUP(cuda\\Sources FILES ${sources})

SET(CUDA_NVCC_FLAGS "${CUDA_NVCC_FLAGS} ${CUDA_GENERATE_CODE}")

IF("${APPLE}")
    ADD_DEFINITIONS(-D__STRICT_ANSI__)
    IF(${CMAKE_CXX_COMPILER_ID} STREQUAL "Clang")
        IF(${CUDA_VERSION_MAJOR} VERSION_LESS 7)
            SET(STD_LIB_BINDING "-stdlib=libstdc++")
        ELSE(${CUDA_VERSION_MAJOR} VERSION_LESS 7)
            SET(STD_LIB_BINDING "-stdlib=libc++")
        ENDIF()

        ADD_DEFINITIONS("${STD_LIB_BINDING}")
        SET(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} ${STD_LIB_BINDING}")
        SET(CMAKE_STATIC_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} ${STD_LIB_BINDING}")
        SET(CUDA_HOST_COMPILER "/usr/bin/clang++")
    ENDIF()
ENDIF()

CUDA_ADD_EXECUTABLE(pi_cuda
                    ${headers}
                    ${sources}
                    )

TARGET_LINK_LIBRARIES(pi_cuda
                      ${ArrayFire_CUDA_LIBRARIES}
                      ${CUDA_CUBLAS_LIBRARIES}
                      ${CUDA_LIBRARIES}
                      ${CUDA_cusolver_LIBRARY}
                      ${CUDA_CUFFT_LIBRARIES}
                      ${CUDA_NVVM_LIBRARIES}
                      ${CUDA_CUDA_LIBRARY}
                     )
