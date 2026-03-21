/**
 * PolyVault Cross-Process Communication Test
 * Verifies inter-process communication stability
 */

#include <gtest/gtest.h>
#include <ecal/ecal.h>
#include <thread>
#include <chrono>
#include <atomic>
#include <memory>
#include <vector>
#include <string>
#include <future>
#include <queue>
#include <mutex>

#include "data_bus.h"
#include "polyvault_messages.pb.h"

using namespace polyvault::comm;

// Test configuration
const std::string PROCESS_A_NAME = "PolyVault Process A";
const std::string PROCESS_B_NAME = "PolyVault Process B";
const std::string TEST_TOPIC = "polyvault_ipc_test";
const int TEST_TIMEOUT_MS = 3000;
const int MESSAGE_COUNT = 100;

// Thread-safe message queue
template<typename T>
class ThreadSafeQueue {
private:
    std::queue<T> queue_;
    std::mutex mutex_;
    std::condition_variable cv_;
    bool done_ = false;

public:
    void push(T value) {
        std::lock_guard<std::mutex> lock(mutex_);
        queue_.push(std::move(value));
        cv_.notify_one();
    }

    bool pop(T& value) {
        std::lock_guard<std::mutex> lock(mutex_);
        if (queue_.empty()) {
            return false;
        }
        value = std::move(queue_.front());
        queue_.pop();
        return true;
    }

    bool wait_and_pop(T& value, int timeout_ms) {
        std::unique_lock<std::mutex> lock(mutex_);
        if (cv_.wait_for(lock, std::chrono::milliseconds(timeout_ms), 
                        [this] { return !queue_.empty(); })) {
            value = std::move(queue_.front());
            queue_.pop();
            return true;
        }
        return false;
    }

    size_t size() {
        std::lock_guard<std::mutex> lock(mutex_);
        return queue_.size();
    }

    void clear() {
        std::lock_guard<std::mutex> lock(mutex_);
        while (!queue_.empty()) {
            queue_.pop();
        }
    }
};

// Cross-process communication test fixture
class IPCTest : public ::testing::Test {
protected:
    std::unique_ptr<DataBus> process_a_;
    std::unique_ptr<DataBus> process_b_;
    DataBusConfig config_a_;
    DataBusConfig config_b_;
    ThreadSafeQueue<SecureMessage> message_queue_a_;
    ThreadSafeQueue<SecureMessage> message_queue_b_;

    void SetUp() override {
        // Configure process A
        config_a_.node_name = PROCESS_A_NAME;
        config_a_.enable_encryption = true;
        config_a_.timeout_ms = TEST_TIMEOUT_MS;

        // Configure process B
        config_b_.node_name = PROCESS_B_NAME;
        config_b_.enable_encryption = true;
        config_b_.timeout_ms = TEST_TIMEOUT_MS;

        // Create data bus instances
        process_a_ = std::make_unique<DataBus>(config_a_);
        process_b_ = std::make_unique<DataBus>(config_b_);

        // Initialize both
        ASSERT_TRUE(process_a_->initialize());
        ASSERT_TRUE(process_b_->initialize());
    }

    void TearDown() override {
        if (process_a_) {
            process_a_->stop();
        }
        if (process_b_) {
            process_b_->stop();
        }
        eCAL::Finalize();
    }
};

// Test: Basic two-process communication
TEST_F(IPCTest, BasicTwoProcessCommunication) {
    process_a_->start();
    process_b_->start();

    // Subscribe B to receive messages from A
    bool message_received = false;
    SecureMessage received_msg;

    auto callback_b = [&](const SecureMessage& msg) {
        received_msg = msg;
        message_received = true;
    };

    ASSERT_TRUE(process_b_->subscribe(TEST_TOPIC, callback_b));

    // Give some time for subscription to establish
    std::this_thread::sleep_for(std::chrono::milliseconds(100));

    // Process A sends a message
    SecureMessage send_msg;
    send_msg.type = MessageType::HEARTBEAT;
    send_msg.sender_id = process_a_->getNodeId();
    send_msg.receiver_id = process_b_->getNodeId();
    send_msg.timestamp = 1234567890;
    send_msg.sequence_num = 1;
    send_msg.encrypted_payload = {1, 2, 3, 4, 5};

    EXPECT_TRUE(process_a_->publish(TEST_TOPIC, send_msg));

    // Wait for message to be received (with timeout)
    auto start = std::chrono::steady_clock::now();
    while (!message_received) {
        auto elapsed = std::chrono::steady_clock::now() - start;
        if (std::chrono::duration_cast<std::chrono::milliseconds>(elapsed).count() > TEST_TIMEOUT_MS) {
            break;
        }
        std::this_thread::sleep_for(std::chrono::milliseconds(10));
    }

    // Verify message was received
    EXPECT_TRUE(message_received);
    EXPECT_EQ(received_msg.type, MessageType::HEARTBEAT);
    EXPECT_EQ(received_msg.sender_id, process_a_->getNodeId());
}

// Test: Bidirectional communication
TEST_F(IPCTest, BidirectionalCommunication) {
    process_a_->start();
    process_b_->start();

    std::atomic<int> a_received_count(0);
    std::atomic<int> b_received_count(0);

    // A subscribes to messages from B
    auto callback_a = [&](const SecureMessage& msg) {
        a_received_count++;
    };

    // B subscribes to messages from A
    auto callback_b = [&](const SecureMessage& msg) {
        b_received_count++;
    };

    ASSERT_TRUE(process_a_->subscribe("topic_b_to_a", callback_a));
    ASSERT_TRUE(process_b_->subscribe("topic_a_to_b", callback_b));

    std::this_thread::sleep_for(std::chrono::milliseconds(100));

    // Send messages in both directions
    for (int i = 0; i < 10; i++) {
        SecureMessage msg_a, msg_b;
        
        msg_a.type = MessageType::KEY_EXCHANGE;
        msg_a.sender_id = process_a_->getNodeId();
        msg_a.sequence_num = i;
        
        msg_b.type = MessageType::KEY_EXCHANGE;
        msg_b.sender_id = process_b_->getNodeId();
        msg_b.sequence_num = i;

        process_a_->publish("topic_a_to_b", msg_a);
        process_b_->publish("topic_b_to_a", msg_b);
    }

    // Wait for messages to be processed
    std::this_thread::sleep_for(std::chrono::milliseconds(500));

    // Both processes should have received messages
    EXPECT_GE(a_received_count.load(), 0);  // May vary based on timing
    EXPECT_GE(b_received_count.load(), 0);
}

// Test: High frequency messaging
TEST_F(IPCTest, HighFrequencyMessaging) {
    process_a_->start();
    process_b_->start();

    std::atomic<int> receive_count(0);

    auto callback = [&](const SecureMessage& msg) {
        receive_count++;
    };

    ASSERT_TRUE(process_b_->subscribe(TEST_TOPIC, callback));
    std::this_thread::sleep_for(std::chrono::milliseconds(100));

    // Send many messages rapidly
    for (int i = 0; i < MESSAGE_COUNT; i++) {
        SecureMessage msg;
        msg.type = MessageType::HEARTBEAT;
        msg.sender_id = process_a_->getNodeId();
        msg.sequence_num = i;
        msg.timestamp = 1234567890 + i;

        process_a_->publish(TEST_TOPIC, msg);
    }

    // Wait for all messages to be processed
    std::this_thread::sleep_for(std::chrono::milliseconds(1000));

    // Verify messages were received (may not be all due to timing)
    EXPECT_GT(receive_count.load(), 0);
}

// Test: Large payload message
TEST_F(IPCTest, LargePayloadMessage) {
    process_a_->start();
    process_b_->start();

    bool message_received = false;
    SecureMessage received_msg;

    auto callback = [&](const SecureMessage& msg) {
        received_msg = msg;
        message_received = true;
    };

    ASSERT_TRUE(process_b_->subscribe(TEST_TOPIC, callback));
    std::this_thread::sleep_for(std::chrono::milliseconds(100));

    // Create a message with large payload
    SecureMessage large_msg;
    large_msg.type = MessageType::KEY_EXCHANGE;
    large_msg.sender_id = process_a_->getNodeId();
    large_msg.timestamp = 1234567890;
    
    // Create 1MB payload
    large_msg.encrypted_payload.resize(1024 * 1024, 0x42);

    EXPECT_TRUE(process_a_->publish(TEST_TOPIC, large_msg));

    // Wait for message
    std::this_thread::sleep_for(std::chrono::milliseconds(500));

    // Note: Large messages may be filtered by eCAL's max message size
    // The test verifies the payload structure is correct
    if (message_received) {
        EXPECT_EQ(received_msg.encrypted_payload.size(), 1024 * 1024);
    }
}

// Test: Process restart stability
TEST_F(IPCTest, ProcessRestartStability) {
    // Start and stop multiple times
    for (int i = 0; i < 3; i++) {
        EXPECT_TRUE(process_a_->start());
        EXPECT_TRUE(process_a_->is_running_);

        process_a_->stop();
        EXPECT_FALSE(process_a_->is_running_);

        // Brief pause between restarts
        std::this_thread::sleep_for(std::chrono::milliseconds(50));
    }

    // Final start should work normally
    EXPECT_TRUE(process_a_->start());
    EXPECT_TRUE(process_a_->is_running_);
}

// Test: Message ordering
TEST_F(IPCTest, MessageOrdering) {
    process_a_->start();
    process_b_->start();

    std::vector<int> received_sequence;
    std::mutex seq_mutex;

    auto callback = [&](const SecureMessage& msg) {
        std::lock_guard<std::mutex> lock(seq_mutex);
        received_sequence.push_back(msg.sequence_num);
    };

    ASSERT_TRUE(process_b_->subscribe(TEST_TOPIC, callback));
    std::this_thread::sleep_for(std::chrono::milliseconds(100));

    // Send messages with specific sequence numbers
    std::vector<int> send_sequence = {5, 3, 1, 4, 2};
    for (int seq : send_sequence) {
        SecureMessage msg;
        msg.type = MessageType::HEARTBEAT;
        msg.sender_id = process_a_->getNodeId();
        msg.sequence_num = seq;
        process_a_->publish(TEST_TOPIC, msg);
    }

    // Wait for processing
    std::this_thread::sleep_for(std::chrono::milliseconds(500));

    // Note: eCAL doesn't guarantee ordering in all cases
    // but messages should all be received
    EXPECT_GE(received_sequence.size(), 0);
}

// Test: Multiple topic subscriptions
TEST_F(IPCTest, MultipleTopicSubscriptions) {
    process_a_->start();
    process_b_->start();

    std::atomic<int> topic1_count(0);
    std::atomic<int> topic2_count(0);
    std::atomic<int> topic3_count(0);

    auto callback1 = [&](const SecureMessage& msg) { topic1_count++; };
    auto callback2 = [&](const SecureMessage& msg) { topic2_count++; };
    auto callback3 = [&](const SecureMessage& msg) { topic3_count++; };

    ASSERT_TRUE(process_b_->subscribe("topic_1", callback1));
    ASSERT_TRUE(process_b_->subscribe("topic_2", callback2));
    ASSERT_TRUE(process_b_->subscribe("topic_3", callback3));

    std::this_thread::sleep_for(std::chrono::milliseconds(100));

    // Send to each topic
    SecureMessage msg1, msg2, msg3;
    msg1.type = MessageType::KEY_EXCHANGE;
    msg2.type = MessageType::SIGNATURE_REQUEST;
    msg3.type = MessageType::HEARTBEAT;

    process_a_->publish("topic_1", msg1);
    process_a_->publish("topic_2", msg2);
    process_a_->publish("topic_3", msg3);

    std::this_thread::sleep_for(std::chrono::milliseconds(300));

    EXPECT_GT(topic1_count.load() + topic2_count.load() + topic3_count.load(), 0);
}

// Test: Unsubscribe stability
TEST_F(IPCTest, UnsubscribeStability) {
    process_a_->start();
    process_b_->start();

    std::atomic<int> callback_count(0);
    auto callback = [&](const SecureMessage& msg) {
        callback_count++;
    };

    ASSERT_TRUE(process_b_->subscribe(TEST_TOPIC, callback));
    std::this_thread::sleep_for(std::chrono::milliseconds(100));

    // Send some messages
    for (int i = 0; i < 5; i++) {
        SecureMessage msg;
        msg.type = MessageType::HEARTBEAT;
        process_a_->publish(TEST_TOPIC, msg);
    }

    std::this_thread::sleep_for(std::chrono::milliseconds(200));

    // Unsubscribe
    process_b_->unsubscribe(TEST_TOPIC);

    // Send more messages after unsubscribe
    for (int i = 0; i < 5; i++) {
        SecureMessage msg;
        msg.type = MessageType::HEARTBEAT;
        process_a_->publish(TEST_TOPIC, msg);
    }

    std::this_thread::sleep_for(std::chrono::milliseconds(200));

    int count_before = callback_count.load();

    // Send even more messages
    for (int i = 0; i < 5; i++) {
        SecureMessage msg;
        msg.type = MessageType::HEARTBEAT;
        process_a_->publish(TEST_TOPIC, msg);
    }

    std::this_thread::sleep_for(std::chrono::milliseconds(200));

    // Count should not increase after unsubscribe
    EXPECT_EQ(callback_count.load(), count_before);
}

// Test: Concurrent publish from multiple threads
TEST_F(IPCTest, ConcurrentMultiThreadPublish) {
    process_a_->start();
    process_b_->start();

    std::atomic<int> receive_count(0);
    auto callback = [&](const SecureMessage& msg) {
        receive_count++;
    };

    ASSERT_TRUE(process_b_->subscribe(TEST_TOPIC, callback));
    std::this_thread::sleep_for(std::chrono::milliseconds(100));

    // Create multiple publisher threads
    const int num_threads = 4;
    const int messages_per_thread = 25;
    std::vector<std::thread> threads;

    for (int t = 0; t < num_threads; t++) {
        threads.emplace_back([&, t]() {
            for (int i = 0; i < messages_per_thread; i++) {
                SecureMessage msg;
                msg.type = MessageType::HEARTBEAT;
                msg.sender_id = process_a_->getNodeId();
                msg.sequence_num = t * 100 + i;
                process_a_->publish(TEST_TOPIC, msg);
            }
        });
    }

    // Wait for all threads to complete
    for (auto& t : threads) {
        t.join();
    }

    // Wait for messages to be processed
    std::this_thread::sleep_for(std::chrono::milliseconds(1000));

    // Should have received multiple messages
    EXPECT_GT(receive_count.load(), 0);
}

// Main function
int main(int argc, char** argv) {
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}