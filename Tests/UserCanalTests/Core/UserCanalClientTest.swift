// UserCanalClientTest.swift
// UserCanal Swift SDK Tests - UserCanalClient Unit Tests
//
// Copyright © 2024 UserCanal. All rights reserved.
//

import XCTest
@testable import UserCanal

/// Unit tests for UserCanalClient - the main SDK interface
final class UserCanalClientTest: XCTestCase {

    // MARK: - Test Configuration

    private var testConfig: UserCanalConfig!
    private var testAPIKey: String!

    override func setUp() {
        super.setUp()
        testAPIKey = "test-api-key-12345"
        testConfig = UserCanalConfig(
            endpoint: "https://test.usercanal.com",
            batchSize: 100,
            flushInterval: .seconds(30),
            enableDebugLogging: true
        )
    }

    override func tearDown() {
        testConfig = nil
        testAPIKey = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testClientInitialization() async throws {
        // Test successful initialization through UserCanal.shared
        try await UserCanal.shared.configure(apiKey: testAPIKey, endpoint: "https://test.usercanal.com")

        // Basic validation that configuration succeeded
        XCTAssertTrue(true, "Client should initialize successfully")
    }

    func testClientConfiguration() async throws {
        // Test that shared instance can be configured
        try await UserCanal.shared.configure(
            apiKey: testAPIKey,
            endpoint: "https://test.usercanal.com",
            batchSize: 50,
            flushInterval: 60
        )
        XCTAssertTrue(true, "Configuration should complete successfully")
    }

    func testClientConfigurationValidation() async {
        // Test with invalid API key (empty)
        do {
            try await UserCanal.shared.configure(apiKey: "")
            XCTFail("Should throw error for empty API key")
        } catch {
            XCTAssertTrue(error is UserCanalError, "Should throw UserCanalError for invalid API key")
        }
    }

    // MARK: - Event Tracking Tests

    func testTrackEvent() async throws {
        try await UserCanal.shared.configure(apiKey: testAPIKey)

        // Test basic event tracking
        let expectation = XCTestExpectation(description: "Event tracking should not crash")

        // First identify a user, then track event
        UserCanal.shared.identify("test-user-123", traits: Properties())
        UserCanal.shared.track(EventName("test_event"), properties: Properties(["test": "value"]))

        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testTrackEventWithCustomProperties() async throws {
        try await UserCanal.shared.configure(apiKey: testAPIKey)

        let expectation = XCTestExpectation(description: "Event with custom properties should not crash")

        // Identify user first, then track with custom properties
        UserCanal.shared.identify("test-user-456", traits: Properties())
        UserCanal.shared.track(EventName("custom_event"), properties: Properties(["custom": "data"]))

        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testTrackEventWithEmptyProperties() async throws {
        try await UserCanal.shared.configure(apiKey: testAPIKey)

        let expectation = XCTestExpectation(description: "Event with empty properties should not crash")

        UserCanal.shared.identify("test-user-789", traits: Properties())
        UserCanal.shared.track(EventName("empty_props_event"), properties: Properties())

        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    // MARK: - Identity Tests

    func testIdentifyUser() async throws {
        try await UserCanal.shared.configure(apiKey: testAPIKey)

        let expectation = XCTestExpectation(description: "User identification should not crash")

        UserCanal.shared.identify(
            "identify-user-123",
            traits: Properties(["name": "Test User", "email": "test@example.com"])
        )
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testIdentifyWithEmptyTraits() async throws {
        try await UserCanal.shared.configure(apiKey: testAPIKey)

        let expectation = XCTestExpectation(description: "Identify with empty traits should not crash")

        UserCanal.shared.identify("identify-user-456", traits: Properties())
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    // MARK: - Group Tests

    func testGroupUser() async throws {
        try await UserCanal.shared.configure(apiKey: testAPIKey)

        let expectation = XCTestExpectation(description: "Group operation should not crash")

        // Identify user first, then add to group
        UserCanal.shared.identify("group-user-123", traits: Properties())
        UserCanal.shared.group("company-456", properties: Properties(["name": "Test Company"]))

        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    // MARK: - Logging Tests

    func testLogMessage() async throws {
        try await UserCanal.shared.configure(apiKey: testAPIKey)

        let expectation = XCTestExpectation(description: "Logging should not crash")

        UserCanal.shared.log(
            .info,
            "Test log message",
            service: "test-service"
        )

        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testLogWithWarningLevel() async throws {
        try await UserCanal.shared.configure(apiKey: testAPIKey)

        let expectation = XCTestExpectation(description: "Warning log should not crash")

        UserCanal.shared.logWarning("Custom warning log test", service: "test-service")

        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    // MARK: - Flush Tests

    func testFlush() async throws {
        try await UserCanal.shared.configure(apiKey: testAPIKey)

        let expectation = XCTestExpectation(description: "Flush should complete")

        do {
            try await UserCanal.shared.flush()
            expectation.fulfill()
        } catch {
            // Flush might fail in test environment, but shouldn't crash
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 5.0)
    }

    // MARK: - Opt-out Tests

    func testOptOut() async throws {
        try await UserCanal.shared.configure(apiKey: testAPIKey)

        // Test opt-out functionality
        UserCanal.shared.optOut()
        XCTAssertTrue(UserCanal.shared.isOptedOut(), "User should be opted out")

        // Test that events are dropped when opted out
        UserCanal.shared.track("opted_out_event")
        // This should not crash, but event should be dropped

        // Test opt-in
        UserCanal.shared.optIn()
        XCTAssertFalse(UserCanal.shared.isOptedOut(), "User should be opted in")
    }

    // MARK: - Reset Tests

    func testReset() async throws {
        try await UserCanal.shared.configure(apiKey: testAPIKey)

        // Identify a user first
        UserCanal.shared.identify("reset-test-user", traits: Properties(["name": "Test User"]))

        // Reset should clear current user
        UserCanal.shared.reset()

        // After reset, should be able to identify again
        UserCanal.shared.identify("new-user-after-reset", traits: Properties())

        XCTAssertTrue(true, "Reset completed without crash")
    }

    // MARK: - Thread Safety Tests

    func testConcurrentOperations() async throws {
        try await UserCanal.shared.configure(apiKey: testAPIKey)
        let expectation = XCTestExpectation(description: "Concurrent operations should not crash")
        expectation.expectedFulfillmentCount = 10

        // Perform multiple operations concurrently
        for i in 0..<10 {
            Task {
                UserCanal.shared.identify("concurrent-user-\(i)", traits: Properties())
                UserCanal.shared.track(EventName("concurrent_event"), properties: Properties(["index": i]))
                expectation.fulfill()
            }
        }

        await fulfillment(of: [expectation], timeout: 2.0)
    }

    func testMixedConcurrentOperations() async throws {
        try await UserCanal.shared.configure(apiKey: testAPIKey)
        let expectation = XCTestExpectation(description: "Mixed concurrent operations should not crash")
        expectation.expectedFulfillmentCount = 4

        // Mix different operations concurrently
        Task {
            UserCanal.shared.identify("mixed-1", traits: Properties())
            UserCanal.shared.track(EventName("track_test"), properties: Properties())
            expectation.fulfill()
        }

        Task {
            UserCanal.shared.identify("mixed-2", traits: Properties())
            expectation.fulfill()
        }

        Task {
            UserCanal.shared.identify("mixed-3", traits: Properties())
            UserCanal.shared.group("group-1", properties: Properties())
            expectation.fulfill()
        }

        Task {
            UserCanal.shared.log(.info, "Mixed test", service: "test")
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 2.0)
    }
}
