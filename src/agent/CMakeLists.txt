cmake_minimum_required(VERSION 3.16)
project(polyvault_agent VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# 选项
option(USE_ECAL "Enable eCAL support" ON)
option(BUILD_TESTS "Build tests" OFF)

# 查找依赖
find_package(Protobuf REQUIRED)

# eCAL支持（可选）
if(USE_ECAL)
    find_package(eCAL REQUIRED)
    add_definitions(-DUSE_ECAL)
endif()

# 生成Protobuf源文件
set(PROTO_DIR "${CMAKE_SOURCE_DIR}/../../protos")
set(PROTO_SRC "${CMAKE_BINARY_DIR}/generated")
file(MAKE_DIRECTORY ${PROTO_SRC})

set(PROTO_FILE "${PROTO_DIR}/openclaw.proto")
set(PROTO_SRC_FILE "${PROTO_SRC}/openclaw.pb.cc")
set(PROTO_HDR_FILE "${PROTO_SRC}/openclaw.pb.h")

add_custom_command(
    OUTPUT ${PROTO_SRC_FILE} ${PROTO_HDR_FILE}
    COMMAND protobuf::protoc
    ARGS --cpp_out=${PROTO_SRC} -I${PROTO_DIR} ${PROTO_FILE}
    DEPENDS ${PROTO_FILE}
    COMMENT "Generating protobuf sources"
)

# 主库
add_library(polyvault_agent_lib
    src/agent.cpp
    src/credential_service.cpp
    src/crypto_utils.cpp
    ${PROTO_SRC_FILE}
)

target_include_directories(polyvault_agent_lib
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/include>
        $<BUILD_INTERFACE:${PROTO_SRC}>
    PRIVATE
        ${CMAKE_SOURCE_DIR}/src
)

target_link_libraries(polyvault_agent_lib
    PUBLIC
        protobuf::libprotobuf
)

if(USE_ECAL)
    target_link_libraries(polyvault_agent_lib PUBLIC eCAL::core)
endif()

# 主可执行文件
add_executable(polyvault_agent src/main.cpp)
target_link_libraries(polyvault_agent PRIVATE polyvault_agent_lib)

# 测试
if(BUILD_TESTS)
    enable_testing()
    add_subdirectory(tests)
endif()

# eCAL通信测试
if(USE_ECAL)
    add_executable(test_ecal_communication src/test_ecal_communication.cpp)
    target_link_libraries(test_ecal_communication PRIVATE polyvault_agent_lib)
    target_include_directories(test_ecal_communication PRIVATE ${CMAKE_SOURCE_DIR}/include)
endif()

# 安装规则
install(TARGETS polyvault_agent DESTINATION bin)
install(TARGETS polyvault_agent_lib DESTINATION lib)
install(DIRECTORY include/ DESTINATION include)