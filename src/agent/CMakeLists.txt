cmake_minimum_required(VERSION 3.16)
project(polyvault_agent VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# 选项
option(USE_ECAL "Enable eCAL support" OFF)
option(BUILD_TESTS "Build tests" OFF)
option(BUILD_SIMPLE "Build simple agent (no protobuf)" ON)

# eCAL支持
if(USE_ECAL)
    find_package(eCAL REQUIRED)
    add_definitions(-DUSE_ECAL)
    message(STATUS "eCAL support enabled")
else()
    message(STATUS "eCAL support disabled")
endif()

# ============ 简化版Agent (无Protobuf依赖) ============
if(BUILD_SIMPLE)
    add_library(polyvault_simple_lib STATIC
        src/simple_agent.cpp
        src/crypto_utils.cpp
    )
    
    target_include_directories(polyvault_simple_lib
        PUBLIC
            $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/include>
        PRIVATE
            ${CMAKE_SOURCE_DIR}/src
    )
    
    if(WIN32)
        target_compile_definitions(polyvault_simple_lib PRIVATE 
            _WIN32_WINNT=0x0601
            WIN32_LEAN_AND_MEAN
        )
        target_link_libraries(polyvault_simple_lib PUBLIC ws2_32)
        if(MSVC)
            target_compile_options(polyvault_simple_lib PRIVATE /W3 /wd4819)
        endif()
    endif()
    
    if(USE_ECAL)
        target_link_libraries(polyvault_simple_lib PUBLIC eCAL::core)
    endif()
    
    # 简化版可执行文件
    add_executable(polyvault_agent_simple src/simple_main.cpp)
    target_link_libraries(polyvault_agent_simple PRIVATE polyvault_simple_lib)
    
    message(STATUS "Simple agent enabled")
endif()

# ============ 完整版Agent (需要Protobuf) ============
if(NOT BUILD_SIMPLE)
    set(PROTO_SRC "${CMAKE_SOURCE_DIR}/generated")
    set(PROTO_SRC_FILE "${PROTO_SRC}/openclaw.pb.cc")
    
    if(EXISTS ${PROTO_SRC_FILE})
        message(STATUS "Using pre-generated protobuf files")
        
        add_library(polyvault_agent_lib STATIC
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
        
        if(WIN32)
            target_compile_definitions(polyvault_agent_lib PRIVATE _WIN32_WINNT=0x0601)
            target_link_libraries(polyvault_agent_lib PUBLIC ws2_32)
        endif()
        
        if(USE_ECAL)
            target_link_libraries(polyvault_agent_lib PUBLIC eCAL::core)
        endif()
        
        add_executable(polyvault_agent src/main.cpp)
        target_link_libraries(polyvault_agent PRIVATE polyvault_agent_lib)
    else()
        message(WARNING "Protobuf files not found, only simple agent available")
    endif()
endif()

# ============ 测试 ============
if(BUILD_TESTS AND USE_ECAL)
    add_executable(test_ecal_communication src/test_ecal_communication.cpp)
    target_link_libraries(test_ecal_communication PRIVATE polyvault_simple_lib)
endif()

# ============ 安装 ============
if(BUILD_SIMPLE)
    install(TARGETS polyvault_agent_simple DESTINATION bin)
endif()

# ============ 摘要 ============
message(STATUS "")
message(STATUS "========================================")
message(STATUS "PolyVault Agent Configuration:")
message(STATUS "  Version: ${PROJECT_VERSION}")
message(STATUS "  USE_ECAL: ${USE_ECAL}")
message(STATUS "  BUILD_SIMPLE: ${BUILD_SIMPLE}")
message(STATUS "  BUILD_TESTS: ${BUILD_TESTS}")
message(STATUS "========================================")
message(STATUS "")