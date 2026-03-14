// Protobuf Runtime Version Header
#pragma once

#define GOOGLE_PROTOBUF_RUNTIME_VERSION 5010000

namespace google {
namespace protobuf {
namespace internal {

inline int ProtobufRuntimeVersion() {
    return GOOGLE_PROTOBUF_RUNTIME_VERSION;
}

} // namespace internal
} // namespace protobuf
} // namespace google