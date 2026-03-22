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
        src/plugin_manager.cpp
        src/permission_manager.cpp
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
        target_link_libraries(polyvault_simple_lib PUBLIC ws2_32 bcrypt)
        if(MSVC)
            target_compile_options(polyvault_simple_lib PRIVATE /W3 /wd4819)
        endif()
    endif()
    
    if(USE_ECAL)
        target_link_libraries(polyvault_simple_lib PUBLIC eCAL::core)
    endif()
    
    # 简化版可执行文�?
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

# ============ 数据总线 (需要eCAL) ============
if(USE_ECAL)
    add_library(polyvault_data_bus STATIC
        src/data_bus.cpp
    )
    
    target_include_directories(polyvault_data_bus
        PUBLIC
            $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/include>
            $<BUILD_INTERFACE:${PROTO_SRC}>
        PRIVATE
            ${CMAKE_SOURCE_DIR}/src
    )
    
    if(WIN32)
        target_compile_definitions(polyvault_data_bus PRIVATE _WIN32_WINNT=0x0601)
        target_link_libraries(polyvault_data_bus PUBLIC ws2_32)
    endif()
    
    target_link_libraries(polyvault_data_bus PUBLIC eCAL::core)
    
    message(STATUS "Data Bus library enabled")
endif()

# ============ 安全模块�?============
# 零知识凭证存�?
add_library(polyvault_zk_vault STATIC
    src/zk_vault.cpp
)

target_include_directories(polyvault_zk_vault
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/include>
    PRIVATE
        ${CMAKE_SOURCE_DIR}/src
)

if(WIN32)
    target_compile_definitions(polyvault_zk_vault PRIVATE _WIN32_WINNT=0x0601)
    target_link_libraries(polyvault_zk_vault PUBLIC ws2_32 bcrypt)
endif()

# 链接 crypto_utils (依赖 polyvault_simple_lib)
target_link_libraries(polyvault_zk_vault PUBLIC polyvault_simple_lib)

# 密钥管理
add_library(polyvault_key_manager STATIC
    src/key_manager.cpp
)

target_include_directories(polyvault_key_manager
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/include>
    PRIVATE
        ${CMAKE_SOURCE_DIR}/src
)

target_link_libraries(polyvault_key_manager PRIVATE polyvault_zk_vault)

if(WIN32)
    target_compile_definitions(polyvault_key_manager PRIVATE _WIN32_WINNT=0x0601)
endif()

# 签名验证
add_library(polyvault_signature STATIC
    src/signature.cpp
)

target_include_directories(polyvault_signature
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/include>
    PRIVATE
        ${CMAKE_SOURCE_DIR}/src
)

target_link_libraries(polyvault_signature PRIVATE polyvault_key_manager)

if(WIN32)
    target_compile_definitions(polyvault_signature PRIVATE _WIN32_WINNT=0x0601)
endif()

# 审计日志
add_library(polyvault_audit_logger STATIC
    src/audit_logger.cpp
)

target_include_directories(polyvault_audit_logger
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/include>
    PRIVATE
        ${CMAKE_SOURCE_DIR}/src
)

target_link_libraries(polyvault_audit_logger PRIVATE polyvault_signature)

# 性能监控 (暂时禁用 - 需要进一步调�?
# add_library(polyvault_perf_monitor STATIC
#     src/perf_monitor.cpp
# )
# 
# target_include_directories(polyvault_perf_monitor
#     PUBLIC
#         $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/include>
#     PRIVATE
#         ${CMAKE_SOURCE_DIR}/src
# )

# 数据同步 (内部总线)
add_library(polyvault_data_sync STATIC
    src/data_sync.cpp
)

target_include_directories(polyvault_data_sync
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/include>
    PRIVATE
        ${CMAKE_SOURCE_DIR}/src
)

target_link_libraries(polyvault_data_sync PRIVATE polyvault_simple_lib)

# REST服务�?
add_library(polyvault_rest_server STATIC
    src/rest_server.cpp
)

target_include_directories(polyvault_rest_server
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/include>
    PRIVATE
        ${CMAKE_SOURCE_DIR}/src
)

target_link_libraries(polyvault_rest_server PRIVATE polyvault_key_manager polyvault_signature)

message(STATUS "Security modules enabled")

# ============ 测试 ============
if(BUILD_TESTS)
    # eCAL通信测试
    if(USE_ECAL)
        add_executable(test_ecal_communication src/test_ecal_communication.cpp)
        target_link_libraries(test_ecal_communication PRIVATE polyvault_simple_lib)
    endif()
    
    # 数据总线测试
    if(USE_ECAL)
        add_executable(test_data_bus src/test_data_bus.cpp)
        target_link_libraries(test_data_bus PRIVATE polyvault_data_bus polyvault_simple_lib)
        target_compile_definitions(test_data_bus PRIVATE USE_ECAL)
        
        # eCAL集成测试
        add_executable(test_ecal_integration 
            src/test_ecal_integration.cpp
            src/data_bus.cpp
        )
        target_link_libraries(test_ecal_integration 
            PRIVATE 
                polyvault_simple_lib 
                eCAL::core
        )
        target_compile_definitions(test_ecal_integration PRIVATE USE_ECAL)
    endif()
    
    # 性能基准测试
    add_executable(perf_benchmark 
        src/perf_benchmark.cpp
        src/zk_vault.cpp
        src/key_manager.cpp
        src/signature.cpp
        src/audit_logger.cpp
        # src/perf_monitor.cpp  # 暂时禁用
        src/data_sync.cpp
    )
    
    target_link_libraries(perf_benchmark 
        PRIVATE 
            polyvault_simple_lib
            polyvault_zk_vault
            polyvault_key_manager
            polyvault_signature
            polyvault_audit_logger
            # polyvault_perf_monitor  # 暂时禁用
            polyvault_data_sync
    )
    
    target_include_directories(perf_benchmark
        PRIVATE
            ${CMAKE_SOURCE_DIR}/src
    )
    
    # Protobuf 序列化测试
    if(EXISTS "${PROTO_SRC_FILE}")
        add_executable(test_protobuf_serialization 
            ../../tests/test_protobuf_serialization.cpp
            ${PROTO_SRC_FILE}
        )
        
        target_link_libraries(test_protobuf_serialization 
            PRIVATE 
                polyvault_simple_lib
        )
        
        target_include_directories(test_protobuf_serialization
            PRIVATE
                ${CMAKE_SOURCE_DIR}/generated
                ${CMAKE_SOURCE_DIR}/src
        )
        
        message(STATUS "Protobuf serialization test enabled")
    endif()
    
    message(STATUS "Tests enabled (including perf_benchmark)")
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