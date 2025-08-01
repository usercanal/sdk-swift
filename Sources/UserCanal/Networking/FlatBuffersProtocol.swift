// FlatBuffersProtocol.swift
// UserCanal Swift SDK
//
// Copyright © 2024 UserCanal. All rights reserved.
//

import Foundation
import FlatBuffers

// Generated FlatBuffers classes are in the same module

// MARK: - Schema Types (matching Go SDK)

/// Schema types for routing and streaming (matches common.fbs)
public enum SchemaType: UInt8 {
    case unknown = 0
    case event = 1
    case log = 2
    case metric = 3
    case inventory = 4
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

        // Convert SchemaType to the generated schema type
        let schemaTypeGenerated: schema_common_SchemaType
        switch schemaType {
        case .unknown:
            schemaTypeGenerated = .unknown
        case .event:
            schemaTypeGenerated = .event
        case .log:
            schemaTypeGenerated = .log
        case .metric:
            schemaTypeGenerated = .metric
        case .inventory:
            schemaTypeGenerated = .inventory
        }

        // Use generated FlatBuffers functions (like Go SDK)
        let batch = schema_common_Batch.createBatch(
            &builder,
            apiKeyVectorOffset: apiKeyVector,
            batchId: batchID,
            schemaType: schemaTypeGenerated,
            dataVectorOffset: dataVector
        )

        builder.finish(offset: batch)

        // Extract data from ByteBuffer using new API
        let result = Data(builder.sizedByteArray)

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
            // Trace logging for event type mapping
            SDKLogger.trace("Serializing event '\(event.name.stringValue)' with type: \(event.eventType) (raw: \(event.eventType.rawValue))", category: .batching)

            // Use explicit event type from Event struct
            let eventTypeGenerated: schema_event_EventType
            switch event.eventType {
            case .unknown:
                eventTypeGenerated = .unknown
            case .track:
                eventTypeGenerated = .track
            case .identify:
                eventTypeGenerated = .identify
            case .group:
                eventTypeGenerated = .group
            case .alias:
                eventTypeGenerated = .alias
            case .enrich:
                eventTypeGenerated = .enrich
            }

            SDKLogger.trace("Mapped to FlatBuffers type: \(eventTypeGenerated) (raw: \(eventTypeGenerated.rawValue))", category: .batching)

            // Serialize event payload (properties + metadata as JSON)
            let payload = try serializeEventPayload(event)
            let payloadVector = builder.createVector(bytes: payload)

            // Convert userID to 16-byte UUID format (pad or hash if needed)
            let userIDBytes = convertUserIDToBytes(event.userID)
            let userIDVector = builder.createVector(bytes: userIDBytes)

            // Convert timestamp to milliseconds
            let timestampMs = UInt64(event.timestamp.timeIntervalSince1970 * 1000)

            // Use generated FlatBuffers functions for Event
            let eventOffset = schema_event_Event.createEvent(
                &builder,
                timestamp: timestampMs,
                eventType: eventTypeGenerated,
                userIdVectorOffset: userIDVector,
                payloadVectorOffset: payloadVector
            )

            eventOffsets.append(eventOffset)
        }

        // Create events vector
        let eventsVector = builder.createVector(ofOffsets: eventOffsets)

        // Use generated FlatBuffers functions for EventData
        let eventData = schema_event_EventData.createEventData(
            &builder,
            eventsVectorOffset: eventsVector
        )

        builder.finish(offset: eventData)

        // Extract data from ByteBuffer using new API
        return Data(builder.sizedByteArray)
    }

    /// Serialize event payload as JSON
    private static func serializeEventPayload(_ event: Event) throws -> Data {
        var payload: [String: Any] = [:]

        // Add all properties
        for (key, value) in event.properties {
            payload[key] = value
        }

        // Add metadata
        if !event.id.isEmpty {
            payload["event_id"] = event.id
        }
        payload["event_name"] = event.name.stringValue

        return try JSONSerialization.data(withJSONObject: payload, options: [])
    }



    /// Convert userID string to 16-byte format
    /// Properly handles UUID strings by parsing them as hex
    private static func convertUserIDToBytes(_ userID: String) -> Data {
        // Try to parse as UUID first (standard format with dashes)
        if let uuid = UUID(uuidString: userID) {
            return withUnsafeBytes(of: uuid.uuid) { bytes in
                Data(bytes)
            }
        }

        // Try to parse as hex string without dashes (32 hex chars = 16 bytes)
        let cleanHex = userID.replacingOccurrences(of: "-", with: "")
        if cleanHex.count == 32, cleanHex.allSatisfy({ $0.isHexDigit }) {
            var data = Data()
            for i in stride(from: 0, to: cleanHex.count, by: 2) {
                let start = cleanHex.index(cleanHex.startIndex, offsetBy: i)
                let end = cleanHex.index(start, offsetBy: 2)
                let byteString = String(cleanHex[start..<end])
                if let byte = UInt8(byteString, radix: 16) {
                    data.append(byte)
                }
            }
            return data
        }

        // Fallback: treat as regular string and pad/truncate to 16 bytes
        let data = userID.data(using: .utf8) ?? Data()
        if data.count == 16 {
            return data
        } else if data.count < 16 {
            // Pad with zeros
            return data + Data(repeating: 0, count: 16 - data.count)
        } else {
            // Truncate to 16 bytes
            return Data(data.prefix(16))
        }
    }

    // MARK: - Log Serialization (Log Schema)

    /// Serialize logs to LogData format (matches log.fbs)
    private static func serializeLogs(_ logs: [LogEntry]) throws -> Data {
        var builder = FlatBufferBuilder(initialSize: 1024)
        var logOffsets: [Offset] = []

        for log in logs {
            // Convert LogLevel to generated schema type
            let logLevel = convertLogLevel(log.level)

            // Convert LogEventType to generated schema type
            let eventType: schema_log_LogEventType
            switch log.eventType {
            case .unknown:
                eventType = .unknown
            case .log:
                eventType = .log
            case .enrich:
                eventType = .enrich
            }

            // Serialize log payload (data properties as JSON)
            let payload = try serializeLogPayload(log)
            let payloadVector = builder.createVector(bytes: payload)

            // Create string offsets
            let sourceVector = builder.create(string: log.source)
            let serviceVector = builder.create(string: log.service)

            // Convert timestamp to milliseconds
            let timestampMs = UInt64(log.timestamp.timeIntervalSince1970 * 1000)

            // Use generated FlatBuffers functions for LogEntry
            let logOffset = schema_log_LogEntry.createLogEntry(
                &builder,
                eventType: eventType,
                contextId: log.contextID,
                level: logLevel,
                timestamp: timestampMs,
                sourceOffset: sourceVector,
                serviceOffset: serviceVector,
                payloadVectorOffset: payloadVector
            )

            logOffsets.append(logOffset)
        }

        // Create logs vector
        let logsVector = builder.createVector(ofOffsets: logOffsets)

        // Use generated FlatBuffers functions for LogData
        let logData = schema_log_LogData.createLogData(
            &builder,
            logsVectorOffset: logsVector
        )

        builder.finish(offset: logData)

        // Extract data from ByteBuffer using new API
        return Data(builder.sizedByteArray)
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

    /// Convert SDK LogLevel to generated schema LogLevel
    private static func convertLogLevel(_ level: LogLevel) -> schema_log_LogLevel {
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

// MARK: - Helper Extensions

/// Extension to check if a character is a valid hexadecimal digit
private extension Character {
    var isHexDigit: Bool {
        return isASCII && (isNumber || ("a"..."f").contains(lowercased()) || ("A"..."F").contains(self))
    }
}

// MARK: - Extensions
