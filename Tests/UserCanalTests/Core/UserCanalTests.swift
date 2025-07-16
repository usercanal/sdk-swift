// UserCanalTests.swift
// UserCanal Swift SDK Tests
//
// Copyright © 2024 UserCanal. All rights reserved.
//

import XCTest
@testable import UserCanal

@MainActor
final class UserCanalTests: XCTestCase {
    
    // MARK: - Test Properties
    
    private let testAPIKey = "1234567890abcdef1234567890abcdef"
    private let testEndpoint = "localhost:50000"
    
    // MARK: - Configuration Tests
    
    func testConfigurationDefaults() throws {
        let config = UserCanalConfig.default
        
        XCTAssertEqual(config.endpoint, "collect.usercanal.com:50000")
        XCTAssertEqual(config.batchSize, 100)
        XCTAssertEqual(config.flushInterval, .seconds(10))
        XCTAssertEqual(config.maxRetries, 3)
        XCTAssertFalse(config.enableDebugLogging)
        XCTAssertTrue(config.collectDeviceContext)
    }
    
    func testConfigurationValidation() {
        // Test invalid batch size
        XCTAssertThrowsError(try UserCanalConfig(batchSize: 0)) { error in
            XCTAssertTrue(error is UserCanalConfig.ValidationError)
        }
        
        // Test invalid flush interval
        XCTAssertThrowsError(try UserCanalConfig(flushInterval: .milliseconds(50))) { error in
            XCTAssertTrue(error is UserCanalConfig.ValidationError)
        }
        
        // Test invalid max retries
        XCTAssertThrowsError(try UserCanalConfig(maxRetries: -1)) { error in
            XCTAssertTrue(error is UserCanalConfig.ValidationError)
        }
    }
    
    func testConfigurationBuilder() throws {
        let config = try UserCanalConfigBuilder()
            .endpoint("test.example.com:9000")
            .batchSize(50)
            .flushInterval(.seconds(5))
            .maxRetries(2)
            .enableDebugLogging(true)
            .build()
        
        XCTAssertEqual(config.endpoint, "test.example.com:9000")
        XCTAssertEqual(config.batchSize, 50)
        XCTAssertEqual(config.flushInterval, .seconds(5))
        XCTAssertEqual(config.maxRetries, 2)
        XCTAssertTrue(config.enableDebugLogging)
    }
    
    // MARK: - Properties Tests
    
    func testPropertiesCreation() {
        let properties = Properties([
            "string": "test",
            "int": 42,
            "double": 3.14,
            "bool": true,
            "date": Date(),
            "array": [1, 2, 3],
            "nested": ["key": "value"]
        ])
        
        XCTAssertEqual(properties.count, 7)
        XCTAssertEqual(properties.string(for: "string"), "test")
        XCTAssertEqual(properties.int(for: "int"), 42)
        XCTAssertEqual(properties.double(for: "double"), 3.14)
        XCTAssertEqual(properties.bool(for: "bool"), true)
        XCTAssertNotNil(properties.date(for: "date"))
        XCTAssertNotNil(properties.array(for: "array"))
    }
    
    func testPropertiesBuilder() {
        let properties = Properties.build { builder in
            builder
                .set("name", "John Doe")
                .set("age", 30)
                .set("active", true)
        }
        
        XCTAssertEqual(properties.string(for: "name"), "John Doe")
        XCTAssertEqual(properties.int(for: "age"), 30)
        XCTAssertEqual(properties.bool(for: "active"), true)
    }
    
    func testPropertiesModification() {
        let original = Properties(["key1": "value1"])
        let modified = original.modified { builder in
            builder
                .set("key2", "value2")
                .remove("key1")
        }
        
        XCTAssertFalse(modified.contains("key1"))
        XCTAssertEqual(modified.string(for: "key2"), "value2")
    }
    
    // MARK: - Event Tests
    
    func testEventCreation() {
        let event = Event(
            userID: "user123",
            name: .userSignedUp,
            properties: Properties(["source": "test"])
        )
        
        XCTAssertFalse(event.id.isEmpty)
        XCTAssertEqual(event.userID, "user123")
        XCTAssertEqual(event.name, .userSignedUp)
        XCTAssertEqual(event.properties.string(for: "source"), "test")
    }
    
    func testEventValidation() throws {
        // Valid event
        let validEvent = Event(userID: "user123", name: .userSignedUp)
        XCTAssertNoThrow(try validEvent.validate())
        
        // Invalid event - empty user ID
        let invalidEvent = Event(userID: "", name: .userSignedUp)
        XCTAssertThrowsError(try invalidEvent.validate()) { error in
            XCTAssertTrue(error is UserCanalError)
        }
    }
    
    func testEventWithPropertiesBuilder() {
        let event = Event(
            userID: "user123",
            name: .featureUsed
        ) {
            Properties.build { builder in
                builder
                    .set("feature_name", "export")
                    .set("duration_ms", 1500)
            }
        }
        
        XCTAssertEqual(event.properties.string(for: "feature_name"), "export")
        XCTAssertEqual(event.properties.int(for: "duration_ms"), 1500)
    }
    
    // MARK: - EventName Tests
    
    func testEventNameStandard() {
        XCTAssertTrue(EventName.userSignedUp.isStandardEvent)
        XCTAssertTrue(EventName.orderCompleted.isStandardEvent)
        XCTAssertEqual(EventName.userSignedUp.category, .authentication)
        XCTAssertEqual(EventName.orderCompleted.category, .revenue)
    }
    
    func testEventNameCustom() {
        let customEvent = EventName("Custom Event Name")
        XCTAssertFalse(customEvent.isStandardEvent)
        XCTAssertEqual(customEvent.category, .custom)
        XCTAssertEqual(customEvent.stringValue, "Custom Event Name")
    }
    
    func testEventNameStringLiteral() {
        let event: EventName = "String Literal Event"
        XCTAssertEqual(event.stringValue, "String Literal Event")
        XCTAssertFalse(event.isStandardEvent)
    }
    
    // MARK: - Currency Tests
    
    func testCurrencyCreation() {
        let usd = Currency.usd
        XCTAssertEqual(usd.currencyCode, "USD")
        XCTAssertEqual(usd.symbol, "$")
        XCTAssertEqual(usd.name, "US Dollar")
        XCTAssertEqual(usd.decimalPlaces, 2)
        XCTAssertTrue(usd.isMajorCurrency)
        XCTAssertFalse(usd.isCryptocurrency)
    }
    
    func testCurrencyValidation() throws {
        // Valid currency
        XCTAssertNoThrow(try Currency.usd.validate())
        
        // Invalid currency - empty code
        let invalidCurrency = Currency("")
        XCTAssertThrowsError(try invalidCurrency.validate())
    }
    
    func testCurrencyFormatting() {
        let usd = Currency.usd
        let formatted = usd.format(amount: 99.99)
        XCTAssertTrue(formatted.contains("99.99") || formatted.contains("$"))
    }
    
    // MARK: - Identity Tests
    
    func testIdentityCreation() {
        let identity = Identity(
            userID: "user123",
            properties: Properties(["name": "John Doe", "email": "john@example.com"])
        )
        
        XCTAssertEqual(identity.userID, "user123")
        XCTAssertEqual(identity.properties.string(for: "name"), "John Doe")
        XCTAssertEqual(identity.properties.string(for: "email"), "john@example.com")
    }
    
    func testIdentityValidation() throws {
        // Valid identity
        let validIdentity = Identity(userID: "user123")
        XCTAssertNoThrow(try validIdentity.validate())
        
        // Invalid identity - empty user ID
        let invalidIdentity = Identity(userID: "")
        XCTAssertThrowsError(try invalidIdentity.validate())
    }
    
    // MARK: - Revenue Tests
    
    func testRevenueCreation() {
        let revenue = Revenue(
            userID: "user123",
            orderID: "order456",
            amount: 29.99,
            currency: .usd,
            type: .subscription,
            properties: Properties(["plan": "premium"])
        )
        
        XCTAssertEqual(revenue.userID, "user123")
        XCTAssertEqual(revenue.orderID, "order456")
        XCTAssertEqual(revenue.amount, 29.99)
        XCTAssertEqual(revenue.currency, .usd)
        XCTAssertEqual(revenue.type, .subscription)
    }
    
    func testRevenueValidation() throws {
        // Valid revenue
        let validRevenue = Revenue(
            userID: "user123",
            orderID: "order456",
            amount: 29.99,
            currency: .usd
        )
        XCTAssertNoThrow(try validRevenue.validate())
        
        // Invalid revenue - negative amount
        let invalidRevenue = Revenue(
            userID: "user123",
            orderID: "order456",
            amount: -10.0,
            currency: .usd
        )
        XCTAssertThrowsError(try invalidRevenue.validate())
    }
    
    // MARK: - Product Tests
    
    func testProductCreation() {
        let product = Product(
            id: "prod123",
            name: "Premium Plan",
            price: 29.99,
            quantity: 1
        )
        
        XCTAssertEqual(product.id, "prod123")
        XCTAssertEqual(product.name, "Premium Plan")
        XCTAssertEqual(product.price, 29.99)
        XCTAssertEqual(product.quantity, 1)
        XCTAssertEqual(product.totalValue, 29.99)
    }
    
    func testProductTotalValue() {
        let product = Product(
            id: "prod123",
            name: "Item",
            price: 10.0,
            quantity: 3
        )
        
        XCTAssertEqual(product.totalValue, 30.0)
    }
    
    // MARK: - LogEntry Tests
    
    func testLogEntryCreation() {
        let logEntry = LogEntry(
            level: .info,
            service: "test-service",
            message: "Test message",
            data: Properties(["key": "value"])
        )
        
        XCTAssertEqual(logEntry.level, .info)
        XCTAssertEqual(logEntry.service, "test-service")
        XCTAssertEqual(logEntry.message, "Test message")
        XCTAssertEqual(logEntry.data.string(for: "key"), "value")
    }
    
    func testLogEntryValidation() throws {
        // Valid log entry
        let validLog = LogEntry(
            level: .info,
            service: "test-service",
            message: "Test message"
        )
        XCTAssertNoThrow(try validLog.validate())
        
        // Invalid log entry - empty service
        let invalidLog = LogEntry(
            level: .info,
            service: "",
            message: "Test message"
        )
        XCTAssertThrowsError(try invalidLog.validate())
    }
    
    // MARK: - Error Tests
    
    func testUserCanalErrorRecoveryInfo() {
        let networkError = UserCanalError.networkFailure(.noConnection)
        let recoveryInfo = networkError.recoveryInfo
        
        XCTAssertTrue(recoveryInfo.isRecoverable)
        XCTAssertNotNil(recoveryInfo.suggestedRetryDelay)
        XCTAssertTrue(recoveryInfo.recoveryActions.contains(.checkNetworkConnection))
    }
    
    func testValidationErrorNotRecoverable() {
        let validationError = UserCanalError.validationError(field: "test", reason: "test")
        let recoveryInfo = validationError.recoveryInfo
        
        XCTAssertFalse(recoveryInfo.isRecoverable)
        XCTAssertTrue(recoveryInfo.recoveryActions.contains(.validateConfiguration))
    }
    
    // MARK: - Version Tests
    
    func testVersionInfo() {
        let version = Version.info
        
        XCTAssertFalse(version.version.isEmpty)
        XCTAssertEqual(version.protocolVersion, "v1")
        XCTAssertEqual(version.swiftVersion, "6.0")
        XCTAssertFalse(version.platform.osName.isEmpty)
    }
    
    func testVersionUserAgent() {
        let userAgent = Version.userAgent
        
        XCTAssertTrue(userAgent.contains("usercanal-swift-sdk"))
        XCTAssertTrue(userAgent.contains("Swift/6.0"))
    }
    
    // MARK: - Network Configuration Tests
    
    func testNetworkConfig() {
        let config = NetworkConfig.default
        
        XCTAssertEqual(config.retryConfig.maxAttempts, 5)
        XCTAssertEqual(config.retryConfig.baseDelay, 1.0)
        XCTAssertEqual(config.retryConfig.maxDelay, 30.0)
        XCTAssertEqual(config.retryConfig.multiplier, 1.5)
    }
    
    func testRetryDelayCalculation() {
        let retryConfig = RetryConfig.default
        
        let delay1 = retryConfig.calculateDelay(for: 1)
        let delay2 = retryConfig.calculateDelay(for: 2)
        let delay3 = retryConfig.calculateDelay(for: 3)
        
        XCTAssertEqual(delay1, 1.0)
        XCTAssertEqual(delay2, 1.5)
        XCTAssertEqual(delay3, 2.25)
    }
    
    // MARK: - FlatBuffers Protocol Tests
    
    func testSchemaTypes() {
        XCTAssertEqual(SchemaType.unknown.rawValue, 0)
        XCTAssertEqual(SchemaType.events.rawValue, 1)
        XCTAssertEqual(SchemaType.logs.rawValue, 2)
    }
    
    func testLogLevelRawValues() {
        XCTAssertEqual(LogLevel.emergency.rawValue, 0)
        XCTAssertEqual(LogLevel.alert.rawValue, 1)
        XCTAssertEqual(LogLevel.critical.rawValue, 2)
        XCTAssertEqual(LogLevel.error.rawValue, 3)
        XCTAssertEqual(LogLevel.warning.rawValue, 4)
        XCTAssertEqual(LogLevel.notice.rawValue, 5)
        XCTAssertEqual(LogLevel.info.rawValue, 6)
        XCTAssertEqual(LogLevel.debug.rawValue, 7)
        XCTAssertEqual(LogLevel.trace.rawValue, 8)
    }
    
    // MARK: - Data Extension Tests
    
    func testDataFromHexString() {
        let hexString = "1234567890abcdef"
        let data = Data(fromHexString: hexString)
        
        XCTAssertNotNil(data)
        XCTAssertEqual(data?.count, 8)
        
        // Test invalid hex
        let invalidHex = Data(fromHexString: "invalid")
        XCTAssertNil(invalidHex)
        
        // Test odd length hex
        let oddLengthHex = Data(fromHexString: "123")
        XCTAssertNil(oddLengthHex)
    }
    
    func testUInt32BigEndianBytes() {
        let value: UInt32 = 0x12345678
        let bytes = value.bigEndianBytes
        
        XCTAssertEqual(bytes.count, 4)
        XCTAssertEqual(bytes[0], 0x12)
        XCTAssertEqual(bytes[1], 0x34)
        XCTAssertEqual(bytes[2], 0x56)
        XCTAssertEqual(bytes[3], 0x78)
    }
    
    // MARK: - Constants Tests
    
    func testRevenueTypeConstants() {
        XCTAssertEqual(RevenueType.oneTime.rawValue, "one_time")
        XCTAssertEqual(RevenueType.subscription.rawValue, "subscription")
    }
    
    func testAuthMethodConstants() {
        XCTAssertEqual(AuthMethod.password.rawValue, "password")
        XCTAssertEqual(AuthMethod.apple.rawValue, "apple")
        XCTAssertEqual(AuthMethod.google.rawValue, "google")
    }
    
    func testDeviceTypeConstants() {
        XCTAssertEqual(DeviceType.mobile.rawValue, "mobile")
        XCTAssertEqual(DeviceType.tablet.rawValue, "tablet")
        XCTAssertEqual(DeviceType.desktop.rawValue, "desktop")
    }
    
    func testOSTypeConstants() {
        XCTAssertEqual(OSType.iOS.rawValue, "ios")
        XCTAssertEqual(OSType.macOS.rawValue, "macos")
        XCTAssertEqual(OSType.visionOS.rawValue, "visionos")
    }
    
    // MARK: - Performance Tests
    
    func testEventCreationPerformance() {
        measure {
            for i in 0..<1000 {
                let event = Event(
                    userID: "user\(i)",
                    name: .featureUsed,
                    properties: Properties([
                        "feature": "test",
                        "value": i,
                        "timestamp": Date()
                    ])
                )
                _ = event.id
            }
        }
    }
    
    func testPropertiesPerformance() {
        let largeProperties = Properties((0..<100).reduce(into: [String: Any]()) { dict, i in
            dict["key\(i)"] = "value\(i)"
        })
        
        measure {
            for _ in 0..<100 {
                _ = largeProperties.dictionary
            }
        }
    }
}

// MARK: - Test Extensions

extension UserCanalTests {
    
    /// Helper to create test configuration
    private func createTestConfig() throws -> UserCanalConfig {
        return try UserCanalConfig(
            endpoint: testEndpoint,
            batchSize: 10,
            flushInterval: .seconds(1),
            maxRetries: 1,
            enableDebugLogging: true
        )
    }
    
    /// Helper to create test event
    private func createTestEvent() -> Event {
        return Event(
            userID: "test_user",
            name: .featureUsed,
            properties: Properties(["test": true])
        )
    }
    
    /// Helper to create test identity
    private func createTestIdentity() -> Identity {
        return Identity(
            userID: "test_user",
            properties: Properties(["name": "Test User"])
        )
    }
    
    /// Helper to create test revenue
    private func createTestRevenue() -> Revenue {
        return Revenue(
            userID: "test_user",
            orderID: "test_order",
            amount: 99.99,
            currency: .usd
        )
    }
    
    /// Helper to create test log entry
    private func createTestLogEntry() -> LogEntry {
        return LogEntry(
            level: .info,
            service: "test-service",
            message: "Test log message",
            data: Properties(["test": true])
        )
    }
}