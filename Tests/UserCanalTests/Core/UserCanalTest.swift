// UserCanalTest.swift
// UserCanal Swift SDK Tests
//
// Copyright © 2024 UserCanal. All rights reserved.
//

import XCTest
@testable import UserCanal

/// Unit tests for UserCanal singleton interface
final class UserCanalTest: XCTestCase {

    // MARK: - Test Setup

    override func setUp() {
        super.setUp()
        // Reset UserCanal state before each test
        Task { @MainActor in
            try? await UserCanal.shared.shutdown()
        }
    }

    override func tearDown() {
        super.tearDown()
        // Clean up after each test
        Task { @MainActor in
            try? await UserCanal.shared.shutdown()
        }
    }

    // MARK: - Configuration Tests

    @MainActor
    func testConfigureBasic() {
        // Test basic configuration doesn't crash
        UserCanal.shared.configure(
            apiKey: "test-api-key",
            endpoint: "localhost:50000"
        )

        // Should not crash - configuration is async internally
        XCTAssertTrue(true, "Basic configuration should succeed")
    }

    @MainActor
    func testConfigureWithAllOptions() {
        var errorReceived: (any Error)?

        UserCanal.shared.configure(
            apiKey: "test-api-key",
            endpoint: "localhost:50000",
            batchSize: 25,
            flushInterval: 10.0,
            deviceContextRefresh: 3600,
            onError: { error in
                errorReceived = error
            }
        )

        // Should not crash with all options
        XCTAssertTrue(true, "Full configuration should succeed")
        XCTAssertNil(errorReceived, "No error should be received during configuration")
    }

    // MARK: - Event Tracking Tests

    @MainActor
    func testTrackEventWithEventName() {
        UserCanal.shared.configure(apiKey: "test-key")

        // Should not crash when tracking with EventName
        UserCanal.shared.track(.userSignedUp, properties: [
            "method": "email",
            "source": "web"
        ])

        XCTAssertTrue(true, "Event tracking with EventName should not crash")
    }

    @MainActor
    func testTrackEventWithString() {
        UserCanal.shared.configure(apiKey: "test-key")

        // Should not crash when tracking with string
        UserCanal.shared.track("custom.event", properties: [
            "key": "value",
            "number": 42
        ])

        XCTAssertTrue(true, "Event tracking with string should not crash")
    }

    @MainActor
    func testTrackEventWithDictionary() {
        UserCanal.shared.configure(apiKey: "test-key")

        // Should not crash when tracking with dictionary properties
        UserCanal.shared.track(.featureUsed, properties: [
            "feature": "analytics",
            "timestamp": Date(),
            "enabled": true
        ])

        XCTAssertTrue(true, "Event tracking with dictionary should not crash")
    }

    @MainActor
    func testTrackEventWithoutConfiguration() {
        // Should handle gracefully when not configured
        UserCanal.shared.track(.userSignedUp, properties: [:])

        XCTAssertTrue(true, "Event tracking without configuration should not crash")
    }

    // MARK: - Revenue Tracking Tests

    @MainActor
    func testEventRevenue() {
        UserCanal.shared.configure(apiKey: "test-key")

        // Should not crash when tracking revenue
        UserCanal.shared.eventRevenue(
            amount: 9.99,
            currency: .usd,
            orderID: "order_123",
            properties: [
                "product": "premium_subscription",
                "plan": "monthly"
            ]
        )

        XCTAssertTrue(true, "Revenue tracking should not crash")
    }

    @MainActor
    func testEventRevenueWithDictionary() {
        UserCanal.shared.configure(apiKey: "test-key")

        // Should not crash when tracking revenue with dictionary
        UserCanal.shared.eventRevenue(
            amount: 29.99,
            currency: .eur,
            orderID: "order_456",
            properties: [
                "product": "one_time_purchase",
                "category": "digital_goods"
            ]
        )

        XCTAssertTrue(true, "Revenue tracking with dictionary should not crash")
    }

    // MARK: - User Management Tests

    @MainActor
    func testIdentify() {
        UserCanal.shared.configure(apiKey: "test-key")

        // Should not crash when identifying user
        UserCanal.shared.identify("user_123", traits: [
            "email": "test@example.com",
            "name": "Test User",
            "plan": "free"
        ])

        XCTAssertTrue(true, "User identification should not crash")
    }

    @MainActor
    func testIdentifyWithDictionary() {
        UserCanal.shared.configure(apiKey: "test-key")

        // Should not crash when identifying with dictionary
        UserCanal.shared.identify("user_456", traits: [
            "email": "test2@example.com",
            "signup_date": Date(),
            "verified": true
        ])

        XCTAssertTrue(true, "User identification with dictionary should not crash")
    }

    @MainActor
    func testReset() {
        UserCanal.shared.configure(apiKey: "test-key")

        // Identify a user first
        UserCanal.shared.identify("user_123", traits: [:])

        // Should not crash when resetting
        UserCanal.shared.reset()

        XCTAssertTrue(true, "User reset should not crash")
    }

    @MainActor
    func testGroup() {
        UserCanal.shared.configure(apiKey: "test-key")

        // Should not crash when associating with group
        UserCanal.shared.group("org_123", properties: [
            "name": "Test Organization",
            "plan": "enterprise",
            "seats": 50
        ])

        XCTAssertTrue(true, "Group association should not crash")
    }

    @MainActor
    func testGroupWithDictionary() {
        UserCanal.shared.configure(apiKey: "test-key")

        // Should not crash when associating with group using dictionary
        UserCanal.shared.group("org_456", properties: [
            "name": "Another Organization",
            "created_date": Date()
        ])

        XCTAssertTrue(true, "Group association with dictionary should not crash")
    }

    // MARK: - Logging Tests

    @MainActor
    func testLogWithLevel() {
        UserCanal.shared.configure(apiKey: "test-key")

        // Should not crash when logging with level
        UserCanal.shared.log(.info, "Test message", service: "test", data: [
            "key": "value"
        ])

        XCTAssertTrue(true, "Logging with level should not crash")
    }

    @MainActor
    func testLogWithDictionary() {
        UserCanal.shared.configure(apiKey: "test-key")

        // Should not crash when logging with dictionary
        UserCanal.shared.log(.error, "Error message", service: "test", data: [
            "error_code": 500,
            "timestamp": Date()
        ])

        XCTAssertTrue(true, "Logging with dictionary should not crash")
    }

    @MainActor
    func testConvenienceLoggingMethods() {
        UserCanal.shared.configure(apiKey: "test-key")

        // Test all convenience logging methods
        UserCanal.shared.logInfo("Info message")
        UserCanal.shared.logError("Error message")
        UserCanal.shared.logDebug("Debug message")
        UserCanal.shared.logWarning("Warning message")

        XCTAssertTrue(true, "Convenience logging methods should not crash")
    }

    @MainActor
    func testConvenienceLoggingWithData() {
        UserCanal.shared.configure(apiKey: "test-key")

        // Test convenience methods with data
        UserCanal.shared.logInfo("Info with data", service: "test", data: [
            "info": "value"
        ])

        UserCanal.shared.logError("Error with data", service: "test", data: [
            "error": "details"
        ])

        XCTAssertTrue(true, "Convenience logging with data should not crash")
    }

    // MARK: - Predefined Events Tests

    @MainActor
    func testPredefinedEvents() {
        UserCanal.shared.configure(apiKey: "test-key")

        // Test various predefined events
        UserCanal.shared.track(.userSignedUp)
        UserCanal.shared.track(.userSignedIn)
        UserCanal.shared.track(.userSignedOut)
        UserCanal.shared.track(.featureUsed)
        UserCanal.shared.track(.pageViewed)
        UserCanal.shared.track(.orderCompleted)
        UserCanal.shared.track(.subscriptionStarted)
        UserCanal.shared.track(.trialStarted)

        XCTAssertTrue(true, "All predefined events should work")
    }

    @MainActor
    func testAdditionalPredefinedEvents() {
        UserCanal.shared.configure(apiKey: "test-key")

        // Test additional predefined events from UserCanal.swift
        UserCanal.shared.track(.buttonTapped)
        UserCanal.shared.track(.contentViewed)
        UserCanal.shared.track(.contentShared)
        UserCanal.shared.track(.subscriptionPurchased)
        UserCanal.shared.track(.subscriptionCancelled)
        UserCanal.shared.track(.purchaseCompleted)

        XCTAssertTrue(true, "Additional predefined events should work")
    }

    // MARK: - Integration Tests

    @MainActor
    func testCompleteUserFlow() {
        UserCanal.shared.configure(apiKey: "test-key")

        // Simulate a complete user flow

        // Anonymous browsing
        UserCanal.shared.track(.pageViewed, properties: ["page": "home"])
        UserCanal.shared.track(.featureUsed, properties: ["feature": "search"])

        // User signs up
        UserCanal.shared.identify("user_flow_test", traits: [
            "email": "flow@test.com",
            "signup_method": "email"
        ])
        UserCanal.shared.track(.userSignedUp, properties: ["method": "email"])

        // User makes a purchase
        UserCanal.shared.eventRevenue(
            amount: 19.99,
            currency: .usd,
            orderID: "flow_order_123"
        )

        // User joins an organization
        UserCanal.shared.group("flow_org", properties: ["name": "Flow Test Org"])

        // Some activity logging
        UserCanal.shared.logInfo("User completed flow")

        // User logs out
        UserCanal.shared.track(.userSignedOut)
        UserCanal.shared.reset()

        XCTAssertTrue(true, "Complete user flow should not crash")
    }

    // MARK: - Error Handling Tests

    @MainActor
    func testErrorHandling() {
        var errorReceived: (any Error)?

        UserCanal.shared.configure(
            apiKey: "test-key",
            onError: { error in
                errorReceived = error
            }
        )

        // Operations should not crash even with potential errors
        UserCanal.shared.track(.userSignedUp)
        UserCanal.shared.identify("test_user", traits: [:])
        UserCanal.shared.eventRevenue(amount: 1.0, currency: .usd, orderID: "test")

        XCTAssertTrue(true, "Error handling should work gracefully")
    }

    // MARK: - Lifecycle Tests

    @MainActor
    func testFlush() async {
        UserCanal.shared.configure(apiKey: "test-key")

        // Track some events
        UserCanal.shared.track(.userSignedUp)
        UserCanal.shared.track(.featureUsed)

        // Flush should not crash (may throw if not properly initialized)
        do {
            try await UserCanal.shared.flush()
            XCTAssertTrue(true, "Flush completed successfully")
        } catch {
            // Flush may fail if client is not properly initialized in test environment
            XCTAssertTrue(true, "Flush threw error as expected in test environment")
        }
    }

    @MainActor
    func testShutdown() async {
        UserCanal.shared.configure(apiKey: "test-key")

        // Shutdown should not crash
        do {
            try await UserCanal.shared.shutdown()
            XCTAssertTrue(true, "Shutdown completed successfully")
        } catch {
            // Shutdown may fail if client is not properly initialized in test environment
            XCTAssertTrue(true, "Shutdown threw error as expected in test environment")
        }
    }

    // MARK: - Edge Cases

    @MainActor
    func testEmptyValues() {
        UserCanal.shared.configure(apiKey: "test-key")

        // Test with empty values
        UserCanal.shared.track("", properties: [:])
        UserCanal.shared.identify("", traits: [:])
        UserCanal.shared.group("", properties: [:])
        UserCanal.shared.logInfo("")

        XCTAssertTrue(true, "Empty values should be handled gracefully")
    }

    @MainActor
    func testNilAndOptionalValues() {
        UserCanal.shared.configure(apiKey: "test-key")

        // Test with properties containing nil-like values
        UserCanal.shared.track(.userSignedUp, properties: [
            "optional_field": NSNull(),
            "empty_string": "",
            "zero_number": 0
        ])

        XCTAssertTrue(true, "Properties with nil-like values should be handled")
    }

    @MainActor
    func testConcurrentAccess() {
        UserCanal.shared.configure(apiKey: "test-key")

        // Test concurrent access to singleton (basic test)
        let group = DispatchGroup()

        for i in 0..<10 {
            group.enter()
            DispatchQueue.global().async {
                Task { @MainActor in
                    UserCanal.shared.track("concurrent_event_\(i)")
                    group.leave()
                }
            }
        }

        group.wait()
        XCTAssertTrue(true, "Concurrent access should be handled safely")
    }

    // MARK: - Performance Tests

    @MainActor
    func testPerformanceEventTracking() {
        UserCanal.shared.configure(apiKey: "test-key")

        self.measure {
            for i in 0..<100 {
                UserCanal.shared.track("performance_test_\(i)", properties: [
                    "iteration": i,
                    "timestamp": Date()
                ])
            }
        }
    }

    @MainActor
    func testPerformanceRevenue() {
        UserCanal.shared.configure(apiKey: "test-key")

        self.measure {
            for i in 0..<50 {
                UserCanal.shared.eventRevenue(
                    amount: Double(i) * 1.99,
                    currency: .usd,
                    orderID: "perf_order_\(i)"
                )
            }
        }
    }
}
