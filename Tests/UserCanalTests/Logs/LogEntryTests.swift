// LogEntryTests.swift
// UserCanal Swift SDK Tests
//
// Copyright © 2024 UserCanal. All rights reserved.
//

import XCTest
@testable import UserCanal

final class LogEntryTests: XCTestCase {
    
    // MARK: - LogEntry Creation Tests
    
    func testLogEntryCreation() {
        let logEntry = LogEntry(
            level: .info,
            service: "test-service",
            message: "Test message",
            data: Properties([
                "key": "value",
                "count": 42
            ])
        )
        
        XCTAssertEqual(logEntry.level, .info)
        XCTAssertEqual(logEntry.service, "test-service")
        XCTAssertEqual(logEntry.message, "Test message")
        XCTAssertEqual(logEntry.data["key"] as? String, "value")
        XCTAssertEqual(logEntry.data["count"] as? Int, 42)
        XCTAssertEqual(logEntry.eventType, .log)
        XCTAssertEqual(logEntry.contextID, 0)
        XCTAssertFalse(logEntry.source.isEmpty)
        XCTAssertNotNil(logEntry.timestamp)
    }
    
    func testLogEntryWithCustomEventType() {
        let logEntry = LogEntry(
            eventType: .enrich,
            contextID: 12345,
            level: .debug,
            service: "enrichment-service",
            message: "Enrichment message"
        )
        
        XCTAssertEqual(logEntry.eventType, .enrich)
        XCTAssertEqual(logEntry.contextID, 12345)
        XCTAssertEqual(logEntry.level, .debug)
        XCTAssertEqual(logEntry.service, "enrichment-service")
        XCTAssertEqual(logEntry.message, "Enrichment message")
    }
    
    func testLogEntryWithDataBuilder() {
        let logEntry = LogEntry(
            level: .error,
            service: "api-service",
            message: "API error"
        ) {
            Properties([
                "error_code": "E001",
                "request_id": "req_123",
                "duration_ms": 150
            ])
        }
        
        XCTAssertEqual(logEntry.data["error_code"] as? String, "E001")
        XCTAssertEqual(logEntry.data["request_id"] as? String, "req_123")
        XCTAssertEqual(logEntry.data["duration_ms"] as? Int, 150)
    }
    
    // MARK: - LogLevel Tests
    
    func testLogLevelComparison() {
        XCTAssertTrue(LogLevel.emergency < LogLevel.alert)
        XCTAssertTrue(LogLevel.alert < LogLevel.critical)
        XCTAssertTrue(LogLevel.critical < LogLevel.error)
        XCTAssertTrue(LogLevel.error < LogLevel.warning)
        XCTAssertTrue(LogLevel.warning < LogLevel.notice)
        XCTAssertTrue(LogLevel.notice < LogLevel.info)
        XCTAssertTrue(LogLevel.info < LogLevel.debug)
        XCTAssertTrue(LogLevel.debug < LogLevel.trace)
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
    
    func testLogLevelDescriptions() {
        XCTAssertEqual(LogLevel.emergency.description, "EMERGENCY")
        XCTAssertEqual(LogLevel.alert.description, "ALERT")
        XCTAssertEqual(LogLevel.critical.description, "CRITICAL")
        XCTAssertEqual(LogLevel.error.description, "ERROR")
        XCTAssertEqual(LogLevel.warning.description, "WARNING")
        XCTAssertEqual(LogLevel.notice.description, "NOTICE")
        XCTAssertEqual(LogLevel.info.description, "INFO")
        XCTAssertEqual(LogLevel.debug.description, "DEBUG")
        XCTAssertEqual(LogLevel.trace.description, "TRACE")
    }
    
    func testLogLevelShortStrings() {
        XCTAssertEqual(LogLevel.emergency.shortString, "EMRG")
        XCTAssertEqual(LogLevel.alert.shortString, "ALRT")
        XCTAssertEqual(LogLevel.critical.shortString, "CRIT")
        XCTAssertEqual(LogLevel.error.shortString, "ERRR")
        XCTAssertEqual(LogLevel.warning.shortString, "WARN")
        XCTAssertEqual(LogLevel.notice.shortString, "NOTE")
        XCTAssertEqual(LogLevel.info.shortString, "INFO")
        XCTAssertEqual(LogLevel.debug.shortString, "DEBG")
        XCTAssertEqual(LogLevel.trace.shortString, "TRCE")
    }
    
    // MARK: - LogEventType Tests
    
    func testLogEventTypeRawValues() {
        XCTAssertEqual(LogEventType.unknown.rawValue, 0)
        XCTAssertEqual(LogEventType.log.rawValue, 1)
        XCTAssertEqual(LogEventType.enrich.rawValue, 2)
    }
    
    func testLogEventTypeDescriptions() {
        XCTAssertEqual(LogEventType.unknown.description, "UNKNOWN")
        XCTAssertEqual(LogEventType.log.description, "LOG")
        XCTAssertEqual(LogEventType.enrich.description, "ENRICH")
    }
    
    // MARK: - Validation Tests
    
    func testLogEntryValidation() {
        // Valid log entry
        let validEntry = LogEntry(
            level: .info,
            service: "test-service",
            message: "Test message"
        )
        
        XCTAssertNoThrow(try validEntry.validate())
    }
    
    func testLogEntryValidationEmptyService() {
        let invalidEntry = LogEntry(
            level: .info,
            service: "",
            message: "Test message"
        )
        
        XCTAssertThrowsError(try invalidEntry.validate()) { error in
            XCTAssertTrue(error is UserCanalError)
        }
    }
    
    func testLogEntryValidationEmptyMessage() {
        let invalidEntry = LogEntry(
            level: .info,
            service: "test-service",
            message: ""
        )
        
        XCTAssertThrowsError(try invalidEntry.validate()) { error in
            XCTAssertTrue(error is UserCanalError)
        }
    }
    
    // MARK: - Convenience Constructor Tests
    
    func testInfoLogEntryConstructor() {
        let logEntry = LogEntry.info(
            service: "test-service",
            message: "Info message",
            data: Properties(["key": "value"])
        )
        
        XCTAssertEqual(logEntry.level, .info)
        XCTAssertEqual(logEntry.eventType, .log)
        XCTAssertEqual(logEntry.service, "test-service")
        XCTAssertEqual(logEntry.message, "Info message")
        XCTAssertEqual(logEntry.data["key"] as? String, "value")
    }
    
    func testErrorLogEntryConstructor() {
        let logEntry = LogEntry.error(
            service: "test-service",
            message: "Error message",
            data: Properties(["error_code": "E001"])
        )
        
        XCTAssertEqual(logEntry.level, .error)
        XCTAssertEqual(logEntry.eventType, .log)
        XCTAssertEqual(logEntry.service, "test-service")
        XCTAssertEqual(logEntry.message, "Error message")
        XCTAssertEqual(logEntry.data["error_code"] as? String, "E001")
    }
    
    func testDebugLogEntryConstructor() {
        let logEntry = LogEntry.debug(
            service: "test-service",
            message: "Debug message"
        )
        
        XCTAssertEqual(logEntry.level, .debug)
        XCTAssertEqual(logEntry.eventType, .log)
        XCTAssertEqual(logEntry.service, "test-service")
        XCTAssertEqual(logEntry.message, "Debug message")
    }
    
    func testWarningLogEntryConstructor() {
        let logEntry = LogEntry.warning(
            service: "test-service",
            message: "Warning message",
            contextID: 9999
        )
        
        XCTAssertEqual(logEntry.level, .warning)
        XCTAssertEqual(logEntry.eventType, .log)
        XCTAssertEqual(logEntry.contextID, 9999)
        XCTAssertEqual(logEntry.service, "test-service")
        XCTAssertEqual(logEntry.message, "Warning message")
    }
    
    func testEnrichmentLogEntryConstructor() {
        let logEntry = LogEntry.enrichment(
            service: "enrichment-service",
            message: "Enrichment data",
            data: Properties(["enriched_field": "value"])
        )
        
        XCTAssertEqual(logEntry.level, .info)
        XCTAssertEqual(logEntry.eventType, .enrich)
        XCTAssertEqual(logEntry.service, "enrichment-service")
        XCTAssertEqual(logEntry.message, "Enrichment data")
        XCTAssertEqual(logEntry.data["enriched_field"] as? String, "value")
    }
    
    // MARK: - Codable Tests
    
    func testLogEntryCodable() throws {
        let originalEntry = LogEntry(
            eventType: .log,
            contextID: 12345,
            level: .warning,
            service: "test-service",
            message: "Test message",
            data: Properties([
                "key1": "value1",
                "key2": 42,
                "key3": true
            ])
        )
        
        // Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalEntry)
        
        // Decode
        let decoder = JSONDecoder()
        let decodedEntry = try decoder.decode(LogEntry.self, from: data)
        
        // Verify
        XCTAssertEqual(originalEntry.eventType, decodedEntry.eventType)
        XCTAssertEqual(originalEntry.contextID, decodedEntry.contextID)
        XCTAssertEqual(originalEntry.level, decodedEntry.level)
        XCTAssertEqual(originalEntry.service, decodedEntry.service)
        XCTAssertEqual(originalEntry.message, decodedEntry.message)
        XCTAssertEqual(originalEntry.source, decodedEntry.source)
    }
    
    // MARK: - CustomStringConvertible Tests
    
    func testLogEntryDescription() {
        let logEntry = LogEntry(
            level: .error,
            service: "api-service",
            message: "Request failed"
        )
        
        let description = logEntry.description
        
        XCTAssertTrue(description.contains("LogEntry"))
        XCTAssertTrue(description.contains("ERROR"))
        XCTAssertTrue(description.contains("api-service"))
        XCTAssertTrue(description.contains("Request failed"))
    }
    
    func testLogLevelDescription() {
        XCTAssertEqual(LogLevel.info.description, "INFO")
        XCTAssertEqual(LogLevel.error.description, "ERROR")
    }
    
    func testLogEventTypeDescription() {
        XCTAssertEqual(LogEventType.log.description, "LOG")
        XCTAssertEqual(LogEventType.enrich.description, "ENRICH")
    }
}