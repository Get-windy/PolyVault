// Protobuf Arena Header
#pragma once

namespace google {
namespace protobuf {

class Arena {
public:
    Arena() = default;
    ~Arena() = default;
    
    template<typename T>
    T* CreateMessage() { return new T(); }
    
    template<typename T>
    T* Create() { return new T(); }
    
    void Reset() {}
    size_t SpaceAllocated() const { return 0; }
    size_t SpaceUsed() const { return 0; }
};

} // namespace protobuf
} // namespace google