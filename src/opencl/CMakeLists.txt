CMAKE_MINIMUM_REQUIRED(VERSION 2.8.7)

FIND_PACKAGE(OpenCL REQUIRED)

ADD_DEFINITIONS(-DAF_OPENCL
                -D__CL_ENABLE_EXCEPTIONS)

# OS Definitions
IF(UNIX)
    SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fPIC -pthread -Wno-comment")
ELSE(${UNIX}) #Windows
    SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
    SET(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} /bigobj")
    SET(CMAKE_CXX_FLAGS_RELWITHDEBINFO "${CMAKE_CXX_FLAGS_RELWITHDEBINFO} /bigobj")
ENDIF()

INCLUDE_DIRECTORIES(
    ${CMAKE_INCLUDE_PATH}
    ${OpenCL_INCLUDE_DIRS}
    "${CMAKE_SOURCE_DIR}/src/common"
    "${CMAKE_SOURCE_DIR}/src/opencl"
    )

FILE(GLOB headers
    "../common/*.hpp"
    "../common/*.h"
     "*.hpp"
     "*.h")

FILE(GLOB sources
    "../common/*.cpp"
    "*.cpp"
    )

SOURCE_GROUP(opencl\\Headers FILES ${headers})
SOURCE_GROUP(opencl\\Sources FILES ${sources})

ADD_EXECUTABLE(pi_opencl
               ${headers}
               ${sources}
              )

TARGET_LINK_LIBRARIES(pi_opencl
                      ${ArrayFire_OpenCL_LIBRARIES}
                      ${OpenCL_LIBRARIES}
                     )
