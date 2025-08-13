// Event.swift
// UserCanal Swift SDK
//
// Copyright © 2024 UserCanal. All rights reserved.
//

import Foundation

// MARK: - Event Types for CDP

/// Event types for different processing paths in the CDP
public enum EventType: UInt8, Sendable, CaseIterable, Codable {
    case unknown = 0
    case track = 1      // User action tracking (page views, clicks, etc.)
    case identify = 2   // User identification/traits updates
    case group = 3      // Group membership/traits updates
    case alias = 4      // Identity resolution/user merging
    case enrich = 5     // Generic entity enrichment
    case context = 6    // Session/device context updates
}

// MARK: - Event

/// Represents a tracking event in the UserCanal system
public struct Event: Sendable {

    // MARK: - Properties

    /// Unique identifier for this event (auto-generated if not provided)
    public let id: String

    /// User ID associated with this event
    public let userID: String

    /// Event name/type
    public let name: EventName

    /// Event type for CDP processing
    public let eventType: EventType

    /// Additional properties/metadata for the event
    public let properties: Properties

    /// Timestamp when the event occurred
    public let timestamp: Date

    // MARK: - Initialization

    /// Create a new event
    public init(
        id: String? = nil,
        userID: String,
        name: EventName,
        eventType: EventType = .track,
        properties: Properties = Properties(),
        timestamp: Date = Date(),
        generateId: Bool = true
    ) {
        self.id = id ?? (generateId ? UUID().uuidString : "")
        self.userID = userID
        self.name = name
        self.eventType = eventType
        self.properties = properties
        self.timestamp = timestamp
    }

    /// Create an event with property builder
    public init(
        id: String? = nil,
        userID: String,
        name: EventName,
        eventType: EventType = .track,
        @PropertiesBuilder properties: () -> Properties,
        timestamp: Date = Date(),
        generateId: Bool = true
    ) {
        self.id = id ?? (generateId ? UUID().uuidString : "")
        self.userID = userID
        self.name = name
        self.eventType = eventType
        self.properties = properties()
        self.timestamp = timestamp
    }
}

// MARK: - Identity

/// Represents a user identification event
public struct Identity: Sendable {

    // MARK: - Properties

    /// User ID being identified
    public let userID: String

    /// User traits/properties
    public let traits: Properties

    /// Timestamp when the identification occurred
    public let timestamp: Date

    // MARK: - Initialization

    /// Create a new identity event
    public init(
        userID: String,
        traits: Properties = Properties(),
        timestamp: Date = Date()
    ) {
        self.userID = userID
        self.traits = traits
        self.timestamp = timestamp
    }

    /// Create an identity with trait builder
    public init(
        userID: String,
        timestamp: Date = Date(),
        traits: () -> Properties
    ) {
        self.userID = userID
        self.timestamp = timestamp
        self.traits = traits()
    }
}

// MARK: - GroupInfo

/// Represents a group event for associating users with groups
public struct GroupInfo: Sendable {

    // MARK: - Properties

    /// User ID being associated with the group
    public let userID: String

    /// Group ID the user is being associated with
    public let groupID: String

    /// Group properties/metadata
    public let properties: Properties

    /// Timestamp when the group association occurred
    public let timestamp: Date

    // MARK: - Initialization

    /// Create a new group info event
    public init(
        userID: String,
        groupID: String,
        properties: Properties = Properties(),
        timestamp: Date = Date()
    ) {
        self.userID = userID
        self.groupID = groupID
        self.properties = properties
        self.timestamp = timestamp
    }

    /// Create a group info with property builder
    public init(
        userID: String,
        groupID: String,
        timestamp: Date = Date(),
        properties: () -> Properties
    ) {
        self.userID = userID
        self.groupID = groupID
        self.timestamp = timestamp
        self.properties = properties()
    }
}

// MARK: - Revenue

/// Represents a revenue event for tracking purchases and subscriptions
public struct Revenue: Sendable {

    // MARK: - Properties

    /// User ID making the purchase
    public let userID: String

    /// Order/transaction ID
    public let orderID: String

    /// Revenue amount
    public let amount: Double

    /// Currency code
    public let currency: Currency

    /// Type of revenue (one-time, subscription, etc.)
    public let type: RevenueType

    /// Products included in this revenue event
    public let products: [Product]

    /// Additional properties/metadata
    public let properties: Properties

    /// Timestamp when the revenue occurred
    public let timestamp: Date

    // MARK: - Initialization

    /// Create a new revenue event
    public init(
        userID: String,
        orderID: String,
        amount: Double,
        currency: Currency,
        type: RevenueType = .oneTime,
        products: [Product] = [],
        properties: Properties = Properties(),
        timestamp: Date = Date()
    ) {
        self.userID = userID
        self.orderID = orderID
        self.amount = amount
        self.currency = currency
        self.type = type
        self.products = products
        self.properties = properties
        self.timestamp = timestamp
    }

    /// Create a revenue event with property builder
    public init(
        userID: String,
        orderID: String,
        amount: Double,
        currency: Currency,
        type: RevenueType = .oneTime,
        products: [Product] = [],
        timestamp: Date = Date(),
        properties: () -> Properties
    ) {
        self.userID = userID
        self.orderID = orderID
        self.amount = amount
        self.currency = currency
        self.type = type
        self.products = products
        self.timestamp = timestamp
        self.properties = properties()
    }
}

// MARK: - Product

/// Represents a product in a revenue event
public struct Product: Sendable {

    // MARK: - Properties

    /// Product identifier
    public let id: String

    /// Product name
    public let name: String

    /// Product price (per unit)
    public let price: Double

    /// Quantity purchased
    public let quantity: Int

    /// Additional product properties
    public let properties: Properties

    // MARK: - Initialization

    /// Create a new product
    public init(
        id: String,
        name: String,
        price: Double,
        quantity: Int = 1,
        properties: Properties = Properties()
    ) {
        self.id = id
        self.name = name
        self.price = price
        self.quantity = quantity
        self.properties = properties
    }

    /// Create a product with property builder
    public init(
        id: String,
        name: String,
        price: Double,
        quantity: Int = 1,
        properties: () -> Properties
    ) {
        self.id = id
        self.name = name
        self.price = price
        self.quantity = quantity
        self.properties = properties()
    }

    // MARK: - Computed Properties

    /// Total value (price * quantity)
    public var totalValue: Double {
        price * Double(quantity)
    }
}

// MARK: - EventAdvanced

/// Represents an advanced tracking event with optional device/session ID overrides
/// Used when you need explicit control over device_id, session_id, or timestamp
public struct EventAdvanced: Sendable {

    // MARK: - Properties

    /// User ID associated with this event (required)
    public let userID: String

    /// Event name (required)
    public let name: EventName

    /// Additional properties/metadata for the event
    public let properties: Properties

    // MARK: - Advanced Optional Overrides

    /// Optional device ID override (16-byte UUID data)
    /// If nil, will use default device behavior
    public let deviceID: Data?

    /// Optional session ID override (16-byte UUID data)
    /// If nil, will use current session ID
    public let sessionID: Data?

    /// Optional custom timestamp override
    /// If nil, will use current timestamp
    public let timestamp: Date?

    // MARK: - Initialization

    /// Create a new advanced event
    public init(
        userID: String,
        name: EventName,
        properties: Properties = Properties(),
        deviceID: Data? = nil,
        sessionID: Data? = nil,
        timestamp: Date? = nil
    ) {
        self.userID = userID
        self.name = name
        self.properties = properties
        self.deviceID = deviceID
        self.sessionID = sessionID
        self.timestamp = timestamp
    }

    /// Create an advanced event with property builder
    public init(
        userID: String,
        name: EventName,
        deviceID: Data? = nil,
        sessionID: Data? = nil,
        timestamp: Date? = nil,
        @PropertiesBuilder properties: () -> Properties
    ) {
        self.userID = userID
        self.name = name
        self.properties = properties()
        self.deviceID = deviceID
        self.sessionID = sessionID
        self.timestamp = timestamp
    }
}

// MARK: - Validation Extensions

extension Event {
    /// Validate the event
    public func validate() throws {
        guard !userID.isEmpty else {
            throw UserCanalError.validationError(field: "userID", reason: "User ID cannot be empty")
        }

        guard !name.stringValue.isEmpty else {
            throw UserCanalError.validationError(field: "eventName", reason: "Event name cannot be empty")
        }

        // Event ID is optional and can be part of the payload - no validation required
    }
}

extension Identity {
    /// Validate the identity
    public func validate() throws {
        guard !userID.isEmpty else {
            throw UserCanalError.validationError(field: "userID", reason: "User ID cannot be empty")
        }
    }
}

extension GroupInfo {
    /// Validate the group info
    public func validate() throws {
        guard !userID.isEmpty else {
            throw UserCanalError.validationError(field: "userID", reason: "User ID cannot be empty")
        }

        guard !groupID.isEmpty else {
            throw UserCanalError.validationError(field: "groupID", reason: "Group ID cannot be empty")
        }
    }
}

extension Revenue {
    /// Validate the revenue
    public func validate() throws {
        guard !userID.isEmpty else {
            throw UserCanalError.validationError(field: "userID", reason: "User ID cannot be empty")
        }

        guard !orderID.isEmpty else {
            throw UserCanalError.validationError(field: "orderID", reason: "Order ID cannot be empty")
        }

        guard amount >= 0 else {
            throw UserCanalError.validationError(field: "amount", reason: "Amount cannot be negative")
        }

        // Validate all products
        for (index, product) in products.enumerated() {
            do {
                try product.validate()
            } catch {
                throw UserCanalError.validationError(field: "products[\(index)]", reason: "Invalid product: \(error.localizedDescription)")
            }
        }
    }
}

extension Product {
    /// Validate the product
    public func validate() throws {
        guard !id.isEmpty else {
            throw UserCanalError.validationError(field: "id", reason: "Product ID cannot be empty")
        }

        guard !name.isEmpty else {
            throw UserCanalError.validationError(field: "name", reason: "Product name cannot be empty")
        }

        guard price >= 0 else {
            throw UserCanalError.validationError(field: "price", reason: "Product price cannot be negative")
        }

        guard quantity > 0 else {
            throw UserCanalError.validationError(field: "quantity", reason: "Product quantity must be positive")
        }
    }
}

extension EventAdvanced {
    /// Validate the advanced event
    public func validate() throws {
        guard !userID.isEmpty else {
            throw UserCanalError.validationError(field: "userID", reason: "User ID cannot be empty")
        }

        guard !name.stringValue.isEmpty else {
            throw UserCanalError.validationError(field: "eventName", reason: "Event name cannot be empty")
        }

        // Validate device ID format if provided (should be 16 bytes)
        if let deviceID = deviceID {
            guard deviceID.count == 16 else {
                throw UserCanalError.validationError(field: "deviceID", reason: "Device ID must be exactly 16 bytes")
            }
        }

        // Validate session ID format if provided (should be 16 bytes)
        if let sessionID = sessionID {
            guard sessionID.count == 16 else {
                throw UserCanalError.validationError(field: "sessionID", reason: "Session ID must be exactly 16 bytes")
            }
        }
    }
}

// MARK: - Codable Conformance

extension Event: Codable {}
extension Identity: Codable {}
extension GroupInfo: Codable {}
extension Revenue: Codable {}
extension Product: Codable {}
extension EventAdvanced: Codable {}

// MARK: - CustomStringConvertible

extension Event: CustomStringConvertible {
    public var description: String {
        return "Event(id: \(id), userID: \(userID), name: \(name.stringValue), type: \(eventType), timestamp: \(timestamp))"
    }
}

extension Identity: CustomStringConvertible {
    public var description: String {
        return "Identity(userID: \(userID), timestamp: \(timestamp))"
    }
}

extension GroupInfo: CustomStringConvertible {
    public var description: String {
        return "GroupInfo(userID: \(userID), groupID: \(groupID), timestamp: \(timestamp))"
    }
}

extension Revenue: CustomStringConvertible {
    public var description: String {
        return "Revenue(userID: \(userID), orderID: \(orderID), amount: \(amount), currency: \(currency))"
    }
}

extension Product: CustomStringConvertible {
    public var description: String {
        return "Product(id: \(id), name: \(name), price: \(price), quantity: \(quantity))"
    }
}

extension EventAdvanced: CustomStringConvertible {
    public var description: String {
        let deviceInfo = deviceID != nil ? "deviceID: custom" : "deviceID: default"
        let sessionInfo = sessionID != nil ? "sessionID: custom" : "sessionID: default"
        let timestampInfo = timestamp != nil ? "timestamp: custom" : "timestamp: default"
        return "EventAdvanced(userID: \(userID), name: \(name.stringValue), \(deviceInfo), \(sessionInfo), \(timestampInfo))"
    }
}
