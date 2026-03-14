// Protobuf Generated Message Bases
#pragma once

#include "message.h"
#include "arena.h"

namespace google {
namespace protobuf {
namespace internal {

class MessageLite;
class Message;

// Base class for generated messages
class GeneratedMessageBase : public Message {
public:
    GeneratedMessageBase() = default;
    virtual ~GeneratedMessageBase() = default;
};

// Helper for zero-init fields
template<typename T>
struct DefaultOneofInstance {
    static const T value;
};

} // namespace internal
} // namespace protobuf
} // namespace google