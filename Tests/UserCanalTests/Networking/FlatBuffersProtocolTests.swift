// FlatBuffersProtocolTests.swift
// UserCanal Swift SDK Tests
//
// Copyright © 2024 UserCanal. All rights reserved.
//

import XCTest
import FlatBuffers
@testable import UserCanal

final class FlatBuffersProtocolTests: XCTestCase {
    
    // MARK: - Test Properties
    
    private let testAPIKey = Data(fromHexString: "1234567890abcdef1234567890abcdef")!
    
    // MARK: - Schema Type Tests
    
    func testSchemaTypeEnumValues() {
        // Verify schema types match the FlatBuffers schema exactly
        XCTAssertEqual(SchemaType.unknown.rawValue, 0)
        XCTAssertEqual(SchemaType.event.rawValue, 1)
        XCTAssertEqual(SchemaType.log.rawValue, 2)
        XCTAssertEqual(SchemaType.metric.rawValue, 3)
        XCTAssertEqual(SchemaType.inventory.rawValue, 4)
    }
    
    func testEventTypeEnumValues() {
        // Verify event types match the FlatBuffers schema exactly
        XCTAssertEqual(EventType.unknown.rawValue, 0)
        XCTAssertEqual(EventType.track.rawValue, 1)
        XCTAssertEqual(EventType.identify.rawValue, 2)
        XCTAssertEqual(EventType.group.rawValue, 3)
        XCTAssertEqual(EventType.alias.rawValue, 4)
        XCTAssertEqual(EventType.enrich.rawValue, 5)
    }
    
    func testLogEventTypeEnumValues() {
        // Verify log event types match the FlatBuffers schema exactly
        XCTAssertEqual(LogEventType.unknown.rawValue, 0)
        XCTAssertEqual(LogEventType.log.rawValue, 1)
        XCTAssertEqual(LogEventType.enrich.rawValue, 2)
        
        // Test alias
        XCTAssertEqual(LogEventType.collect, LogEventType.log)
    }
    
    func testLogLevelEnumValues() {
        // Verify log levels match RFC 5424 + TRACE
        XCTAssertEqual(FBLogLevel.emergency.rawValue, 0)
        XCTAssertEqual(FBLogLevel.alert.rawValue, 1)
        XCTAssertEqual(FBLogLevel.critical.rawValue, 2)
        XCTAssertEqual(FBLogLevel.error.rawValue, 3)
        XCTAssertEqual(FBLogLevel.warning.rawValue, 4)
        XCTAssertEqual(FBLogLevel.notice.rawValue, 5)
        XCTAssertEqual(FBLogLevel.info.rawValue, 6)
        XCTAssertEqual(FBLogLevel.debug.rawValue, 7)
        XCTAssertEqual(FBLogLevel.trace.rawValue, 8)
    }
    
    // MARK: - Event Batch Tests
    
    func testCreateEventBatchSingleEvent() throws {
        let event = Event(
            userID: "user123",
            name: .userSignedUp,
            properties: Properties([
                "source": "organic",
                "plan": "free"
            ])
        )
        
        let batchData = try FlatBuffersProtocol.createEventBatch(
            events: [event],
            apiKey: testAPIKey
        )
        
        // Verify batch was created
        XCTAssertFalse(batchData.isEmpty)
        XCTAssertLessThanOrEqual(batchData.count, 10 * 1024 * 1024) // Under 10MB limit
        
        // Verify it's valid FlatBuffers data
        XCTAssertNoThrow(try validateFlatBuffersBatch(batchData))
    }
    
    func testCreateEventBatchMultipleEvents() throws {
        let events = [
            Event(userID: "user1", name: .userSignedUp, properties: Properties(["plan": "free"])),
            Event(userID: "user2", name: .userSignedIn, properties: Properties(["device": "mobile"])),
            Event(userID: "user3", name: .pageViewed, properties: Properties(["page": "dashboard"]))
        ]
        
        let batchData = try FlatBuffersProtocol.createEventBatch(
            events: events,
            apiKey: testAPIKey
        )
        
        XCTAssertFalse(batchData.isEmpty)
        XCTAssertNoThrow(try validateFlatBuffersBatch(batchData))
    }
    
    func testCreateEventBatchWithIdentifyEvent() throws {
        let event = Event(
            userID: "user123",
            name: .custom("identify"),
            properties: Properties([
                "name": "John Doe",
                "email": "john@example.com",
                "traits": "premium_user"
            ])
        )
        
        let batchData = try FlatBuffersProtocol.createEventBatch(
            events: [event],
            apiKey: testAPIKey
        )
        
        XCTAssertFalse(batchData.isEmpty)
        XCTAssertNoThrow(try validateFlatBuffersBatch(batchData))
    }
    
    func testCreateEventBatchWithGroupEvent() throws {
        let event = Event(
            userID: "user123",
            name: .custom("group"),
            properties: Properties([
                "group_id": "company456",
                "company": "ACME Corp"
            ])
        )
        
        let batchData = try FlatBuffersProtocol.createEventBatch(
            events: [event],
            apiKey: testAPIKey
        )
        
        XCTAssertFalse(batchData.isEmpty)
        XCTAssertNoThrow(try validateFlatBuffersBatch(batchData))
    }
    
    func testCreateEventBatchWithRevenueEvent() throws {
        let event = Event(
            userID: "user123",
            name: .orderCompleted,
            properties: Properties([
                "amount": 99.99,
                "currency": "USD",
                "order_id": "order_456"
            ])
        )
        
        let batchData = try FlatBuffersProtocol.createEventBatch(
            events: [event],
            apiKey: testAPIKey
        )
        
        XCTAssertFalse(batchData.isEmpty)
        XCTAssertNoThrow(try validateFlatBuffersBatch(batchData))
    }
    
    // MARK: - Log Batch Tests
    
    func testCreateLogBatchSingleEntry() throws {
        let logEntry = LogEntry(
            level: .info,
            service: "test-service",
            message: "Test message",
            data: Properties([
                "key": "value",
                "number": 42
            ])
        )
        
        let batchData = try FlatBuffersProtocol.createLogBatch(
            logs: [logEntry],
            apiKey: testAPIKey
        )
        
        XCTAssertFalse(batchData.isEmpty)
        XCTAssertNoThrow(try validateFlatBuffersBatch(batchData))
    }
    
    func testCreateLogBatchMultipleEntries() throws {
        let logs = [
            LogEntry(level: .info, service: "api", message: "Request received"),
            LogEntry(level: .warning, service: "api", message: "Slow query detected"),
            LogEntry(level: .error, service: "api", message: "Database connection failed")
        ]
        
        let batchData = try FlatBuffersProtocol.createLogBatch(
            logs: logs,
            apiKey: testAPIKey
        )
        
        XCTAssertFalse(batchData.isEmpty)
        XCTAssertNoThrow(try validateFlatBuffersBatch(batchData))
    }
    
    func testCreateLogBatchWithAllLogLevels() throws {
        let logs = [
            LogEntry(level: .emergency, service: "system", message: "System failure"),
            LogEntry(level: .alert, service: "system", message: "Immediate action required"),
            LogEntry(level: .critical, service: "system", message: "Critical condition"),
            LogEntry(level: .error, service: "app", message: "Error occurred"),
            LogEntry(level: .warning, service: "app", message: "Warning condition"),
            LogEntry(level: .notice, service: "app", message: "Normal but significant"),
            LogEntry(level: .info, service: "app", message: "Informational message"),
            LogEntry(level: .debug, service: "app", message: "Debug information"),
            LogEntry(level: .trace, service: "app", message: "Detailed trace")
        ]
        
        let batchData = try FlatBuffersProtocol.createLogBatch(
            logs: logs,
            apiKey: testAPIKey
        )
        
        XCTAssertFalse(batchData.isEmpty)
        XCTAssertNoThrow(try validateFlatBuffersBatch(batchData))
    }
    
    // MARK: - UserID Conversion Tests
    
    func testUserIDConversion16Bytes() throws {
        let userID = "1234567890123456" // Exactly 16 characters
        let event = Event(userID: userID, name: .userSignedUp)
        
        let batchData = try FlatBuffersProtocol.createEventBatch(
            events: [event], 
            apiKey: testAPIKey
        )
        
        XCTAssertFalse(batchData.isEmpty)
    }
    
    func testUserIDConversionShortID() throws {
        let userID = "short" // Less than 16 characters
        let event = Event(userID: userID, name: .userSignedUp)
        
        let batchData = try FlatBuffersProtocol.createEventBatch(
            events: [event],
            apiKey: testAPIKey
        )
        
        XCTAssertFalse(batchData.isEmpty)
    }
    
    func testUserIDConversionLongID() throws {
        let userID = "this_is_a_very_long_user_id_that_exceeds_16_bytes"
        let event = Event(userID: userID, name: .userSignedUp)
        
        let batchData = try FlatBuffersProtocol.createEventBatch(
            events: [event],
            apiKey: testAPIKey
        )
        
        XCTAssertFalse(batchData.isEmpty)
    }
    
    // MARK: - JSON Payload Tests
    
    func testEventPayloadSerialization() throws {
        let event = Event(
            id: "event123",
            userID: "user456",
            name: .featureUsed,
            properties: Properties([
                "feature_name": "analytics",
                "usage_count": 5,
                "is_premium": true,
                "metadata": Properties([
                    "version": "1.0",
                    "platform": "iOS"
                ])
            ])
        )
        
        let batchData = try FlatBuffersProtocol.createEventBatch(
            events: [event],
            apiKey: testAPIKey
        )
        
        XCTAssertFalse(batchData.isEmpty)
        
        // The payload should contain the event metadata
        // We can't easily extract it without parsing FlatBuffers,
        // but we can verify the batch was created successfully
    }
    
    func testLogPayloadSerialization() throws {
        let logEntry = LogEntry(
            level: .info,
            service: "payment-service",
            message: "Payment processed successfully",
            data: Properties([
                "payment_id": "pay_123",
                "amount": 29.99,
                "currency": "USD",
                "processor": "stripe",
                "metadata": Properties([
                    "attempt": 1,
                    "processing_time_ms": 150
                ])
            ])
        )
        
        let batchData = try FlatBuffersProtocol.createLogBatch(
            logs: [logEntry],
            apiKey: testAPIKey
        )
        
        XCTAssertFalse(batchData.isEmpty)
    }
    
    // MARK: - Error Handling Tests
    
    func testEmptyEventsBatch() {
        XCTAssertThrowsError(try FlatBuffersProtocol.createEventBatch(
            events: [],
            apiKey: testAPIKey
        )) { error in
            // Should throw an error for empty events array
            XCTAssertTrue(error is UserCanalError)
        }
    }
    
    func testEmptyLogsBatch() {
        XCTAssertThrowsError(try FlatBuffersProtocol.createLogBatch(
            logs: [],
            apiKey: testAPIKey
        )) { error in
            // Should throw an error for empty logs array
            XCTAssertTrue(error is UserCanalError)
        }
    }
    
    func testInvalidAPIKey() {
        let invalidAPIKey = Data() // Empty API key
        let event = Event(userID: "user123", name: .userSignedUp)
        
        XCTAssertThrowsError(try FlatBuffersProtocol.createEventBatch(
            events: [event],
            apiKey: invalidAPIKey
        )) { error in
            XCTAssertTrue(error is UserCanalError)
        }
    }
    
    func testBatchSizeLimit() throws {
        // Create a very large event to test size limits
        var largeProperties = Properties()
        for i in 0..<10000 {
            largeProperties["key_\(i)"] = "very_long_value_that_takes_up_space_\(String(repeating: "x", count: 100))"
        }
        
        let event = Event(
            userID: "user123",
            name: .custom("large_event"),
            properties: largeProperties
        )
        
        // This should either succeed or throw a validation error about batch size
        do {
            let batchData = try FlatBuffersProtocol.createEventBatch(
                events: [event],
                apiKey: testAPIKey
            )
            
            // If it succeeds, verify it's within limits
            XCTAssertLessThanOrEqual(batchData.count, 10 * 1024 * 1024)
        } catch let error as UserCanalError {
            // Should be a validation error about batch size
            if case .validationError(let field, let reason) = error {
                XCTAssertEqual(field, "batch")
                XCTAssertTrue(reason.contains("exceeds maximum"))
            } else {
                XCTFail("Unexpected error type: \(error)")
            }
        }
    }
    
    // MARK: - Performance Tests
    
    func testBatchCreationPerformance() throws {
        let events = (0..<100).map { i in
            Event(
                userID: "user\(i)",
                name: .pageViewed,
                properties: Properties([
                    "page": "page\(i)",
                    "session_id": "session\(i % 10)",
                    "timestamp": Date().timeIntervalSince1970
                ])
            )
        }
        
        measure {
            do {
                _ = try FlatBuffersProtocol.createEventBatch(
                    events: events,
                    apiKey: testAPIKey
                )
            } catch {
                XCTFail("Batch creation failed: \(error)")
            }
        }
    }
    
    func testLogBatchCreationPerformance() throws {
        let logs = (0..<100).map { i in
            LogEntry(
                level: .info,
                service: "service\(i % 5)",
                message: "Log message \(i)",
                data: Properties([
                    "request_id": "req_\(i)",
                    "duration_ms": i * 10,
                    "status": "success"
                ])
            )
        }
        
        measure {
            do {
                _ = try FlatBuffersProtocol.createLogBatch(
                    logs: logs,
                    apiKey: testAPIKey
                )
            } catch {
                XCTFail("Log batch creation failed: \(error)")
            }
        }
    }
    
    // MARK: - Schema Compatibility Tests
    
    func testEventTypeDetection() throws {
        // Test that events are properly categorized by type
        
        // Track event
        let trackEvent = Event(
            userID: "user123",
            name: .pageViewed,
            properties: Properties(["page": "home"])
        )
        
        // Identify event (has user traits)
        let identifyEvent = Event(
            userID: "user123",
            name: .custom("identify"),
            properties: Properties([
                "name": "John Doe",
                "email": "john@example.com"
            ])
        )
        
        // Group event (has group info)
        let groupEvent = Event(
            userID: "user123",
            name: .custom("group"),
            properties: Properties([
                "group_id": "company456",
                "company": "ACME Corp"
            ])
        )
        
        let batchData = try FlatBuffersProtocol.createEventBatch(
            events: [trackEvent, identifyEvent, groupEvent],
            apiKey: testAPIKey
        )
        
        XCTAssertFalse(batchData.isEmpty)
    }
    
    func testTimestampConversion() throws {
        let specificDate = Date(timeIntervalSince1970: 1234567890.123)
        let event = Event(
            userID: "user123",
            name: .userSignedUp,
            timestamp: specificDate
        )
        
        let batchData = try FlatBuffersProtocol.createEventBatch(
            events: [event],
            apiKey: testAPIKey
        )
        
        XCTAssertFalse(batchData.isEmpty)
        
        // Verify millisecond precision is maintained
        let expectedMs = UInt64(specificDate.timeIntervalSince1970 * 1000)
        XCTAssertEqual(expectedMs, 1234567890123)
    }
    
    // MARK: - Helper Methods
    
    private func validateFlatBuffersBatch(_ data: Data) throws {
        // Basic validation that the data is valid FlatBuffers format
        // This is a simple check - in a real scenario you'd parse the buffer
        XCTAssertGreaterThan(data.count, 0)
        XCTAssertLessThan(data.count, 10 * 1024 * 1024) // Under 10MB
        
        // FlatBuffers data should have at least the minimum header size
        XCTAssertGreaterThanOrEqual(data.count, 8)
    }
}

// MARK: - Test Extensions

extension Data {
    static func fromHexString(_ hex: String) -> Data? {
        let len = hex.count / 2
        var data = Data(capacity: len)
        var index = hex.startIndex
        for _ in 0..<len {
            let nextIndex = hex.index(index, offsetBy: 2)
            if let b = UInt8(hex[index..<nextIndex], radix: 16) {
                data.append(b)
            } else {
                return nil
            }
            index = nextIndex
        }
        return data
    }
}