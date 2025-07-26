// LogEntryTest.swift
// UserCanal Swift SDK Tests - LogEntry Unit Tests
//
// Copyright © 2024 UserCanal. All rights reserved.
//

import XCTest
@testable import UserCanal

/// Unit tests for LogEntry - log entry model validation
final class LogEntryTest: XCTestCase {

    // MARK: - LogEntry Creation Tests

    func testLogEntryInitialization() {
        let logEntry = LogEntry(
            level: .info,
            timestamp: Date(),
            source: "test-source",
            service: "test-service",
            message: "Test log message"
        )

        XCTAssertEqual(logEntry.level, .info)
        XCTAssertEqual(logEntry.source, "test-source")
        XCTAssertEqual(logEntry.service, "test-service")
        XCTAssertEqual(logEntry.message, "Test log message")
        XCTAssertNotNil(logEntry.timestamp)
        XCTAssertEqual(logEntry.eventType, .log)
        XCTAssertEqual(logEntry.contextID, 0)
    }

    func testLogEntryWithCustomParameters() {
        let customTimestamp = Date(timeIntervalSince1970: 1640995200)
        let contextID: UInt64 = 12345

        let logEntry = LogEntry(
            eventType: .enrich,
            contextID: contextID,
            level: .error,
            timestamp: customTimestamp,
            source: "custom-source",
            service: "custom-service",
            message: "Custom log message",
            data: Properties(["custom": "data"])
        )

        XCTAssertEqual(logEntry.eventType, .enrich)
        XCTAssertEqual(logEntry.contextID, contextID)
        XCTAssertEqual(logEntry.level, .error)
        XCTAssertEqual(logEntry.timestamp, customTimestamp)
        XCTAssertEqual(logEntry.source, "custom-source")
        XCTAssertEqual(logEntry.service, "custom-service")
        XCTAssertEqual(logEntry.message, "Custom log message")
        XCTAssertEqual(logEntry.data.count, 1)
    }

    func testLogEntryWithDefaultValues() {
        let logEntry = LogEntry(
            level: .warning,
            timestamp: Date(),
            source: "default-test",
            service: "default-service",
            message: "Default test message"
        )

        XCTAssertEqual(logEntry.eventType, .log)
        XCTAssertEqual(logEntry.contextID, 0)
        XCTAssertTrue(logEntry.data.isEmpty)
    }

    // MARK: - LogLevel Tests

    func testAllLogLevels() {
        let allLevels: [LogLevel] = [
            .emergency, .alert, .critical, .error,
            .warning, .notice, .info, .debug, .trace
        ]

        for level in allLevels {
            let logEntry = LogEntry(
                level: level,
                timestamp: Date(),
                source: "level-test",
                service: "level-service",
                message: "Testing \(level) level"
            )

            XCTAssertEqual(logEntry.level, level, "LogLevel should be preserved: \(level)")
        }
    }

    func testLogLevelSeverityOrder() {
        // Test that log levels follow RFC 5424 severity order
        let levels: [(LogLevel, UInt8)] = [
            (.emergency, 0),
            (.alert, 1),
            (.critical, 2),
            (.error, 3),
            (.warning, 4),
            (.notice, 5),
            (.info, 6),
            (.debug, 7),
            (.trace, 8)
        ]

        for (level, expectedValue) in levels {
            XCTAssertEqual(level.rawValue, expectedValue, "LogLevel \(level) should have rawValue \(expectedValue)")
        }
    }

    // MARK: - LogEventType Tests

    func testLogEventTypes() {
        let eventTypes: [LogEventType] = [.unknown, .log, .enrich]

        for eventType in eventTypes {
            let logEntry = LogEntry(
                eventType: eventType,
                level: .info,
                timestamp: Date(),
                source: "event-type-test",
                service: "event-service",
                message: "Testing \(eventType) event type"
            )

            XCTAssertEqual(logEntry.eventType, eventType, "LogEventType should be preserved: \(eventType)")
        }
    }

    // MARK: - Message Validation Tests

    func testLogEntryWithEmptyMessage() {
        let logEntry = LogEntry(
            level: .info,
            timestamp: Date(),
            source: "empty-test",
            service: "empty-service",
            message: ""
        )

        XCTAssertEqual(logEntry.message, "")
        XCTAssertTrue(logEntry.message.isEmpty)
    }

    func testLogEntryWithLongMessage() {
        let longMessage = String(repeating: "This is a very long log message. ", count: 100)
        let logEntry = LogEntry(
            level: .info,
            timestamp: Date(),
            source: "long-test",
            service: "long-service",
            message: longMessage
        )

        XCTAssertEqual(logEntry.message, longMessage)
        XCTAssertEqual(logEntry.message.count, longMessage.count)
    }

    func testLogEntryWithMultilineMessage() {
        let multilineMessage = """
        This is a multiline log message.
        Line 2 of the message.
        Line 3 with special characters: @#$%^&*()
        Final line.
        """

        let logEntry = LogEntry(
            level: .info,
            timestamp: Date(),
            source: "multiline-test",
            service: "multiline-service",
            message: multilineMessage
        )

        XCTAssertEqual(logEntry.message, multilineMessage)
        XCTAssertTrue(logEntry.message.contains("\n"))
    }

    func testLogEntryWithSpecialCharacters() {
        let specialMessages = [
            "Message with unicode: 🎉 émojis",
            "Message with \t tabs and \n newlines",
            "Message with \"quotes\" and 'apostrophes'",
            "Message with <html> & XML entities",
            "Message with JSON: {\"key\": \"value\"}",
            "Message with SQL: SELECT * FROM table WHERE id = 1;",
            "Message with regex: /^test.*$/",
            "Message with null: \u{0000}",
            "Message with backslashes: C:\\Windows\\System32"
        ]

        for message in specialMessages {
            let logEntry = LogEntry(
                level: .info,
                timestamp: Date(),
                source: "special-test",
                service: "special-service",
                message: message
            )

            XCTAssertEqual(logEntry.message, message, "Special characters should be preserved: \(message)")
        }
    }

    // MARK: - Source and Service Tests

    func testLogEntryWithEmptySourceAndService() {
        let logEntry = LogEntry(
            level: .info,
            timestamp: Date(),
            source: "",
            service: "",
            message: "Empty source/service test"
        )

        XCTAssertEqual(logEntry.source, "")
        XCTAssertEqual(logEntry.service, "")
    }

    func testLogEntryWithLongSourceAndService() {
        let longSource = String(repeating: "source-", count: 100)
        let longService = String(repeating: "service-", count: 100)

        let logEntry = LogEntry(
            level: .info,
            timestamp: Date(),
            source: longSource,
            service: longService,
            message: "Long source/service test"
        )

        XCTAssertEqual(logEntry.source, longSource)
        XCTAssertEqual(logEntry.service, longService)
    }

    func testLogEntryWithSpecialCharactersInSourceAndService() {
        let specialSource = "source-with-special@chars#123"
        let specialService = "service.with.dots-and_underscores"

        let logEntry = LogEntry(
            level: .info,
            timestamp: Date(),
            source: specialSource,
            service: specialService,
            message: "Special chars in source/service"
        )

        XCTAssertEqual(logEntry.source, specialSource)
        XCTAssertEqual(logEntry.service, specialService)
    }

    // MARK: - Data Properties Tests

    func testLogEntryWithEmptyData() {
        let logEntry = LogEntry(
            level: .info,
            timestamp: Date(),
            source: "empty-data-test",
            service: "empty-data-service",
            message: "Empty data test",
            data: Properties()
        )

        XCTAssertTrue(logEntry.data.isEmpty)
        XCTAssertEqual(logEntry.data.count, 0)
    }

    func testLogEntryWithSimpleData() {
        let data = Properties([
            "user_id": "test-user-123",
            "request_id": "req-456",
            "duration_ms": 150,
            "success": true
        ])

        let logEntry = LogEntry(
            level: .info,
            timestamp: Date(),
            source: "simple-data-test",
            service: "simple-data-service",
            message: "Simple data test",
            data: data
        )

        XCTAssertEqual(logEntry.data.count, 4)
        XCTAssertEqual(logEntry.data.string(for: "user_id"), "test-user-123")
        XCTAssertEqual(logEntry.data.string(for: "request_id"), "req-456")
        XCTAssertEqual(logEntry.data.int(for: "duration_ms"), 150)
        XCTAssertEqual(logEntry.data.bool(for: "success"), true)
    }

    func testLogEntryWithComplexData() {
        let complexData = Properties([
            "nested_object": ["key": "value", "count": 10],
            "array_data": [1, 2, 3, 4, 5],
            "mixed_types": ["string", 42, true, 3.14],
            "metadata": [
                "version": "1.0.0",
                "environment": "test",
                "features": ["feature1", "feature2"]
            ]
        ])

        let logEntry = LogEntry(
            level: .info,
            timestamp: Date(),
            source: "complex-data-test",
            service: "complex-data-service",
            message: "Complex data test",
            data: complexData
        )

        XCTAssertEqual(logEntry.data.count, 4)
        XCTAssertNotNil(logEntry.data["nested_object"])
        XCTAssertNotNil(logEntry.data["array_data"])
        XCTAssertNotNil(logEntry.data["mixed_types"])
        XCTAssertNotNil(logEntry.data["metadata"])
    }

    // MARK: - Context ID Tests

    func testLogEntryWithVariousContextIDs() {
        let contextIDs: [UInt64] = [0, 1, 12345, UInt64.max]

        for contextID in contextIDs {
            let logEntry = LogEntry(
                contextID: contextID,
                level: .info,
                timestamp: Date(),
                source: "context-test",
                service: "context-service",
                message: "Context ID test: \(contextID)"
            )

            XCTAssertEqual(logEntry.contextID, contextID, "Context ID should be preserved: \(contextID)")
        }
    }

    // MARK: - Timestamp Tests

    func testLogEntryWithVariousTimestamps() {
        let timestamps = [
            Date(timeIntervalSince1970: 0),
            Date(timeIntervalSince1970: 1640995200), // 2022-01-01
            Date(),
            Date(timeIntervalSinceNow: 3600) // 1 hour in future
        ]

        for timestamp in timestamps {
            let logEntry = LogEntry(
                level: .info,
                timestamp: timestamp,
                source: "timestamp-test",
                service: "timestamp-service",
                message: "Timestamp test"
            )

            XCTAssertEqual(logEntry.timestamp, timestamp, "Timestamp should be preserved")
        }
    }

    // MARK: - LogEntry Serialization Tests

    func testLogEntryDataSerialization() {
        let logEntry = LogEntry(
            level: .error,
            timestamp: Date(),
            source: "serialization-test",
            service: "serialization-service",
            message: "Serialization test message",
            data: Properties([
                "error_code": "E001",
                "error_details": "Test error details"
            ])
        )

        let jsonData = logEntry.data.jsonData
        XCTAssertNotNil(jsonData, "LogEntry data should be serializable to JSON")

        if let jsonData = jsonData {
            XCTAssertGreaterThan(jsonData.count, 0, "JSON data should not be empty")

            do {
                let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
                XCTAssertNotNil(jsonObject, "JSON should be deserializable")
            } catch {
                XCTFail("JSON deserialization failed: \(error)")
            }
        }
    }

    // MARK: - LogEntry Memory Tests

    func testLogEntryMemoryFootprint() {
        var logEntries: [LogEntry] = []

        for i in 0..<100 {
            let logEntry = LogEntry(
                level: .info,
                timestamp: Date(),
                source: "memory-test-source-\(i)",
                service: "memory-test-service-\(i)",
                message: "Memory test log message \(i)",
                data: Properties([
                    "index": i,
                    "test_data": "memory test data \(i)"
                ])
            )
            logEntries.append(logEntry)
        }

        XCTAssertEqual(logEntries.count, 100)

        // Verify some random entries
        XCTAssertEqual(logEntries[0].source, "memory-test-source-0")
        XCTAssertEqual(logEntries[50].source, "memory-test-source-50")
        XCTAssertEqual(logEntries[99].source, "memory-test-source-99")
    }

    // MARK: - LogEntry Thread Safety Tests

    func testLogEntryConcurrentCreation() {
        let expectation = XCTestExpectation(description: "Concurrent LogEntry creation should not crash")
        expectation.expectedFulfillmentCount = 10

        for i in 0..<10 {
            DispatchQueue.global().async {
                let logEntry = LogEntry(
                    level: .info,
                    timestamp: Date(),
                    source: "concurrent-source-\(i)",
                    service: "concurrent-service",
                    message: "Concurrent log message \(i)",
                    data: Properties([
                        "thread_id": i,
                        "timestamp": Date().timeIntervalSince1970
                    ])
                )

                XCTAssertEqual(logEntry.source, "concurrent-source-\(i)")
                XCTAssertEqual(logEntry.message, "Concurrent log message \(i)")
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 2.0)
    }

    // MARK: - LogEntry Description Tests

    func testLogEntryDescription() {
        let logEntry = LogEntry(
            level: .warning,
            timestamp: Date(),
            source: "description-test",
            service: "description-service",
            message: "Description test message"
        )

        let description = String(describing: logEntry)
        XCTAssertFalse(description.isEmpty, "LogEntry should have string representation")
        XCTAssertTrue(description.contains("LogEntry"), "Description should identify the type")
    }

    // MARK: - LogEntry Equality Tests

    func testLogEntryEquality() {
        let timestamp = Date()
        let data = Properties(["test": "value"])

        let logEntry1 = LogEntry(
            eventType: .log,
            contextID: 123,
            level: .info,
            timestamp: timestamp,
            source: "same-source",
            service: "same-service",
            message: "same message",
            data: data
        )

        let logEntry2 = LogEntry(
            eventType: .log,
            contextID: 123,
            level: .info,
            timestamp: timestamp,
            source: "same-source",
            service: "same-service",
            message: "same message",
            data: data
        )

        // Test structural equality
        XCTAssertEqual(logEntry1.eventType, logEntry2.eventType)
        XCTAssertEqual(logEntry1.contextID, logEntry2.contextID)
        XCTAssertEqual(logEntry1.level, logEntry2.level)
        XCTAssertEqual(logEntry1.timestamp, logEntry2.timestamp)
        XCTAssertEqual(logEntry1.source, logEntry2.source)
        XCTAssertEqual(logEntry1.service, logEntry2.service)
        XCTAssertEqual(logEntry1.message, logEntry2.message)
    }

    // MARK: - Edge Case Tests

    func testLogEntryWithEdgeCases() {
        // Test various edge cases that might cause issues
        let edgeCases = [
            (source: "", service: "", message: ""),
            (source: "\0", service: "\0", message: "\0"),
            (source: String(repeating: "x", count: 10000), service: String(repeating: "y", count: 10000), message: String(repeating: "z", count: 10000))
        ]

        for (source, service, message) in edgeCases {
            let logEntry = LogEntry(
                level: .info,
                timestamp: Date(),
                source: source,
                service: service,
                message: message
            )

            XCTAssertEqual(logEntry.source, source)
            XCTAssertEqual(logEntry.service, service)
            XCTAssertEqual(logEntry.message, message)
        }
    }
}
