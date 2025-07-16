// EventDomainTests.swift
// UserCanal Swift SDK Tests
//
// Copyright © 2024 UserCanal. All rights reserved.
//

import XCTest
@testable import UserCanal

final class EventDomainTests: XCTestCase {
    
    // MARK: - Event Structure Tests
    
    func testEventCreation() {
        let event = Event(
            userID: "user123",
            name: .userSignedUp,
            properties: Properties([
                "source": "organic",
                "plan": "free"
            ])
        )
        
        XCTAssertFalse(event.id.isEmpty)
        XCTAssertEqual(event.userID, "user123")
        XCTAssertEqual(event.name, .userSignedUp)
        XCTAssertEqual(event.properties["source"] as? String, "organic")
        XCTAssertEqual(event.properties["plan"] as? String, "free")
        XCTAssertNotNil(event.timestamp)
    }
    
    func testEventCreationWithCustomID() {
        let customID = "custom_event_123"
        let event = Event(
            id: customID,
            userID: "user456",
            name: .pageViewed,
            properties: Properties(["page": "dashboard"])
        )
        
        XCTAssertEqual(event.id, customID)
        XCTAssertEqual(event.userID, "user456")
        XCTAssertEqual(event.name, .pageViewed)
    }
    
    func testEventCreationWithCustomTimestamp() {
        let customTimestamp = Date(timeIntervalSince1970: 1234567890)
        let event = Event(
            userID: "user789",
            name: .featureUsed,
            timestamp: customTimestamp
        )
        
        XCTAssertEqual(event.timestamp, customTimestamp)
    }
    
    // MARK: - Event Validation Tests
    
    func testEventValidationSuccess() {
        let event = Event(
            userID: "user123",
            name: .userSignedUp,
            properties: Properties(["key": "value"])
        )
        
        XCTAssertNoThrow(try event.validate())
    }
    
    func testEventValidationEmptyUserID() {
        let event = Event(
            userID: "",
            name: .userSignedUp
        )
        
        XCTAssertThrowsError(try event.validate()) { error in
            if case UserCanalError.validationError(let field, let reason) = error {
                XCTAssertEqual(field, "userID")
                XCTAssertTrue(reason.contains("cannot be empty"))
            } else {
                XCTFail("Expected validation error for empty userID")
            }
        }
    }
    
    func testEventValidationEmptyID() {
        let event = Event(
            id: "",
            userID: "user123",
            name: .userSignedUp
        )
        
        XCTAssertThrowsError(try event.validate()) { error in
            if case UserCanalError.validationError(let field, let reason) = error {
                XCTAssertEqual(field, "id")
                XCTAssertTrue(reason.contains("cannot be empty"))
            } else {
                XCTFail("Expected validation error for empty ID")
            }
        }
    }
    
    func testEventValidationFutureTimestamp() {
        let futureTimestamp = Date().addingTimeInterval(600) // 10 minutes in future
        let event = Event(
            userID: "user123",
            name: .userSignedUp,
            timestamp: futureTimestamp
        )
        
        XCTAssertThrowsError(try event.validate()) { error in
            if case UserCanalError.validationError(let field, let reason) = error {
                XCTAssertEqual(field, "timestamp")
                XCTAssertTrue(reason.contains("cannot be more than 5 minutes in the future"))
            } else {
                XCTFail("Expected validation error for future timestamp")
            }
        }
    }
    
    func testEventValidationNearFutureTimestamp() {
        let nearFutureTimestamp = Date().addingTimeInterval(240) // 4 minutes in future
        let event = Event(
            userID: "user123",
            name: .userSignedUp,
            timestamp: nearFutureTimestamp
        )
        
        XCTAssertNoThrow(try event.validate()) // Should be within 5 minute tolerance
    }
    
    // MARK: - Identity Tests
    
    func testIdentityCreation() {
        let identity = Identity(
            userID: "user123",
            properties: Properties([
                "name": "John Doe",
                "email": "john@example.com",
                "plan": "premium"
            ])
        )
        
        XCTAssertEqual(identity.userID, "user123")
        XCTAssertEqual(identity.properties["name"] as? String, "John Doe")
        XCTAssertEqual(identity.properties["email"] as? String, "john@example.com")
        XCTAssertEqual(identity.properties["plan"] as? String, "premium")
        XCTAssertNotNil(identity.timestamp)
    }
    
    func testIdentityValidation() {
        let identity = Identity(
            userID: "user123",
            properties: Properties(["name": "John"])
        )
        
        XCTAssertNoThrow(try identity.validate())
    }
    
    func testIdentityValidationEmptyUserID() {
        let identity = Identity(
            userID: "",
            properties: Properties(["name": "John"])
        )
        
        XCTAssertThrowsError(try identity.validate()) { error in
            if case UserCanalError.validationError(let field, let reason) = error {
                XCTAssertEqual(field, "userID")
                XCTAssertTrue(reason.contains("cannot be empty"))
            } else {
                XCTFail("Expected validation error for empty userID")
            }
        }
    }
    
    // MARK: - GroupInfo Tests
    
    func testGroupInfoCreation() {
        let groupInfo = GroupInfo(
            userID: "user123",
            groupID: "company456",
            properties: Properties([
                "company_name": "ACME Corp",
                "industry": "Technology"
            ])
        )
        
        XCTAssertEqual(groupInfo.userID, "user123")
        XCTAssertEqual(groupInfo.groupID, "company456")
        XCTAssertEqual(groupInfo.properties["company_name"] as? String, "ACME Corp")
        XCTAssertEqual(groupInfo.properties["industry"] as? String, "Technology")
    }
    
    func testGroupInfoValidation() {
        let groupInfo = GroupInfo(
            userID: "user123",
            groupID: "group456"
        )
        
        XCTAssertNoThrow(try groupInfo.validate())
    }
    
    func testGroupInfoValidationEmptyUserID() {
        let groupInfo = GroupInfo(
            userID: "",
            groupID: "group456"
        )
        
        XCTAssertThrowsError(try groupInfo.validate()) { error in
            if case UserCanalError.validationError(let field, let reason) = error {
                XCTAssertEqual(field, "userID")
                XCTAssertTrue(reason.contains("cannot be empty"))
            } else {
                XCTFail("Expected validation error for empty userID")
            }
        }
    }
    
    func testGroupInfoValidationEmptyGroupID() {
        let groupInfo = GroupInfo(
            userID: "user123",
            groupID: ""
        )
        
        XCTAssertThrowsError(try groupInfo.validate()) { error in
            if case UserCanalError.validationError(let field, let reason) = error {
                XCTAssertEqual(field, "groupID")
                XCTAssertTrue(reason.contains("cannot be empty"))
            } else {
                XCTFail("Expected validation error for empty groupID")
            }
        }
    }
    
    // MARK: - Revenue Tests
    
    func testRevenueCreation() {
        let revenue = Revenue(
            userID: "user123",
            orderID: "order456",
            amount: 99.99,
            currency: .USD,
            type: .oneTime,
            products: [],
            properties: Properties([
                "payment_method": "credit_card"
            ])
        )
        
        XCTAssertEqual(revenue.userID, "user123")
        XCTAssertEqual(revenue.orderID, "order456")
        XCTAssertEqual(revenue.amount, 99.99, accuracy: 0.001)
        XCTAssertEqual(revenue.currency, .USD)
        XCTAssertEqual(revenue.type, .oneTime)
        XCTAssertTrue(revenue.products.isEmpty)
        XCTAssertEqual(revenue.properties["payment_method"] as? String, "credit_card")
    }
    
    func testRevenueCreationWithProducts() {
        let product = Product(
            id: "prod123",
            name: "Premium Plan",
            price: 29.99,
            quantity: 1
        )
        
        let revenue = Revenue(
            userID: "user123",
            orderID: "order456",
            amount: 29.99,
            currency: .USD,
            products: [product]
        )
        
        XCTAssertEqual(revenue.products.count, 1)
        XCTAssertEqual(revenue.products.first?.id, "prod123")
        XCTAssertEqual(revenue.products.first?.name, "Premium Plan")
    }
    
    func testRevenueValidation() {
        let revenue = Revenue(
            userID: "user123",
            orderID: "order456",
            amount: 99.99,
            currency: .USD
        )
        
        XCTAssertNoThrow(try revenue.validate())
    }
    
    func testRevenueValidationEmptyUserID() {
        let revenue = Revenue(
            userID: "",
            orderID: "order456",
            amount: 99.99,
            currency: .USD
        )
        
        XCTAssertThrowsError(try revenue.validate()) { error in
            if case UserCanalError.validationError(let field, let reason) = error {
                XCTAssertEqual(field, "userID")
                XCTAssertTrue(reason.contains("cannot be empty"))
            } else {
                XCTFail("Expected validation error for empty userID")
            }
        }
    }
    
    func testRevenueValidationEmptyOrderID() {
        let revenue = Revenue(
            userID: "user123",
            orderID: "",
            amount: 99.99,
            currency: .USD
        )
        
        XCTAssertThrowsError(try revenue.validate()) { error in
            if case UserCanalError.validationError(let field, let reason) = error {
                XCTAssertEqual(field, "orderID")
                XCTAssertTrue(reason.contains("cannot be empty"))
            } else {
                XCTFail("Expected validation error for empty orderID")
            }
        }
    }
    
    func testRevenueValidationNegativeAmount() {
        let revenue = Revenue(
            userID: "user123",
            orderID: "order456",
            amount: -10.0,
            currency: .USD
        )
        
        XCTAssertThrowsError(try revenue.validate()) { error in
            if case UserCanalError.validationError(let field, let reason) = error {
                XCTAssertEqual(field, "amount")
                XCTAssertTrue(reason.contains("cannot be negative"))
            } else {
                XCTFail("Expected validation error for negative amount")
            }
        }
    }
    
    func testRevenueValidationZeroAmount() {
        let revenue = Revenue(
            userID: "user123",
            orderID: "order456",
            amount: 0.0,
            currency: .USD
        )
        
        XCTAssertNoThrow(try revenue.validate()) // Zero amount should be valid
    }
    
    // MARK: - Product Tests
    
    func testProductCreation() {
        let product = Product(
            id: "prod123",
            name: "Premium Subscription",
            price: 29.99,
            quantity: 2,
            properties: Properties([
                "category": "subscription",
                "billing_cycle": "monthly"
            ])
        )
        
        XCTAssertEqual(product.id, "prod123")
        XCTAssertEqual(product.name, "Premium Subscription")
        XCTAssertEqual(product.price, 29.99, accuracy: 0.001)
        XCTAssertEqual(product.quantity, 2)
        XCTAssertEqual(product.properties["category"] as? String, "subscription")
        XCTAssertEqual(product.properties["billing_cycle"] as? String, "monthly")
    }
    
    func testProductTotalValue() {
        let product = Product(
            id: "prod123",
            name: "Widget",
            price: 15.50,
            quantity: 3
        )
        
        XCTAssertEqual(product.totalValue, 46.50, accuracy: 0.001)
    }
    
    func testProductValidation() {
        let product = Product(
            id: "prod123",
            name: "Test Product",
            price: 10.0,
            quantity: 1
        )
        
        XCTAssertNoThrow(try product.validate())
    }
    
    func testProductValidationEmptyID() {
        let product = Product(
            id: "",
            name: "Test Product",
            price: 10.0
        )
        
        XCTAssertThrowsError(try product.validate()) { error in
            if case UserCanalError.validationError(let field, let reason) = error {
                XCTAssertEqual(field, "id")
                XCTAssertTrue(reason.contains("cannot be empty"))
            } else {
                XCTFail("Expected validation error for empty ID")
            }
        }
    }
    
    func testProductValidationEmptyName() {
        let product = Product(
            id: "prod123",
            name: "",
            price: 10.0
        )
        
        XCTAssertThrowsError(try product.validate()) { error in
            if case UserCanalError.validationError(let field, let reason) = error {
                XCTAssertEqual(field, "name")
                XCTAssertTrue(reason.contains("cannot be empty"))
            } else {
                XCTFail("Expected validation error for empty name")
            }
        }
    }
    
    func testProductValidationNegativePrice() {
        let product = Product(
            id: "prod123",
            name: "Test Product",
            price: -5.0
        )
        
        XCTAssertThrowsError(try product.validate()) { error in
            if case UserCanalError.validationError(let field, let reason) = error {
                XCTAssertEqual(field, "price")
                XCTAssertTrue(reason.contains("cannot be negative"))
            } else {
                XCTFail("Expected validation error for negative price")
            }
        }
    }
    
    func testProductValidationZeroQuantity() {
        let product = Product(
            id: "prod123",
            name: "Test Product",
            price: 10.0,
            quantity: 0
        )
        
        XCTAssertThrowsError(try product.validate()) { error in
            if case UserCanalError.validationError(let field, let reason) = error {
                XCTAssertEqual(field, "quantity")
                XCTAssertTrue(reason.contains("must be positive"))
            } else {
                XCTFail("Expected validation error for zero quantity")
            }
        }
    }
    
    func testProductValidationNegativeQuantity() {
        let product = Product(
            id: "prod123",
            name: "Test Product",
            price: 10.0,
            quantity: -1
        )
        
        XCTAssertThrowsError(try product.validate()) { error in
            if case UserCanalError.validationError(let field, let reason) = error {
                XCTAssertEqual(field, "quantity")
                XCTAssertTrue(reason.contains("must be positive"))
            } else {
                XCTFail("Expected validation error for negative quantity")
            }
        }
    }
    
    // MARK: - LogEntry Tests
    
    func testLogEntryCreation() {
        let logEntry = LogEntry(
            level: .info,
            service: "payment-service",
            message: "Payment processed successfully",
            data: Properties([
                "payment_id": "pay_123",
                "amount": 29.99
            ])
        )
        
        XCTAssertEqual(logEntry.level, .info)
        XCTAssertEqual(logEntry.service, "payment-service")
        XCTAssertEqual(logEntry.message, "Payment processed successfully")
        XCTAssertEqual(logEntry.data["payment_id"] as? String, "pay_123")
        XCTAssertEqual(logEntry.data["amount"] as? Double, 29.99)
        XCTAssertEqual(logEntry.eventType, .collect) // Default event type
    }
    
    func testLogEntryWithCustomEventType() {
        let logEntry = LogEntry(
            eventType: .enrich,
            level: .debug,
            service: "analytics",
            message: "Event enriched"
        )
        
        XCTAssertEqual(logEntry.eventType, .enrich)
        XCTAssertEqual(logEntry.level, .debug)
    }
    
    func testLogEntryValidation() {
        let logEntry = LogEntry(
            level: .info,
            service: "test-service",
            message: "Test message"
        )
        
        XCTAssertNoThrow(try logEntry.validate())
    }
    
    func testLogEntryValidationEmptyService() {
        let logEntry = LogEntry(
            level: .info,
            service: "",
            message: "Test message"
        )
        
        XCTAssertThrowsError(try logEntry.validate()) { error in
            if case UserCanalError.validationError(let field, let reason) = error {
                XCTAssertEqual(field, "service")
                XCTAssertTrue(reason.contains("cannot be empty"))
            } else {
                XCTFail("Expected validation error for empty service")
            }
        }
    }
    
    func testLogEntryValidationEmptyMessage() {
        let logEntry = LogEntry(
            level: .info,
            service: "test-service",
            message: ""
        )
        
        XCTAssertThrowsError(try logEntry.validate()) { error in
            if case UserCanalError.validationError(let field, let reason) = error {
                XCTAssertEqual(field, "message")
                XCTAssertTrue(reason.contains("cannot be empty"))
            } else {
                XCTFail("Expected validation error for empty message")
            }
        }
    }
    
    func testLogEntryValidationEmptySource() {
        let logEntry = LogEntry(
            level: .info,
            source: "",
            service: "test-service",
            message: "Test message"
        )
        
        XCTAssertThrowsError(try logEntry.validate()) { error in
            if case UserCanalError.validationError(let field, let reason) = error {
                XCTAssertEqual(field, "source")
                XCTAssertTrue(reason.contains("cannot be empty"))
            } else {
                XCTFail("Expected validation error for empty source")
            }
        }
    }
    
    // MARK: - Complex Validation Tests
    
    func testRevenueWithInvalidProducts() {
        let invalidProduct = Product(
            id: "prod123",
            name: "",  // Invalid: empty name
            price: 10.0
        )
        
        let revenue = Revenue(
            userID: "user123",
            orderID: "order456",
            amount: 10.0,
            currency: .USD,
            products: [invalidProduct]
        )
        
        XCTAssertThrowsError(try revenue.validate()) { error in
            if case UserCanalError.validationError(let field, _) = error {
                XCTAssertTrue(field.contains("products[0]"))
            } else {
                XCTFail("Expected validation error for invalid product")
            }
        }
    }
    
    func testRevenueWithMultipleProducts() throws {
        let product1 = Product(id: "prod1", name: "Product 1", price: 10.0)
        let product2 = Product(id: "prod2", name: "Product 2", price: 20.0, quantity: 2)
        
        let revenue = Revenue(
            userID: "user123",
            orderID: "order456",
            amount: 50.0,
            currency: .USD,
            products: [product1, product2]
        )
        
        XCTAssertNoThrow(try revenue.validate())
        XCTAssertEqual(revenue.products.count, 2)
        XCTAssertEqual(product2.totalValue, 40.0, accuracy: 0.001)
    }
    
    // MARK: - Codable Tests
    
    func testEventCodable() throws {
        let event = Event(
            userID: "user123",
            name: .userSignedUp,
            properties: Properties([
                "source": "organic",
                "count": 1
            ])
        )
        
        let encoded = try JSONEncoder().encode(event)
        let decoded = try JSONDecoder().decode(Event.self, from: encoded)
        
        XCTAssertEqual(decoded.id, event.id)
        XCTAssertEqual(decoded.userID, event.userID)
        XCTAssertEqual(decoded.name, event.name)
        XCTAssertEqual(decoded.properties["source"] as? String, "organic")
        XCTAssertEqual(decoded.properties["count"] as? Int, 1)
    }
    
    func testProductCodable() throws {
        let product = Product(
            id: "prod123",
            name: "Test Product",
            price: 29.99,
            quantity: 2
        )
        
        let encoded = try JSONEncoder().encode(product)
        let decoded = try JSONDecoder().decode(Product.self, from: encoded)
        
        XCTAssertEqual(decoded.id, product.id)
        XCTAssertEqual(decoded.name, product.name)
        XCTAssertEqual(decoded.price, product.price, accuracy: 0.001)
        XCTAssertEqual(decoded.quantity, product.quantity)
    }
    
    // MARK: - Description Tests
    
    func testEventDescription() {
        let event = Event(
            id: "event123",
            userID: "user456",
            name: .userSignedUp
        )
        
        let description = event.description
        XCTAssertTrue(description.contains("event123"))
        XCTAssertTrue(description.contains("user456"))
        XCTAssertTrue(description.contains("userSignedUp"))
    }
    
    func testProductDescription() {
        let product = Product(
            id: "prod123",
            name: "Test Product",
            price: 10.0,
            quantity: 2
        )
        
        let description = product.description
        XCTAssertTrue(description.contains("prod123"))
        XCTAssertTrue(description.contains("Test Product"))
        XCTAssertTrue(description.contains("10.0"))
        XCTAssertTrue(description.contains("2"))
    }
}