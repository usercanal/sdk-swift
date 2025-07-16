// ClientInterfaceTests.swift
// UserCanal Swift SDK Tests
//
// Copyright © 2024 UserCanal. All rights reserved.
//

import XCTest
@testable import UserCanal

final class ClientInterfaceTests: XCTestCase {
    
    // MARK: - Test Properties
    
    private let testAPIKey = "1234567890abcdef1234567890abcdef"
    private var client: UserCanalClient!
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Initialize client for testing
        client = try await UserCanalClient(
            apiKey: testAPIKey,
            config: UserCanalConfig.default
                .endpoint("https://test.usercanal.com")
                .collectDeviceContext(false) // Disable for testing
                .batchSize(1) // Immediate batching for tests
                .flushInterval(.seconds(1))
        )
    }
    
    override func tearDown() async throws {
        if let client = client {
            try await client.close()
        }
        try await super.tearDown()
    }
    
    // MARK: - Interface Compatibility Tests (vs Go SDK)
    
    func testEventTrackingInterface() async {
        // Swift SDK: client.event()
        // Go SDK: client.Event()
        // Both should track events with same data structure
        
        client.event(
            userID: "user123",
            eventName: .userSignedUp,
            properties: Properties([
                "source": "organic",
                "plan": "free"
            ])
        )
        
        // Fire-and-forget should not throw
        // Verify via statistics after brief delay
        try? await Task.sleep(for: .milliseconds(100))
        let stats = await client.statistics
        XCTAssertEqual(stats.eventsTracked, 1)
    }
    
    func testIdentifyInterface() async {
        // Swift SDK: client.eventIdentify()
        // Go SDK: client.EventIdentify() 
        // Both should identify users with traits
        
        client.eventIdentify(
            userID: "user123",
            traits: Properties([
                "name": "John Doe",
                "email": "john@example.com",
                "plan": "premium"
            ])
        )
        
        try? await Task.sleep(for: .milliseconds(100))
        let stats = await client.statistics
        XCTAssertEqual(stats.identitiesTracked, 1)
    }
    
    func testGroupInterface() async {
        // Swift SDK: client.eventGroup()
        // Go SDK: client.EventGroup()
        // Both should associate users with groups
        
        client.eventGroup(
            userID: "user123",
            groupID: "company456",
            properties: Properties([
                "company_name": "ACME Corp",
                "industry": "Technology"
            ])
        )
        
        try? await Task.sleep(for: .milliseconds(100))
        let stats = await client.statistics
        XCTAssertEqual(stats.groupsTracked, 1)
    }
    
    func testRevenueInterface() async {
        // Swift SDK: client.eventRevenue()
        // Go SDK: client.EventRevenue()
        // Both should track revenue with same parameters
        
        client.eventRevenue(
            userID: "user123",
            orderID: "order456",
            amount: 99.99,
            currency: .USD,
            properties: Properties([
                "payment_method": "credit_card",
                "billing_cycle": "monthly"
            ])
        )
        
        try? await Task.sleep(for: .milliseconds(100))
        let stats = await client.statistics
        XCTAssertEqual(stats.revenueTracked, 1)
    }
    
    func testLoggingInterface() async {
        // Swift SDK: client.logInfo(), client.logError()
        // Go SDK: client.LogInfo(), client.LogError()
        // Both should log with same severity levels
        
        client.logInfo(
            service: "onboarding-service",
            "User completed onboarding",
            data: Properties([
                "steps_completed": 5,
                "time_taken": 120,
                "help_used": false
            ])
        )
        
        client.logError(
            service: "payment-service", 
            "Payment processing failed",
            data: Properties([
                "error_code": "CARD_DECLINED",
                "retry_count": 1
            ])
        )
        
        try? await Task.sleep(for: .milliseconds(100))
        let stats = await client.statistics
        XCTAssertEqual(stats.logsTracked, 2)
    }
    
    // MARK: - Event Name Constants Compatibility
    
    func testEventNameConstants() {
        // Verify Swift event names match Go SDK constants
        
        // User lifecycle events
        XCTAssertEqual(EventName.userSignedUp.stringValue, "user_signed_up")
        XCTAssertEqual(EventName.userSignedIn.stringValue, "user_signed_in")
        XCTAssertEqual(EventName.userSignedOut.stringValue, "user_signed_out")
        XCTAssertEqual(EventName.userInvited.stringValue, "user_invited")
        XCTAssertEqual(EventName.userOnboarded.stringValue, "user_onboarded")
        
        // Authentication events
        XCTAssertEqual(EventName.authenticationFailed.stringValue, "authentication_failed")
        XCTAssertEqual(EventName.passwordReset.stringValue, "password_reset")
        XCTAssertEqual(EventName.twoFactorEnabled.stringValue, "two_factor_enabled")
        XCTAssertEqual(EventName.twoFactorDisabled.stringValue, "two_factor_disabled")
        
        // Commerce events
        XCTAssertEqual(EventName.orderCompleted.stringValue, "order_completed")
        XCTAssertEqual(EventName.orderRefunded.stringValue, "order_refunded")
        XCTAssertEqual(EventName.orderCanceled.stringValue, "order_canceled")
        XCTAssertEqual(EventName.paymentFailed.stringValue, "payment_failed")
        
        // Subscription events
        XCTAssertEqual(EventName.subscriptionStarted.stringValue, "subscription_started")
        XCTAssertEqual(EventName.subscriptionRenewed.stringValue, "subscription_renewed")
        XCTAssertEqual(EventName.subscriptionCanceled.stringValue, "subscription_canceled")
        
        // Product events
        XCTAssertEqual(EventName.pageViewed.stringValue, "page_viewed")
        XCTAssertEqual(EventName.featureUsed.stringValue, "feature_used")
        XCTAssertEqual(EventName.searchPerformed.stringValue, "search_performed")
    }
    
    func testCurrencyConstants() {
        // Verify Swift currency constants match Go SDK
        
        // Major currencies
        XCTAssertEqual(Currency.USD.rawValue, "USD")
        XCTAssertEqual(Currency.EUR.rawValue, "EUR")
        XCTAssertEqual(Currency.GBP.rawValue, "GBP")
        XCTAssertEqual(Currency.JPY.rawValue, "JPY")
        XCTAssertEqual(Currency.CAD.rawValue, "CAD")
        XCTAssertEqual(Currency.AUD.rawValue, "AUD")
        
        // Crypto currencies
        XCTAssertEqual(Currency.BTC.rawValue, "BTC")
        XCTAssertEqual(Currency.ETH.rawValue, "ETH")
        XCTAssertEqual(Currency.USDC.rawValue, "USDC")
        XCTAssertEqual(Currency.USDT.rawValue, "USDT")
    }
    
    func testRevenueTypeConstants() {
        // Verify Swift revenue types match Go SDK
        XCTAssertEqual(RevenueType.oneTime.rawValue, "one_time")
        XCTAssertEqual(RevenueType.subscription.rawValue, "subscription")
        XCTAssertEqual(RevenueType.inApp.rawValue, "in_app")
    }
    
    // MARK: - Fire-and-Forget Interface Tests
    
    func testFireAndForgetBehavior() async {
        // Swift SDK emphasizes fire-and-forget for analytics
        // Go SDK requires explicit error handling
        
        let startTime = Date()
        
        // These should all complete immediately (non-blocking)
        client.event(userID: "user1", eventName: .userSignedUp)
        client.event(userID: "user2", eventName: .userSignedIn)
        client.event(userID: "user3", eventName: .pageViewed)
        client.eventIdentify(userID: "user1", traits: Properties(["name": "John"]))
        client.eventRevenue(userID: "user2", orderID: "order123", amount: 29.99, currency: .USD)
        
        let duration = Date().timeIntervalSince(startTime)
        
        // Should complete in under 50ms (fire-and-forget)
        XCTAssertLessThan(duration, 0.05)
        
        // Verify events were processed in background
        try? await Task.sleep(for: .milliseconds(200))
        let stats = await client.statistics
        XCTAssertEqual(stats.eventsTracked, 3)
        XCTAssertEqual(stats.identitiesTracked, 1)
        XCTAssertEqual(stats.revenueTracked, 1)
    }
    
    func testConcurrentFireAndForget() async {
        // Test that multiple concurrent fire-and-forget calls work correctly
        
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask { [weak self] in
                    self?.client.event(
                        userID: "user\(i)",
                        eventName: .featureUsed,
                        properties: Properties(["feature": "test_\(i)"])
                    )
                }
            }
        }
        
        // Allow background processing
        try? await Task.sleep(for: .milliseconds(300))
        let stats = await client.statistics
        XCTAssertEqual(stats.eventsTracked, 10)
    }
    
    // MARK: - Error Handling Compatibility
    
    func testGracefulErrorHandling() async {
        // Swift SDK should handle errors gracefully in fire-and-forget mode
        // Go SDK returns errors explicitly
        
        // These should all be handled gracefully (no crashes/exceptions)
        client.event(userID: "", eventName: .userSignedUp) // Empty user ID
        client.eventIdentify(userID: "", traits: Properties(["name": "John"])) // Empty user ID
        client.eventGroup(userID: "user123", groupID: "", properties: Properties([:]))  // Empty group ID
        client.eventRevenue(userID: "user123", orderID: "order123", amount: -10.0, currency: .USD) // Negative amount
        client.logInfo(service: "test-service", "") // Empty message
        
        // All should be dropped silently
        try? await Task.sleep(for: .milliseconds(100))
        let stats = await client.statistics
        XCTAssertEqual(stats.eventsTracked, 0)
        XCTAssertEqual(stats.identitiesTracked, 0)
        XCTAssertEqual(stats.groupsTracked, 0)
        XCTAssertEqual(stats.revenueTracked, 0)
        XCTAssertEqual(stats.logsTracked, 0)
    }
    
    // MARK: - Configuration Compatibility
    
    func testConfigurationOptions() async throws {
        // Both SDKs should support similar configuration options
        
        let config = UserCanalConfig.default
            .endpoint("https://custom.usercanal.com")
            .batchSize(50)
            .flushInterval(.seconds(5))
            .maxRetries(3)
            .collectDeviceContext(true)
        
        let testClient = try await UserCanalClient(
            apiKey: testAPIKey,
            config: config
        )
        
        // Verify client was created successfully with custom config
        XCTAssertNotNil(testClient)
        
        try await testClient.close()
    }
    
    func testConfigurationBuilder() async throws {
        // Test configuration builder pattern
        
        let testClient = try await UserCanalClient(apiKey: testAPIKey) {
            UserCanalConfig.default
                .batchSize(25)
                .flushInterval(.seconds(2))
                .collectDeviceContext(false)
        }
        
        XCTAssertNotNil(testClient)
        try await testClient.close()
    }
    
    // MARK: - Product Structure Compatibility
    
    func testProductStructure() {
        // Verify Product structure matches Go SDK exactly
        
        let product = Product(
            id: "prod_123",
            name: "Premium Plan",
            price: 99.99,
            quantity: 1,
            properties: Properties([
                "category": "subscription",
                "billing_cycle": "monthly"
            ])
        )
        
        // Go SDK Product fields: ID, Name, Price, Quantity
        // No Currency field on Product (it's on Revenue level)
        XCTAssertEqual(product.id, "prod_123")
        XCTAssertEqual(product.name, "Premium Plan")
        XCTAssertEqual(product.price, 99.99, accuracy: 0.001)
        XCTAssertEqual(product.quantity, 1)
        XCTAssertEqual(product.totalValue, 99.99, accuracy: 0.001)
        
        // Verify product validates correctly
        XCTAssertNoThrow(try product.validate())
    }
    
    func testRevenueProductCompatibility() {
        // Verify Revenue with Products matches Go SDK structure
        
        let products = [
            Product(id: "prod1", name: "Basic Plan", price: 29.99, quantity: 1),
            Product(id: "prod2", name: "Add-on", price: 9.99, quantity: 2)
        ]
        
        let revenue = Revenue(
            userID: "user123",
            orderID: "order_456",
            amount: 49.97, // 29.99 + (9.99 * 2)
            currency: .USD, // Currency is at Revenue level, not Product level
            type: .oneTime,
            products: products,
            properties: Properties([
                "payment_method": "credit_card",
                "processor": "stripe"
            ])
        )
        
        XCTAssertEqual(revenue.products.count, 2)
        XCTAssertEqual(revenue.currency, .USD)
        XCTAssertEqual(revenue.type, .oneTime)
        XCTAssertNoThrow(try revenue.validate())
    }
    
    // MARK: - Batch Processing Compatibility
    
    func testAutomaticBatching() async {
        // Both SDKs should batch events automatically
        // Swift SDK batches even single events (vs Go SDK manual batching)
        
        // Send events rapidly
        for i in 0..<5 {
            client.event(
                userID: "user\(i)",
                eventName: .pageViewed,
                properties: Properties(["page": "page\(i)"])
            )
        }
        
        // Allow batching to complete
        try? await Task.sleep(for: .milliseconds(200))
        
        let stats = await client.statistics
        XCTAssertEqual(stats.eventsTracked, 5)
        XCTAssertGreaterThan(stats.totalItemsProcessed, 0)
    }
    
    // MARK: - Statistics and Monitoring
    
    func testClientStatistics() async {
        // Test that statistics tracking works
        
        client.event(userID: "user1", eventName: .userSignedUp)
        client.eventIdentify(userID: "user1", traits: Properties(["plan": "free"]))
        client.eventGroup(userID: "user1", groupID: "company1")
        client.eventRevenue(userID: "user1", orderID: "order456", amount: 29.99, currency: .USD)
        client.logInfo(service: "test-service", "Test log message")
        
        try? await Task.sleep(for: .milliseconds(200))
        
        let stats = await client.statistics
        XCTAssertEqual(stats.eventsTracked, 1)
        XCTAssertEqual(stats.identitiesTracked, 1)
        XCTAssertEqual(stats.groupsTracked, 1)
        XCTAssertEqual(stats.revenueTracked, 1)
        XCTAssertEqual(stats.logsTracked, 1)
        XCTAssertEqual(stats.totalItemsProcessed, 5)
    }
    
    // MARK: - Client Lifecycle
    
    func testClientLifecycle() async throws {
        // Test proper initialization and cleanup
        
        let testClient = try await UserCanalClient(
            apiKey: testAPIKey,
            config: UserCanalConfig.default
        )
        
        // Client should be ready for use immediately after initialization
        testClient.event(userID: "test", eventName: .userSignedUp)
        
        // Should be able to close cleanly
        try await testClient.close()
        
        // After close, operations should be dropped gracefully
        testClient.event(userID: "test", eventName: .userSignedIn)
        
        // No exceptions should be thrown
    }
    
    func testMultipleClients() async throws {
        // Test that multiple clients can coexist
        
        let client1 = try await UserCanalClient(
            apiKey: testAPIKey,
            config: UserCanalConfig.default.batchSize(10)
        )
        
        let client2 = try await UserCanalClient(
            apiKey: testAPIKey,
            config: UserCanalConfig.default.batchSize(20)
        )
        
        client1.event(userID: "user1", eventName: .userSignedUp)
        client2.event(userID: "user2", eventName: .userSignedIn)
        
        try? await Task.sleep(for: .milliseconds(100))
        
        let stats1 = await client1.statistics
        let stats2 = await client2.statistics
        
        XCTAssertEqual(stats1.eventsTracked, 1)
        XCTAssertEqual(stats2.eventsTracked, 1)
        
        try await client1.close()
        try await client2.close()
    }
    
    // MARK: - Device Context Integration
    
    func testDeviceContextIntegration() async throws {
        // Test device context enrichment (Swift SDK specific feature)
        
        let contextClient = try await UserCanalClient(
            apiKey: testAPIKey,
            config: UserCanalConfig.default
                .collectDeviceContext(true)
        )
        
        contextClient.event(
            userID: "user123",
            eventName: .featureUsed,
            properties: Properties([
                "feature": "device_detection"
            ])
        )
        
        try? await Task.sleep(for: .milliseconds(100))
        
        let stats = await contextClient.statistics
        XCTAssertEqual(stats.eventsTracked, 1)
        
        try await contextClient.close()
    }
    
    // MARK: - Flush and Close Operations
    
    func testFlushOperation() async throws {
        // Both SDKs should support flushing pending data
        
        // Add some events
        client.event(userID: "user1", eventName: .userSignedUp)
        client.event(userID: "user2", eventName: .userSignedIn)
        
        // Explicit flush
        try await client.flush()
        
        let stats = await client.statistics
        XCTAssertEqual(stats.eventsTracked, 2)
    }
    
    func testCloseOperation() async throws {
        // Close should flush all pending data
        
        client.event(userID: "user1", eventName: .userSignedUp)
        client.eventIdentify(userID: "user1", traits: Properties(["name": "John"]))
        
        // Close should flush everything
        try await client.close()
        
        // Statistics should show all events were processed
        let stats = await client.statistics
        XCTAssertEqual(stats.eventsTracked, 1)
        XCTAssertEqual(stats.identitiesTracked, 1)
    }
}