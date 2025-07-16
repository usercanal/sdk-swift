// FlatBuffersProtocol.swift
// UserCanal Swift SDK
//
// Copyright © 2024 UserCanal. All rights reserved.
//

import Foundation
import FlatBuffers

// MARK: - Schema Types (matching Go SDK)

/// Schema types for routing and streaming (matches common.fbs)
public enum SchemaType: UInt8 {
    case unknown = 0
    case event = 1
    case log = 2
    case metric = 3
    case inventory = 4
}

/// Event types for different processing paths (matches event.fbs)
public enum EventType: UInt8 {
    case unknown = 0
    case track = 1
    case identify = 2
    case group = 3
    case alias = 4
    case enrich = 5
}



/// Log severity levels (matches log.fbs RFC 5424 + TRACE)
public enum FBLogLevel: UInt8 {
    case emergency = 0
    case alert = 1
    case critical = 2
    case error = 3
    case warning = 4
    case notice = 5
    case info = 6
    case debug = 7
    case trace = 8
}

// MARK: - FlatBuffers Protocol Implementation

/// Handles FlatBuffers serialization matching the Go SDK schema exactly
public struct FlatBuffersProtocol {
    
    // MARK: - Constants
    
    private static let maxBatchSize = 10 * 1024 * 1024 // 10MB
    
    // MARK: - Public Interface
    
    /// Create a batch for events
    public static func createEventBatch(events: [Event], apiKey: Data) throws -> Data {
        let eventData = try serializeEvents(events)
        return try createBatch(apiKey: apiKey, schemaType: .event, data: eventData)
    }
    
    /// Create a batch for logs  
    public static func createLogBatch(logs: [LogEntry], apiKey: Data) throws -> Data {
        let logData = try serializeLogs(logs)
        return try createBatch(apiKey: apiKey, schemaType: .log, data: logData)
    }
    
    // MARK: - Batch Creation (Common Schema)
    
    /// Create a standard batch structure (matches Batch table in common.fbs)
    private static func createBatch(apiKey: Data, schemaType: SchemaType, data: Data) throws -> Data {
        var builder = FlatBufferBuilder(initialSize: 1024)
        
        // Generate simple incremental batch ID
        let batchID = UInt64(Date().timeIntervalSince1970 * 1000) // Use timestamp in milliseconds
        
        // Create byte vectors for api_key and data
        let apiKeyVector = builder.createVector(bytes: apiKey)
        let dataVector = builder.createVector(bytes: data)
        
        // Build Batch table (field IDs match common.fbs)
        let batchStart = builder.startTable(with: 4)
        builder.add(offset: apiKeyVector, at: 0)     // api_key (id: 0)
        builder.add(element: batchID, at: 1)         // batch_id (id: 1) 
        builder.add(element: schemaType.rawValue, at: 2) // schema_type (id: 2)
        builder.add(offset: dataVector, at: 3)       // data (id: 3)
        let batch = builder.endTable(at: batchStart)
        
        builder.finish(offset: Offset(offset: batch))
        
        // Extract data from ByteBuffer
        let result = Data(bytes: builder.sizedBuffer.memory.assumingMemoryBound(to: UInt8.self), 
                         count: Int(builder.sizedBuffer.size))
        
        // Validate batch size
        guard result.count <= maxBatchSize else {
            throw UserCanalError.validationError(
                field: "batch",
                reason: "Batch size \(result.count) exceeds maximum \(maxBatchSize)"
            )
        }
        
        return result
    }
    
    // MARK: - Event Serialization (Event Schema)
    
    /// Serialize events to EventData format (matches event.fbs)
    private static func serializeEvents(_ events: [Event]) throws -> Data {
        var builder = FlatBufferBuilder(initialSize: 1024)
        var eventOffsets: [Offset] = []
        
        for event in events {
            // Determine event type based on properties or name
            let eventType = determineEventType(for: event)
            
            // Serialize event payload (properties + metadata as JSON)
            let payload = try serializeEventPayload(event)
            let payloadVector = builder.createVector(bytes: payload)
            
            // Convert userID to 16-byte UUID format (pad or hash if needed)
            let userIDBytes = convertUserIDToBytes(event.userID)
            let userIDVector = builder.createVector(bytes: userIDBytes)
            
            // Convert timestamp to milliseconds
            let timestampMs = UInt64(event.timestamp.timeIntervalSince1970 * 1000)
            
            // Build Event table (field IDs match event.fbs)
            let eventStart = builder.startTable(with: 4)
            builder.add(element: timestampMs, at: 0)      // timestamp (id: 0)
            builder.add(element: eventType.rawValue, at: 1) // event_type (id: 1)
            builder.add(offset: userIDVector, at: 2)      // user_id (id: 2)
            builder.add(offset: payloadVector, at: 3)     // payload (id: 3)
            let eventOffset = builder.endTable(at: eventStart)
            
            eventOffsets.append(Offset(offset: eventOffset))
        }
        
        // Create events vector
        let eventsVector = builder.createVector(ofOffsets: eventOffsets)
        
        // Build EventData table
        let eventDataStart = builder.startTable(with: 1)
        builder.add(offset: eventsVector, at: 0) // events (required)
        let eventData = builder.endTable(at: eventDataStart)
        
        builder.finish(offset: Offset(offset: eventData))
        
        return Data(bytes: builder.sizedBuffer.memory.assumingMemoryBound(to: UInt8.self),
                   count: Int(builder.sizedBuffer.size))
    }
    
    /// Serialize event payload as JSON
    private static func serializeEventPayload(_ event: Event) throws -> Data {
        var payload: [String: Any] = [:]
        
        // Add all properties
        for (key, value) in event.properties {
            payload[key] = value
        }
        
        // Add metadata
        payload["event_id"] = event.id
        payload["event_name"] = event.name.stringValue
        
        return try JSONSerialization.data(withJSONObject: payload, options: [])
    }
    
    /// Determine event type based on event content
    private static func determineEventType(for event: Event) -> EventType {
        // Check if this is an identify event (has user traits)
        if event.properties.keys.contains(where: { ["name", "email", "traits"].contains($0) }) {
            return .identify
        }
        
        // Check if this is a group event
        if event.properties.keys.contains(where: { ["group_id", "company"].contains($0) }) {
            return .group
        }
        
        // Default to track
        return .track
    }
    
    /// Convert userID string to 16-byte format
    private static func convertUserIDToBytes(_ userID: String) -> Data {
        let data = userID.data(using: .utf8) ?? Data()
        
        if data.count == 16 {
            return data
        } else if data.count < 16 {
            // Pad with zeros
            return data + Data(repeating: 0, count: 16 - data.count)
        } else {
            // Hash to 16 bytes
            return Data(userID.utf8.prefix(16))
        }
    }
    
    // MARK: - Log Serialization (Log Schema)
    
    /// Serialize logs to LogData format (matches log.fbs)
    private static func serializeLogs(_ logs: [LogEntry]) throws -> Data {
        var builder = FlatBufferBuilder(initialSize: 1024)
        var logOffsets: [Offset] = []
        
        for log in logs {
            // Convert LogLevel to FBLogLevel
            let logLevel = convertLogLevel(log.level)
            
            // Use LogCollect type (type 1) as specified
            let eventType = LogEventType.log
            
            // Serialize log payload (data properties as JSON)
            let payload = try serializeLogPayload(log)
            let payloadVector = builder.createVector(bytes: payload)
            
            // Create string offsets
            let sourceVector = builder.create(string: log.source)
            let serviceVector = builder.create(string: log.service)
            
            // Convert timestamp to milliseconds
            let timestampMs = UInt64(log.timestamp.timeIntervalSince1970 * 1000)
            
            // Build LogEntry table (field IDs match log.fbs)
            let logStart = builder.startTable(with: 7)
            builder.add(element: eventType.rawValue, at: 0)  // event_type (id: 0)
            builder.add(element: log.contextID, at: 1)       // context_id (id: 1)
            builder.add(element: logLevel.rawValue, at: 2)   // level (id: 2)
            builder.add(element: timestampMs, at: 3)         // timestamp (id: 3)
            builder.add(offset: sourceVector, at: 4)         // source (id: 4)
            builder.add(offset: serviceVector, at: 5)        // service (id: 5)
            builder.add(offset: payloadVector, at: 6)        // payload (id: 6)
            let logOffset = builder.endTable(at: logStart)
            
            logOffsets.append(Offset(offset: logOffset))
        }
        
        // Create logs vector
        let logsVector = builder.createVector(ofOffsets: logOffsets)
        
        // Build LogData table
        let logDataStart = builder.startTable(with: 1)
        builder.add(offset: logsVector, at: 0) // logs (required)
        let logData = builder.endTable(at: logDataStart)
        
        builder.finish(offset: Offset(offset: logData))
        
        return Data(bytes: builder.sizedBuffer.memory.assumingMemoryBound(to: UInt8.self),
                   count: Int(builder.sizedBuffer.size))
    }
    
    /// Serialize log payload as JSON
    private static func serializeLogPayload(_ log: LogEntry) throws -> Data {
        var payload: [String: Any] = [:]
        
        // Add all data properties
        for (key, value) in log.data {
            payload[key] = value
        }
        
        // Add log metadata
        payload["message"] = log.message
        payload["level_name"] = log.level.rawValue
        
        return try JSONSerialization.data(withJSONObject: payload, options: [])
    }
    
    /// Convert SDK LogLevel to FlatBuffers LogLevel
    private static func convertLogLevel(_ level: LogLevel) -> FBLogLevel {
        switch level {
        case .emergency: return .emergency
        case .alert: return .alert
        case .critical: return .critical
        case .error: return .error
        case .warning: return .warning
        case .notice: return .notice
        case .info: return .info
        case .debug: return .debug
        case .trace: return .trace
        }
    }
}

// MARK: - Extensions

