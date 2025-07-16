// Properties.swift
// UserCanal Swift SDK
//
// Copyright © 2024 UserCanal. All rights reserved.
//

import Foundation

// MARK: - Properties Type

/// A type-safe property collection for events and logs
/// Equivalent to Go SDK's `Properties map[string]interface{}`
public struct Properties: Sendable {
    
    // MARK: - Storage
    
    internal let storage: [String: PropertyValue]
    
    // MARK: - Initialization
    
    /// Create empty properties
    public init() {
        self.storage = [:]
    }
    
    /// Create properties from a dictionary
    public init(_ dictionary: [String: Any]) {
        var storage: [String: PropertyValue] = [:]
        for (key, value) in dictionary {
            storage[key] = PropertyValue(value)
        }
        self.storage = storage
    }
    
    /// Create properties from Sendable values
    public init(sendable dictionary: [String: any Sendable]) {
        var storage: [String: PropertyValue] = [:]
        for (key, value) in dictionary {
            storage[key] = PropertyValue(sendable: value)
        }
        self.storage = storage
    }
    
    // MARK: - Dictionary Literal Support
    
    /// Create properties from dictionary literal
    public init(dictionaryLiteral elements: (String, Any)...) {
        var storage: [String: PropertyValue] = [:]
        for (key, value) in elements {
            storage[key] = PropertyValue(value)
        }
        self.storage = storage
    }
    
    // MARK: - Subscript Access
    
    /// Access properties by key
    public subscript(key: String) -> Any? {
        get {
            return storage[key]?.value
        }
        set {
            // Properties is immutable - use builder pattern for modifications
        }
    }
    
    // MARK: - Property Access
    
    /// Get a property value as a specific type
    public func value<T>(for key: String, as type: T.Type) -> T? {
        return storage[key]?.value as? T
    }
    
    /// Get a string property
    public func string(for key: String) -> String? {
        return value(for: key, as: String.self)
    }
    
    /// Get an integer property
    public func int(for key: String) -> Int? {
        return value(for: key, as: Int.self)
    }
    
    /// Get a double property
    public func double(for key: String) -> Double? {
        return value(for: key, as: Double.self)
    }
    
    /// Get a boolean property
    public func bool(for key: String) -> Bool? {
        return value(for: key, as: Bool.self)
    }
    
    /// Get a date property
    public func date(for key: String) -> Date? {
        return value(for: key, as: Date.self)
    }
    
    /// Get an array property
    public func array(for key: String) -> [Any]? {
        return value(for: key, as: [Any].self)
    }
    
    /// Get a nested properties object
    public func properties(for key: String) -> Properties? {
        if let dict = value(for: key, as: [String: Any].self) {
            return Properties(dict)
        }
        return nil
    }
    
    // MARK: - Property Information
    
    /// All property keys
    public var keys: Set<String> {
        Set(storage.keys)
    }
    
    /// Number of properties
    public var count: Int {
        storage.count
    }
    
    /// Whether properties is empty
    public var isEmpty: Bool {
        storage.isEmpty
    }
    
    /// Check if a key exists
    public func contains(_ key: String) -> Bool {
        storage.keys.contains(key)
    }
    
    // MARK: - Conversion
    
    /// Convert to dictionary
    public var dictionary: [String: Any] {
        var result: [String: Any] = [:]
        for (key, propertyValue) in storage {
            result[key] = propertyValue.value
        }
        return result
    }
    
    /// Convert to JSON data
    public var jsonData: Data? {
        try? JSONSerialization.data(withJSONObject: dictionary, options: [])
    }
    
    /// Convert to JSON string
    public var jsonString: String? {
        guard let data = jsonData else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

// MARK: - Properties Builder

/// Property wrapper for building properties with a DSL-like syntax
@resultBuilder
public struct PropertiesBuilder {
    
    public static func buildBlock(_ properties: Properties...) -> Properties {
        var result = Properties()
        for prop in properties {
            result = result.modified { builder in
                builder.merge(with: prop)
            }
        }
        return result
    }
    
    public static func buildOptional(_ properties: Properties?) -> Properties {
        return properties ?? Properties()
    }
    
    public static func buildEither(first properties: Properties) -> Properties {
        return properties
    }
    
    public static func buildEither(second properties: Properties) -> Properties {
        return properties
    }
    
    public static func buildArray(_ properties: [Properties]) -> Properties {
        var result = Properties()
        for prop in properties {
            result = result.modified { builder in
                builder.merge(with: prop)
            }
        }
        return result
    }
    
    public static func buildExpression(_ properties: Properties) -> Properties {
        return properties
    }
    
    public static func buildExpression(_ keyValue: (String, Any)) -> Properties {
        return Properties([keyValue.0: keyValue.1])
    }
    
    public static func buildExpression(_ dictionary: [String: Any]) -> Properties {
        return Properties(dictionary)
    }
}

/// Builder for creating and modifying properties
public struct PropertiesModifier: Sendable {
    private var storage: [String: PropertyValue] = [:]
    
    public init() {}
    
    public init(from properties: Properties) {
        self.storage = properties.storage
    }
    
    /// Set a property value
    public func set(_ key: String, _ value: Any) -> Self {
        var copy = self
        copy.storage[key] = PropertyValue(value)
        return copy
    }
    
    /// Set a Sendable property value
    public func set(_ key: String, sendable value: any Sendable) -> Self {
        var copy = self
        copy.storage[key] = PropertyValue(sendable: value)
        return copy
    }
    
    /// Merge with another Properties object
    public func merge(with properties: Properties) -> Self {
        var copy = self
        for (key, value) in properties.storage {
            copy.storage[key] = value
        }
        return copy
    }
    
    /// Remove a property
    public func remove(_ key: String) -> Self {
        var copy = self
        copy.storage.removeValue(forKey: key)
        return copy
    }
    
    /// Build the final Properties object
    public func build() -> Properties {
        return Properties(storage: storage)
    }
}

// MARK: - Property Value Wrapper

/// Internal wrapper for property values that maintains type safety
public struct PropertyValue: Sendable {
    let value: any Sendable
    
    init(_ value: Any) {
        // Convert common non-Sendable types to Sendable equivalents
        switch value {
        case let date as Date:
            self.value = date
        case let string as String:
            self.value = string
        case let int as Int:
            self.value = int
        case let double as Double:
            self.value = double
        case let float as Float:
            self.value = Double(float)
        case let bool as Bool:
            self.value = bool
        case let array as [Any]:
            self.value = array.map { PropertyValue($0).value }
        case let dict as [String: Any]:
            var sendableDict: [String: Any] = [:]
            for (key, val) in dict {
                sendableDict[key] = PropertyValue(val).value
            }
            // Store as dictionary of Sendable values
            var convertedDict: [String: any Sendable] = [:]
            for (key, val) in dict {
                convertedDict[key] = PropertyValue(val).value
            }
            self.value = convertedDict
        case let sendable as any Sendable:
            self.value = sendable
        default:
            // Convert unknown types to string representation
            self.value = String(describing: value)
        }
    }
    
    init(sendable value: any Sendable) {
        self.value = value
    }
}

// MARK: - Properties Extensions

extension Properties {
    
    /// Internal initializer for builder
    fileprivate init(storage: [String: PropertyValue]) {
        self.storage = storage
    }
    
    /// Create properties with builder pattern
    public static func build(_ builder: (PropertiesModifier) -> PropertiesModifier) -> Properties {
        return builder(PropertiesModifier()).build()
    }
    
    /// Modify existing properties
    public func modified(_ builder: (PropertiesModifier) -> PropertiesModifier) -> Properties {
        return builder(PropertiesModifier(from: self)).build()
    }
}

// MARK: - ExpressibleByDictionaryLiteral

extension Properties: ExpressibleByDictionaryLiteral {
    public typealias Key = String
    public typealias Value = Any
}

// MARK: - Collection Conformance

extension Properties: Collection {
    public typealias Index = Dictionary<String, PropertyValue>.Index
    public typealias Element = (key: String, value: Any)
    
    public var startIndex: Index {
        storage.startIndex
    }
    
    public var endIndex: Index {
        storage.endIndex
    }
    
    public subscript(position: Index) -> Element {
        let (key, propertyValue) = storage[position]
        return (key: key, value: propertyValue.value)
    }
    
    public func index(after i: Index) -> Index {
        storage.index(after: i)
    }
}

// MARK: - Sequence Conformance

extension Properties: Sequence {
    public func makeIterator() -> AnyIterator<Element> {
        var iterator = storage.makeIterator()
        return AnyIterator {
            guard let (key, propertyValue) = iterator.next() else { return nil }
            return (key: key, value: propertyValue.value)
        }
    }
}

// MARK: - Codable Support

extension Properties: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let dictionary = try container.decode([String: AnyCodable].self)
        
        var storage: [String: PropertyValue] = [:]
        for (key, value) in dictionary {
            storage[key] = PropertyValue(value.value)
        }
        self.storage = storage
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        var codableDict: [String: AnyCodable] = [:]
        
        for (key, propertyValue) in storage {
            codableDict[key] = AnyCodable(propertyValue.value)
        }
        
        try container.encode(codableDict)
    }
}

// MARK: - AnyCodable Helper

private struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Cannot decode value"
                )
            )
        }
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            let codableArray = array.map { AnyCodable($0) }
            try container.encode(codableArray)
        case let dict as [String: Any]:
            let codableDict = dict.mapValues { AnyCodable($0) }
            try container.encode(codableDict)
        default:
            let string = String(describing: value)
            try container.encode(string)
        }
    }
}

// MARK: - CustomStringConvertible

extension Properties: CustomStringConvertible {
    public var description: String {
        return jsonString ?? "Properties(invalid)"
    }
}

// MARK: - Equatable

extension Properties: Equatable {
    public static func == (lhs: Properties, rhs: Properties) -> Bool {
        guard lhs.count == rhs.count else { return false }
        
        for key in lhs.keys {
            guard rhs.contains(key) else { return false }
            
            // Simple equality check - could be enhanced for complex types
            let lhsValue = String(describing: lhs[key] ?? "nil")
            let rhsValue = String(describing: rhs[key] ?? "nil")
            if lhsValue != rhsValue {
                return false
            }
        }
        
        return true
    }
}

// MARK: - Hashable

extension Properties: Hashable {
    public func hash(into hasher: inout Hasher) {
        // Hash based on sorted keys and string representations
        let sortedKeys = keys.sorted()
        hasher.combine(sortedKeys)
        
        for key in sortedKeys {
            hasher.combine(String(describing: self[key] ?? "nil"))
        }
    }
}