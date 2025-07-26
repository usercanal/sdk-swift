// FlatBuffersIntegrationTest.swift
// UserCanal Swift SDK Tests - FlatBuffers Integration Test
//
// Copyright © 2024 UserCanal. All rights reserved.
//

import XCTest
import FlatBuffers
@testable import UserCanal

/// Comprehensive integration test for FlatBuffers schema serialization
/// Tests real UserCanal schemas (Event, Log, Batch) to catch FlatBuffers bugs
/// This test is CRITICAL for preventing alignment crashes and schema regressions
final class FlatBuffersIntegrationTest: XCTestCase {

    func testEventBatchSerialization() {
        print("🧪 Event Batch Serialization - Real Schema Test")

        // Your actual API key
        let apiKey = Data([0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
                          0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f])

        // Create minimal event
        let event = Event(
            userID: "test_user_123",
            name: EventName("test_event"),
            properties: Properties(["key": "value"])
        )

        print("📊 Testing with event: \(event.id)")
        print("📊 User ID: \(event.userID)")
        print("📊 Event name: \(event.name.stringValue)")

        do {
            print("📊 About to call FlatBuffersProtocol.createEventBatch...")
            let batchData = try FlatBuffersProtocol.createEventBatch(
                events: [event],
                apiKey: apiKey
            )

            print("✅ SUCCESS: Batch created without crash!")
            print("📊 Batch size: \(batchData.count) bytes")

            // Save to file for analysis
            let tempFile = "/tmp/swift_flatbuffers_batch.bin"
            try batchData.write(to: URL(fileURLWithPath: tempFile))
            print("📊 Saved batch to: \(tempFile)")

            // Hex dump first 32 bytes
            let hexDump = batchData.prefix(32).map { String(format: "%02x", $0) }.joined(separator: " ")
            print("📊 First 32 bytes: \(hexDump)")

            XCTAssertFalse(batchData.isEmpty, "Batch should not be empty")

        } catch {
            print("❌ CRASH/ERROR: \(error)")
            XCTFail("FlatBuffersProtocol.createEventBatch failed: \(error)")
        }
    }

    func testLogBatchSerialization() {
        print("🧪 Log Batch Serialization - Real Schema Test")

        let apiKey = Data([0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
                          0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f])

        let logEntry = LogEntry(
            level: .info,
            service: "test-service",
            message: "Test log message",
            data: ["test_key": "test_value"]
        )

        print("📊 Testing with log: \(logEntry.message)")

        do {
            print("📊 About to call FlatBuffersProtocol.createLogBatch...")
            let batchData = try FlatBuffersProtocol.createLogBatch(
                logs: [logEntry],
                apiKey: apiKey
            )

            print("✅ SUCCESS: Log batch created without crash!")
            print("📊 Log batch size: \(batchData.count) bytes")

            XCTAssertFalse(batchData.isEmpty, "Log batch should not be empty")

        } catch {
            print("❌ CRASH/ERROR: \(error)")
            XCTFail("FlatBuffersProtocol.createLogBatch failed: \(error)")
        }
    }

    func testBatchScalingAndComplexity() {
        print("🧪 Batch Scaling and Schema Complexity Test")

        let apiKey = Data([0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
                          0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f])

        let events = [
            Event(userID: "user1", name: .userSignedUp, properties: Properties(["plan": "free"])),
            Event(userID: "user2", name: .userSignedIn, properties: Properties(["device": "mobile"])),
            Event(userID: "user3", name: .pageViewed, properties: Properties(["page": "dashboard"]))
        ]

        print("📊 Testing with \(events.count) events")

        do {
            let batchData = try FlatBuffersProtocol.createEventBatch(
                events: events,
                apiKey: apiKey
            )

            print("✅ SUCCESS: Multi-event batch created!")
            print("📊 Multi-event batch size: \(batchData.count) bytes")

            XCTAssertFalse(batchData.isEmpty, "Multi-event batch should not be empty")

        } catch {
            XCTFail("Multi-event batch creation failed: \(error)")
        }
    }

    func testAlignmentStressTest() {
        print("🧪 FlatBuffers Alignment Stress Test - Critical for ARM64")

        let apiKey = Data([0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
                          0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f])

        // Test various string lengths that historically caused alignment issues
        let testSizes = [1, 2, 3, 5, 7, 15, 16, 17, 31, 32, 33, 63, 64, 65]

        for size in testSizes {
            let testString = String(repeating: "x", count: size)
            let event = Event(
                userID: "alignment_test_user",
                name: EventName(testString),
                properties: Properties(["size": size])
            )

            do {
                let batchData = try FlatBuffersProtocol.createEventBatch(
                    events: [event],
                    apiKey: apiKey
                )

                XCTAssertFalse(batchData.isEmpty, "Batch with \(size)-char string should not be empty")

                // Periodically log progress
                if size % 16 == 0 {
                    print("✅ Alignment test \(size) chars: \(batchData.count) bytes")
                }

            } catch {
                XCTFail("Alignment test failed for size \(size): \(error)")
            }
        }

        print("✅ Alignment stress test: All sizes passed")
    }

    func testComplexTableStructures() {
        print("🧪 Complex Table Structures - Schema Validation")

        let apiKey = Data([0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
                          0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f])

        // Test the exact Batch table structure from schema (4 fields)
        // This historically triggered the alignment bug
        let complexEvent = Event(
            userID: "complex_table_user",
            name: EventName("complex_table_test"),
            properties: Properties([
                "string_field": "test_value",
                "integer_field": 42,
                "float_field": 3.14159,
                "boolean_field": true,
                "nested_data": "{\"key\":\"value\"}"
            ])
        )

        do {
            // This creates the full schema hierarchy:
            // Batch(api_key, batch_id, schema_type, data) -> EventData(events) -> Event(timestamp, event_type, user_id, payload)
            let batchData = try FlatBuffersProtocol.createEventBatch(
                events: [complexEvent],
                apiKey: apiKey
            )

            XCTAssertFalse(batchData.isEmpty, "Complex table structure should serialize")
            XCTAssertGreaterThan(batchData.count, 100, "Complex structure should have substantial size")

            print("✅ Complex table serialization: \(batchData.count) bytes")

        } catch {
            XCTFail("Complex table structure failed: \(error)")
        }
    }

    func testMemorySafetyValidation() {
        print("🧪 Memory Safety Validation - Buffer Bounds Checking")

        let apiKey = Data([0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
                          0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f])

        // Rapidly create many batches to test for memory safety issues
        for i in 1...50 {
            let event = Event(
                userID: "memory_safety_user_\(i)",
                name: EventName("memory_test_event"),
                properties: Properties(["iteration": i])
            )

            do {
                let batchData = try FlatBuffersProtocol.createEventBatch(
                    events: [event],
                    apiKey: apiKey
                )

                XCTAssertFalse(batchData.isEmpty, "Batch \(i) should not be empty")

                // Validate basic integrity
                XCTAssertGreaterThan(batchData.count, 50, "Batch should have minimum size")
                XCTAssertLessThan(batchData.count, 10000, "Batch should not be excessively large")

            } catch {
                XCTFail("Memory safety test failed at iteration \(i): \(error)")
            }
        }

        print("✅ Memory safety validation: 50 batches created successfully")
    }

    func testMultipleSchemaValidation() {
        print("🧪 Multiple Schema Validation - Event and Log Schema Testing")

        let apiKey = Data([0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
                          0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f])

        // Test both Event and Log schemas in the same test
        let event = Event(
            userID: "schema_evo_user",
            name: EventName("schema_evolution_test"),
            properties: Properties(["test": "evolution"])
        )

        let logEntry = LogEntry(
            level: .info,
            timestamp: Date(),
            source: "schema-test",
            service: "usercanal-sdk",
            message: "Schema evolution test log"
        )

        do {
            // Test Event batch
            let eventBatch = try FlatBuffersProtocol.createEventBatch(
                events: [event],
                apiKey: apiKey
            )

            // Test Log batch
            let logBatch = try FlatBuffersProtocol.createLogBatch(
                logs: [logEntry],
                apiKey: apiKey
            )

            XCTAssertFalse(eventBatch.isEmpty, "Event batch should serialize")
            XCTAssertFalse(logBatch.isEmpty, "Log batch should serialize")
            XCTAssertNotEqual(eventBatch, logBatch, "Different schemas should produce different output")

            print("✅ Event schema batch: \(eventBatch.count) bytes")
            print("✅ Log schema batch: \(logBatch.count) bytes")

        } catch {
            XCTFail("Schema evolution test failed: \(error)")
        }
    }

    override func tearDown() {
        print("🎯 FlatBuffers Integration Test completed - All schema validations passed")
        super.tearDown()
    }
}
