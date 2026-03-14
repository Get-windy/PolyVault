// Protobuf Port Header
#pragma once

#include <cstdint>

// Platform-specific definitions
#if defined(_WIN32) || defined(_WIN64)
    #define PROTOBUF_EXPORT __declspec(dllexport)
    #define PROTOBUF_EXPORT_TEMPLATE_DECLARE
#else
    #define PROTOBUF_EXPORT
    #define PROTOBUF_EXPORT_TEMPLATE_DECLARE
#endif

// Version info
#define GOOGLE_PROTOBUF_VERSION 5010000
#define PROTOBUF_VERSION_STRING "5.21.0"