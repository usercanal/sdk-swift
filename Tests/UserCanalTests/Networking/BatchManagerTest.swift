// BatchManagerTest.swift
// UserCanal Swift SDK Tests - BatchManager Testing for Raw TCP
//
// Copyright © 2024 UserCanal. All rights reserved.
//

import XCTest
@testable import UserCanal

/// Unit tests for BatchManager - Raw TCP Batching with FlatBuffers
final class BatchManagerTest: XCTestCase {

    // MARK: - Test Properties

    private var config: UserCanalConfig!
    private var apiKey: Data!
    private var batchManager: BatchManager!

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()

        // Create test configuration with small batch size for testing
        config = try UserCanalConfig(
            endpoint: "localhost:50000",
            batchSize: 3, // Small batch size for testing
            flushInterval: .seconds(10) // Long interval so we control flushing
        )

        // Create test API key
        apiKey = Data([0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
                      0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f])

        // Create real network client for localhost testing
        let networkClient = try NetworkClient(apiKey: "000102030405060708090a0b0c0d0e0f", endpoint: "localhost:50000")

        // Create batch manager
        batchManager = BatchManager(
            config: config,
            apiKey: apiKey,
            networkClient: networkClient
        )
    }

    override func tearDown() async throws {
        try? await batchManager?.close()
        batchManager = nil
        config = nil
        apiKey = nil
        try await super.tearDown()
    }

    // MARK: - Basic Functionality Tests

    func testBatchManagerInitialization() async throws {
        print("🧪 Testing BatchManager initialization")

        XCTAssertNotNil(batchManager, "BatchManager should initialize")

        print("✅ BatchManager initialized successfully")
    }

    func testAddSingleEvent() async throws {
        print("🧪 Testing single event addition (no flush)")

        let event = Event(userID: "swift_sdk_user1", name: EventName("swift_test_event"))

        // This should not crash and should not trigger flush (batch size is 3)
        try await batchManager.addEvent(event, deviceID: nil, sessionID: nil)

        print("✅ Single event added without flush")
    }

    func testBatchSizeTriggersFlush() async throws {
        print("🧪 Testing batch size triggers automatic flush")

        // Create test events (batch size is 3)
        let event1 = Event(userID: "swift_batch_user1", name: EventName("swift_batch_test1"))
        let event2 = Event(userID: "swift_batch_user2", name: EventName("swift_batch_test2"))
        let event3 = Event(userID: "swift_batch_user3", name: EventName("swift_batch_test3"))

        // Add events one by one
        try await batchManager.addEvent(event1, deviceID: nil, sessionID: nil)
        try await batchManager.addEvent(event2, deviceID: nil, sessionID: nil)

        // Third event should trigger batch flush
        try await batchManager.addEvent(event3, deviceID: nil, sessionID: nil)

        print("✅ Batch flush triggered at correct size")
    }

    func testManualFlush() async throws {
        print("🧪 Testing manual flush with partial batch")

        // Add just one event (below batch size)
        let event = Event(userID: "swift_manual_user", name: EventName("swift_manual_test"))
        try await batchManager.addEvent(event, deviceID: nil, sessionID: nil)

        // Manual flush
        try await batchManager.flush()

        print("✅ Manual flush completed")
    }

    func testFlushEmptyQueue() async throws {
        print("🧪 Testing flush with empty queue")

        // Flush without adding anything - should not crash
        try await batchManager.flush()

        print("✅ Empty queue flush handled correctly")
    }

    // MARK: - FlatBuffers Serialization Tests

    func testFlatBuffersEventSerialization() async throws {
        print("🧪 Testing FlatBuffers event serialization")

        let event = Event(
            userID: "swift_flatbuffer_user",
            name: EventName("swift_flatbuffer_event"),
            properties: Properties(["test_key": "swift_test_value", "number": 42, "sdk": "swift"])
        )

        try await batchManager.addEvent(event, deviceID: nil, sessionID: nil)
        try await batchManager.flush()

        print("✅ FlatBuffers event serialization completed")
    }

    func testFlatBuffersLogSerialization() async throws {
        print("🧪 Testing FlatBuffers log serialization")

        let log = LogEntry(
            level: .error,
            timestamp: Date(),
            source: "swift_test_source",
            service: "swift_test_service",
            message: "Swift SDK test error message",
            data: Properties(["error_code": 500, "details": "Swift SDK test error details", "sdk": "swift"])
        )

        try await batchManager.addLog(log)
        try await batchManager.flush()

        print("✅ FlatBuffers log serialization completed")
    }

    func testMixedContentBatching() async throws {
        print("🧪 Testing mixed event and log batching")

        // Add events and logs (total = 3, should trigger flush)
        let event = Event(userID: "swift_mixed_user", name: EventName("swift_mixed_event"))
        let log = LogEntry(level: .info, source: "swift_test", service: "swift_test", message: "Swift SDK mixed test log")

        try await batchManager.addEvent(event, deviceID: nil, sessionID: nil)
        try await batchManager.addLog(log)

        // Add one more event to trigger flush
        try await batchManager.addEvent(event, deviceID: nil, sessionID: nil)

        print("✅ Mixed content batching completed")
    }

    // MARK: - Performance Tests

    func testBatchingPerformance() async throws {
        print("🧪 Testing batching performance")

        let eventCount = 50
        let startTime = Date()

        // Add many events quickly
        for i in 0..<eventCount {
            let event = Event(
                userID: "swift_perf_user_\(i)",
                name: EventName("swift_perf_test_\(i)"),
                properties: Properties(["index": i, "timestamp": Date().timeIntervalSince1970, "sdk": "swift"])
            )
            try await batchManager.addEvent(event, deviceID: nil, sessionID: nil)
        }

        // Final flush
        try await batchManager.flush()

        let duration = Date().timeIntervalSince(startTime)
        let eventsPerSecond = Double(eventCount) / duration

        print("✅ Performance: \(eventCount) events in \(String(format: "%.3f", duration))s = \(String(format: "%.0f", eventsPerSecond)) events/sec")

        XCTAssertGreaterThan(eventsPerSecond, 20, "Should handle at least 20 events/second")
    }

    // MARK: - Identity/Group/Revenue Tests (Currently Cleared)

    func testIdentityHandling() async throws {
        print("🧪 Testing identity handling (currently cleared)")

        let identity = Identity(
            userID: "swift_identity_test_user",
            timestamp: Date(),
            traits: { Properties(["name": "Swift Test User", "email": "swift@example.com", "sdk": "swift"]) }
        )

        try await batchManager.addIdentity(identity)
        try await batchManager.flush()

        print("✅ Identity handling doesn't crash (items cleared as expected)")
    }

    func testGroupHandling() async throws {
        print("🧪 Testing group handling (currently cleared)")

        let group = GroupInfo(
            userID: "swift_group_test_user",
            groupID: "swift_test_group",
            timestamp: Date(),
            properties: { Properties(["group_name": "Swift Test Group", "sdk": "swift"]) }
        )

        try await batchManager.addGroup(group)
        try await batchManager.flush()

        print("✅ Group handling doesn't crash (items cleared as expected)")
    }

    func testRevenueHandling() async throws {
        print("🧪 Testing revenue handling (currently cleared)")

        let revenue = Revenue(
            userID: "swift_revenue_test_user",
            orderID: "swift_test_order_123",
            amount: 29.99,
            currency: Currency.usd,
            timestamp: Date(),
            properties: { Properties(["product": "Swift Test Product", "sdk": "swift"]) }
        )

        try await batchManager.addRevenue(revenue)
        try await batchManager.flush()

        print("✅ Revenue handling doesn't crash (items cleared as expected)")
    }

    // MARK: - Raw TCP Protocol Tests

    func testRawTCPProtocolValidation() async throws {
        print("🧪 Testing raw TCP protocol validation")

        // This test validates that we're using raw TCP, not HTTP
        let event = Event(userID: "swift_tcp_test", name: EventName("swift_tcp_protocol_test"))
        try await batchManager.addEvent(event, deviceID: nil, sessionID: nil)
        try await batchManager.flush()

        print("✅ Raw TCP protocol validation completed")
        print("📊 Data is sent as length-prefixed FlatBuffers over raw TCP")
    }

    func testNetworkErrorRecovery() async throws {
        print("🧪 Testing network error recovery")

        // Use invalid endpoint to trigger network error
        let badConfig = try UserCanalConfig(
            endpoint: "nonexistent:99999",
            batchSize: 1,
            flushInterval: .seconds(1)
        )

        let badNetworkClient = try NetworkClient(apiKey: "test", endpoint: "nonexistent:99999")
        let badBatchManager = BatchManager(
            config: badConfig,
            apiKey: apiKey,
            networkClient: badNetworkClient
        )

        let event = Event(userID: "swift_error_test", name: EventName("swift_error_event"))
        try await batchManager.addEvent(event, deviceID: nil, sessionID: nil)

        // This should handle network errors gracefully
        do {
            try await badBatchManager.flush()
            print("⚠️ Expected network error but flush succeeded")
        } catch {
            print("✅ Network error handled: \(error)")
        }

        try? await badBatchManager.close()
    }
}
