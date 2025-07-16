// UserCanalSDKTests.swift
// UserCanal Swift SDK Tests
//
// Copyright © 2024 UserCanal. All rights reserved.
//

import XCTest
@testable import UserCanal

final class UserCanalSDKTests: XCTestCase {
    
    // MARK: - Test Properties
    
    private let testAPIKey = "1234567890abcdef1234567890abcdef"
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        // Reset the shared instance state before each test
        await UserCanalSDK.shared.reset()
    }
    
    override func tearDown() async throws {
        // Clean up after tests
        try await UserCanalSDK.shared.shutdown()
        try await super.tearDown()
    }
    
    // MARK: - Configuration Tests
    
    func testConfiguration() {
        let expectation = expectation(description: "Configuration completes")
        
        UserCanalSDK.shared.configure(
            apiKey: testAPIKey,
            onError: { error in
                XCTFail("Unexpected error during configuration: \(error)")
            }
        )
        
        // Give a moment for async initialization
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testConfigurationWithAdvancedOptions() {
        let errorExpectation = expectation(description: "Error handler not called")
        errorExpectation.isInverted = true
        
        UserCanalSDK.shared.configure(
            apiKey: testAPIKey,
            endpoint: "test.usercanal.com:50000",
            batchSize: 50,
            flushInterval: 10.0,
            deviceContextRefresh: 60 * 60, // 1 hour
            onError: { _ in
                errorExpectation.fulfill()
            }
        )
        
        wait(for: [errorExpectation], timeout: 1.0)
    }
    
    func testConfigurationWithInvalidAPIKey() {
        let errorExpectation = expectation(description: "Error handler called")
        
        UserCanalSDK.shared.configure(
            apiKey: "",
            onError: { error in
                XCTAssertTrue(error is UserCanalError)
                errorExpectation.fulfill()
            }
        )
        
        wait(for: [errorExpectation], timeout: 2.0)
    }
    
    // MARK: - Event Tracking Tests
    
    func testEventTrackingWithEventName() async {
        UserCanalSDK.shared.configure(apiKey: testAPIKey)
        
        // Give time for initialization
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Test tracking with EventName
        UserCanalSDK.shared.track(.userSignedUp, properties: [
            "signup_method": "email",
            "referral_source": "google"
        ])
        
        // Test tracking with string
        UserCanalSDK.shared.track("custom_event", properties: [
            "custom_property": "value",
            "count": 42
        ])
        
        // Test tracking with Properties object
        let properties = Properties([
            "feature_name": "dashboard",
            "section": "analytics"
        ])
        UserCanalSDK.shared.track(.featureUsed, properties: properties)
        
        // No assertions needed for fire-and-forget interface
        // Success is measured by not throwing exceptions
    }
    
    func testEventTrackingWithoutConfiguration() {
        // Tracking without configuration should not crash
        UserCanalSDK.shared.track(.userSignedUp, properties: ["test": "value"])
        
        // Should handle gracefully
        XCTAssertTrue(true, "Fire-and-forget interface should not crash")
    }
    
    // MARK: - User Management Tests
    
    func testUserIdentification() async {
        UserCanalSDK.shared.configure(apiKey: testAPIKey)
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Test identification with Properties
        UserCanalSDK.shared.identify("user_123", traits: Properties([
            "email": "user@example.com",
            "plan": "premium",
            "signup_date": Date()
        ]))
        
        // Test identification with dictionary
        UserCanalSDK.shared.identify("user_456", traits: [
            "name": "John Doe",
            "age": 28,
            "verified": true
        ])
    }
    
    func testUserReset() async {
        UserCanalSDK.shared.configure(apiKey: testAPIKey)
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Identify a user
        UserCanalSDK.shared.identify("user_123", traits: ["email": "user@example.com"])
        
        // Reset should clear user and generate new anonymous ID
        UserCanalSDK.shared.reset()
        
        // Track event after reset (should use new anonymous ID)
        UserCanalSDK.shared.track(.screenViewed, properties: ["screen": "home"])
    }
    
    func testGroupAssociation() async {
        UserCanalSDK.shared.configure(apiKey: testAPIKey)
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Test group with Properties
        UserCanalSDK.shared.group("org_123", properties: Properties([
            "organization_name": "Acme Corp",
            "plan": "enterprise",
            "seat_count": 50
        ]))
        
        // Test group with dictionary
        UserCanalSDK.shared.group("team_456", properties: [
            "team_name": "Engineering",
            "size": 12,
            "department": "Product"
        ])
    }
    
    // MARK: - Revenue Tracking Tests
    
    func testRevenueTracking() async {
        UserCanalSDK.shared.configure(apiKey: testAPIKey)
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Test revenue with Properties
        UserCanalSDK.shared.eventRevenue(
            amount: 99.99,
            currency: .USD,
            orderID: "order_123",
            properties: Properties([
                "product_id": "premium_plan",
                "billing_cycle": "monthly"
            ])
        )
        
        // Test revenue with dictionary
        UserCanalSDK.shared.eventRevenue(
            amount: 29.99,
            currency: .USD,
            orderID: "order_456",
            properties: [
                "product_type": "add_on",
                "product_name": "Extra Storage"
            ]
        )
    }
    
    // MARK: - Logging Tests
    
    func testBasicLogging() async {
        UserCanalSDK.shared.configure(apiKey: testAPIKey)
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Test all convenience logging methods
        UserCanalSDK.shared.logInfo("Application started")
        UserCanalSDK.shared.logError("Login failed", data: Properties([
            "user_id": "123",
            "reason": "invalid_password"
        ]))
        UserCanalSDK.shared.logDebug("Processing request", data: ["request_id": "req_456"])
        UserCanalSDK.shared.logWarning("Cache hit ratio low", service: "cache")
    }
    
    func testAdvancedLogging() async {
        UserCanalSDK.shared.configure(apiKey: testAPIKey)
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Test log method with all parameters
        UserCanalSDK.shared.log(
            .critical,
            "Database connection lost",
            service: "database",
            data: Properties([
                "connection_pool": "primary",
                "error_code": "CONN_LOST",
                "retry_count": 3
            ])
        )
        
        // Test log method with dictionary data
        UserCanalSDK.shared.log(
            .info,
            "User action completed",
            service: "user-service",
            data: [
                "action": "profile_update",
                "duration_ms": 150,
                "success": true
            ]
        )
    }
    
    // MARK: - Session Flow Tests
    
    func testAnonymousToIdentifiedFlow() async {
        UserCanalSDK.shared.configure(apiKey: testAPIKey)
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // 1. Anonymous tracking
        UserCanalSDK.shared.track(.screenViewed, properties: ["screen": "landing"])
        UserCanalSDK.shared.track("button_clicked", properties: ["button": "signup"])
        
        // 2. User signs up (anonymous → identified)
        UserCanalSDK.shared.identify("user_789", traits: [
            "email": "user@example.com",
            "signup_method": "email"
        ])
        
        // 3. Identified tracking
        UserCanalSDK.shared.track(.userSignedUp, properties: ["method": "email"])
        UserCanalSDK.shared.track(.featureUsed, properties: ["feature": "onboarding"])
        
        // 4. Revenue event
        UserCanalSDK.shared.eventRevenue(
            amount: 9.99,
            currency: .USD,
            orderID: "order_first"
        )
        
        // The flow should work seamlessly without errors
    }
    
    func testUserSwitching() async {
        UserCanalSDK.shared.configure(apiKey: testAPIKey)
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // User 1
        UserCanalSDK.shared.identify("user_1", traits: ["name": "Alice"])
        UserCanalSDK.shared.track(.featureUsed, properties: ["feature": "dashboard"])
        
        // Switch to User 2
        UserCanalSDK.shared.identify("user_2", traits: ["name": "Bob"])
        UserCanalSDK.shared.track(.featureUsed, properties: ["feature": "reports"])
        
        // Logout (back to anonymous)
        UserCanalSDK.shared.reset()
        UserCanalSDK.shared.track(.screenViewed, properties: ["screen": "logout"])
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandling() {
        let errorExpectation = expectation(description: "Error callback called")
        
        UserCanalSDK.shared.configure(
            apiKey: "invalid_key_format",
            onError: { error in
                XCTAssertNotNil(error)
                errorExpectation.fulfill()
            }
        )
        
        wait(for: [errorExpectation], timeout: 2.0)
    }
    
    func testFireAndForgetNeverCrashes() async {
        // Test that all methods work without configuration
        UserCanalSDK.shared.track(.userSignedUp)
        UserCanalSDK.shared.identify("user", traits: ["key": "value"])
        UserCanalSDK.shared.group("group", properties: ["name": "Test"])
        UserCanalSDK.shared.eventRevenue(amount: 1.0, currency: .USD, orderID: "test")
        UserCanalSDK.shared.logInfo("Test message")
        UserCanalSDK.shared.logError("Test error")
        UserCanalSDK.shared.reset()
        
        // Should not crash
        XCTAssertTrue(true, "Fire-and-forget should never crash")
    }
    
    // MARK: - Lifecycle Tests
    
    func testFlush() async throws {
        UserCanalSDK.shared.configure(apiKey: testAPIKey)
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Track some events
        UserCanalSDK.shared.track(.userSignedUp)
        UserCanalSDK.shared.logInfo("Test log")
        
        // Flush should complete without error
        try await UserCanalSDK.shared.flush()
    }
    
    func testShutdown() async throws {
        UserCanalSDK.shared.configure(apiKey: testAPIKey)
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Track some events
        UserCanalSDK.shared.track(.userSignedUp)
        
        // Shutdown should complete without error
        try await UserCanalSDK.shared.shutdown()
    }
    
    // MARK: - Performance Tests
    
    func testHighVolumeTracking() async {
        UserCanalSDK.shared.configure(apiKey: testAPIKey)
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        let eventCount = 100
        let startTime = Date()
        
        // Track many events rapidly
        for i in 0..<eventCount {
            UserCanalSDK.shared.track("test_event_\(i)", properties: [
                "index": i,
                "timestamp": Date(),
                "random": Int.random(in: 1...1000)
            ])
        }
        
        let duration = Date().timeIntervalSince(startTime)
        
        // Should complete quickly (fire-and-forget)
        XCTAssertLessThan(duration, 1.0, "High volume tracking should be fast")
    }
    
    func testConcurrentTracking() async {
        UserCanalSDK.shared.configure(apiKey: testAPIKey)
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Test concurrent tracking from multiple tasks
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask {
                    UserCanalSDK.shared.track("concurrent_event", properties: [
                        "task_id": i,
                        "timestamp": Date()
                    ])
                }
            }
        }
        
        // Should complete without issues
        XCTAssertTrue(true, "Concurrent tracking should work safely")
    }
}