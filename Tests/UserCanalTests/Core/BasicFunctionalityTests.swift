// BasicFunctionalityTests.swift
// UserCanal Swift SDK Tests
//
// Copyright © 2024 UserCanal. All rights reserved.
//

import XCTest
@testable import UserCanal

final class BasicFunctionalityTests: XCTestCase {

    // MARK: - Event Tests

    func testEventCreation() {
        // Test basic event creation
        let event = Event(
            userID: "test_user_123",
            name: .custom("button_clicked"),
            properties: Properties(["button": "signup", "page": "home"])
        )

        XCTAssertEqual(event.userID, "test_user_123")
        XCTAssertEqual(event.name.value, "button_clicked")
        XCTAssertEqual(event.properties["button"] as? String, "signup")
        XCTAssertEqual(event.properties["page"] as? String, "home")
        XCTAssertFalse(event.id.isEmpty)
    }

    func testEventWithPresetNames() {
        let signupEvent = Event(
            userID: "user_456",
            name: .userSignedUp
        )

        XCTAssertEqual(signupEvent.name.value, "user.signed_up")
        XCTAssertEqual(signupEvent.userID, "user_456")
    }

    func testEventValidation() {
        // Test empty user ID
        let invalidEvent = Event(
            userID: "",
            name: .custom("test")
        )

        XCTAssertThrowsError(try invalidEvent.validate()) { error in
            XCTAssertTrue(error is UserCanalError)
        }

        // Test valid event
        let validEvent = Event(
            userID: "valid_user",
            name: .custom("valid_event")
        )

        XCTAssertNoThrow(try validEvent.validate())
    }

    func testEventWithDeviceContext() {
        let properties = Properties([
            "custom_prop": "value",
            "device_type": "mobile",
            "operating_system": "iOS"
        ])

        let event = Event(
            userID: "user_123",
            name: .featureUsed,
            properties: properties
        )

        XCTAssertEqual(event.properties["custom_prop"] as? String, "value")
        XCTAssertEqual(event.properties["device_type"] as? String, "mobile")
        XCTAssertEqual(event.properties["operating_system"] as? String, "iOS")
    }

    // MARK: - LogEntry Tests

    func testLogEntryCreation() {
        let logEntry = LogEntry(
            eventType: .collect,
            level: .info,
            source: "test_source",
            service: "test_service",
            message: "Test log message",
            data: Properties(["key": "value"])
        )

        XCTAssertEqual(logEntry.eventType, .collect)
        XCTAssertEqual(logEntry.level, .info)
        XCTAssertEqual(logEntry.source, "test_source")
        XCTAssertEqual(logEntry.service, "test_service")
        XCTAssertEqual(logEntry.message, "Test log message")
        XCTAssertEqual(logEntry.data["key"] as? String, "value")
        XCTAssertGreaterThan(logEntry.contextID, 0)
    }

    func testLogLevelComparison() {
        XCTAssertLessThan(LogLevel.emergency, LogLevel.alert)
        XCTAssertLessThan(LogLevel.error, LogLevel.warning)
        XCTAssertLessThan(LogLevel.info, LogLevel.debug)
        XCTAssertLessThan(LogLevel.debug, LogLevel.trace)
    }

    func testLogValidation() {
        // Test empty message
        let invalidLog = LogEntry(
            eventType: .collect,
            level: .info,
            source: "source",
            service: "service",
            message: "",
            data: Properties()
        )

        XCTAssertThrowsError(try invalidLog.validate()) { error in
            XCTAssertTrue(error is UserCanalError)
        }

        // Test valid log
        let validLog = LogEntry(
            eventType: .collect,
            level: .info,
            source: "source",
            service: "service",
            message: "Valid message",
            data: Properties()
        )

        XCTAssertNoThrow(try validLog.validate())
    }

    // MARK: - Properties Tests

    func testPropertiesCreation() {
        let properties = Properties([
            "string": "value",
            "number": 42,
            "boolean": true,
            "array": [1, 2, 3],
            "nested": ["key": "value"]
        ])

        XCTAssertEqual(properties["string"] as? String, "value")
        XCTAssertEqual(properties["number"] as? Int, 42)
        XCTAssertEqual(properties["boolean"] as? Bool, true)
        XCTAssertEqual(properties["array"] as? [Int], [1, 2, 3])

        if let nested = properties["nested"] as? [String: String] {
            XCTAssertEqual(nested["key"], "value")
        } else {
            XCTFail("Nested property not found or wrong type")
        }
    }

    func testPropertiesModification() {
        let original = Properties(["key1": "value1"])

        let modified = original.modified { builder in
            builder.set("key2", "value2")
                .set("key3", 123)
        }

        XCTAssertEqual(original["key1"] as? String, "value1")
        XCTAssertNil(original["key2"])

        XCTAssertEqual(modified["key1"] as? String, "value1")
        XCTAssertEqual(modified["key2"] as? String, "value2")
        XCTAssertEqual(modified["key3"] as? Int, 123)
    }

    func testPropertiesEquality() {
        let props1 = Properties(["key": "value", "number": 42])
        let props2 = Properties(["key": "value", "number": 42])
        let props3 = Properties(["key": "different", "number": 42])

        XCTAssertEqual(props1, props2)
        XCTAssertNotEqual(props1, props3)
    }

    // MARK: - Device Context Tests

    func testDeviceContextCreation() async {
        let deviceContext = DeviceContext()

        let minimalContext = await deviceContext.getMinimalContext()

        XCTAssertTrue(minimalContext.keys.contains("device_type"))
        XCTAssertTrue(minimalContext.keys.contains("operating_system"))
        XCTAssertTrue(minimalContext.keys.contains("os_version"))
        XCTAssertTrue(minimalContext.keys.contains("app_version"))

        // Verify device type is valid
        if let deviceType = minimalContext["device_type"] as? String {
            let validTypes = ["mobile", "tablet", "desktop", "tv", "watch", "vr", "unknown"]
            XCTAssertTrue(validTypes.contains(deviceType))
        } else {
            XCTFail("device_type not found or wrong type")
        }

        // Verify operating system is valid
        if let os = minimalContext["operating_system"] as? String {
            let validOS = ["iOS", "macOS", "watchOS", "tvOS", "unknown"]
            XCTAssertTrue(validOS.contains(os))
        } else {
            XCTFail("operating_system not found or wrong type")
        }
    }

    func testDeviceContextCaching() async {
        let deviceContext = DeviceContext()

        // First call
        let context1 = await deviceContext.getContext()

        // Second call should return cached version
        let context2 = await deviceContext.getContext()

        // Values should be identical (testing caching works)
        XCTAssertEqual(context1.count, context2.count)

        for (key, value1) in context1 {
            if let value2 = context2[key] {
                XCTAssertEqual(String(describing: value1), String(describing: value2))
            } else {
                XCTFail("Key \(key) missing from second context call")
            }
        }
    }

    // MARK: - EventName Tests

    func testEventNamePresets() {
        XCTAssertEqual(EventName.userSignedUp.value, "user.signed_up")
        XCTAssertEqual(EventName.orderCompleted.value, "order.completed")
        XCTAssertEqual(EventName.subscriptionStarted.value, "subscription.started")
        XCTAssertEqual(EventName.featureUsed.value, "feature.used")
    }

    func testEventNameCustom() {
        let customEvent = EventName.custom("my_custom_event")
        XCTAssertEqual(customEvent.value, "my_custom_event")

        let customEvent2 = EventName.custom("button.clicked.signup")
        XCTAssertEqual(customEvent2.value, "button.clicked.signup")
    }

    func testEventNameCategory() {
        XCTAssertEqual(EventName.userSignedUp.category, .user)
        XCTAssertEqual(EventName.orderCompleted.category, .revenue)
        XCTAssertEqual(EventName.subscriptionStarted.category, .subscription)
        XCTAssertEqual(EventName.custom("test").category, .custom)
    }

    // MARK: - Currency Tests

    func testCurrencyCreation() {
        let usd = Currency.USD
        XCTAssertEqual(usd.code, "USD")
        XCTAssertEqual(usd.symbol, "$")
        XCTAssertEqual(usd.name, "US Dollar")

        let customCurrency = Currency("BTC")
        XCTAssertEqual(customCurrency.code, "BTC")
    }

    func testCurrencyValidation() {
        XCTAssertTrue(Currency.USD.isValid)
        XCTAssertTrue(Currency.EUR.isValid)
        XCTAssertTrue(Currency.GBP.isValid)

        let invalid = Currency("INVALID")
        XCTAssertFalse(invalid.isValid)
    }

    // MARK: - Revenue Tests

    func testRevenueCreation() {
        let revenue = Revenue(
            userID: "user_123",
            amount: 99.99,
            currency: .USD,
            products: [
                Product(
                    id: "product_1",
                    name: "Premium Plan",
                    price: 99.99,
                    currency: .USD
                )
            ]
        )

        XCTAssertEqual(revenue.userID, "user_123")
        XCTAssertEqual(revenue.amount, 99.99)
        XCTAssertEqual(revenue.currency, .USD)
        XCTAssertEqual(revenue.products.count, 1)
        XCTAssertEqual(revenue.products[0].name, "Premium Plan")
    }

    func testRevenueValidation() {
        // Test negative amount
        let invalidRevenue = Revenue(
            userID: "user_123",
            amount: -10.0,
            currency: .USD
        )

        XCTAssertThrowsError(try invalidRevenue.validate()) { error in
            XCTAssertTrue(error is UserCanalError)
        }

        // Test valid revenue
        let validRevenue = Revenue(
            userID: "user_123",
            amount: 10.0,
            currency: .USD
        )

        XCTAssertNoThrow(try validRevenue.validate())
    }

    // MARK: - Identity Tests

    func testIdentityCreation() {
        let identity = Identity(
            userID: "user_123",
            traits: Properties([
                "name": "John Doe",
                "email": "john@example.com",
                "plan": "premium"
            ])
        )

        XCTAssertEqual(identity.userID, "user_123")
        XCTAssertEqual(identity.traits["name"] as? String, "John Doe")
        XCTAssertEqual(identity.traits["email"] as? String, "john@example.com")
        XCTAssertEqual(identity.traits["plan"] as? String, "premium")
    }

    func testIdentityValidation() {
        // Test empty user ID
        let invalidIdentity = Identity(
            userID: "",
            traits: Properties()
        )

        XCTAssertThrowsError(try invalidIdentity.validate()) { error in
            XCTAssertTrue(error is UserCanalError)
        }

        // Test valid identity
        let validIdentity = Identity(
            userID: "valid_user",
            traits: Properties(["key": "value"])
        )

        XCTAssertNoThrow(try validIdentity.validate())
    }

    // MARK: - GroupInfo Tests

    func testGroupInfoCreation() {
        let group = GroupInfo(
            userID: "user_123",
            groupID: "company_456",
            properties: Properties([
                "company_name": "ACME Corp",
                "industry": "Technology"
            ])
        )

        XCTAssertEqual(group.userID, "user_123")
        XCTAssertEqual(group.groupID, "company_456")
        XCTAssertEqual(group.properties["company_name"] as? String, "ACME Corp")
        XCTAssertEqual(group.properties["industry"] as? String, "Technology")
    }

    func testGroupInfoValidation() {
        // Test empty group ID
        let invalidGroup = GroupInfo(
            userID: "user_123",
            groupID: "",
            properties: Properties()
        )

        XCTAssertThrowsError(try invalidGroup.validate()) { error in
            XCTAssertTrue(error is UserCanalError)
        }

        // Test valid group
        let validGroup = GroupInfo(
            userID: "user_123",
            groupID: "group_456",
            properties: Properties()
        )

        XCTAssertNoThrow(try validGroup.validate())
    }
}
