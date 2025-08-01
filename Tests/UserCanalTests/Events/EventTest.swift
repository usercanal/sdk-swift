// EventTest.swift
// UserCanal Swift SDK Tests - Event Unit Tests
//
// Copyright © 2024 UserCanal. All rights reserved.
//

import XCTest
@testable import UserCanal

/// Unit tests for Event - core event model validation
final class EventTest: XCTestCase {

    // MARK: - Event Creation Tests

    func testEventInitialization() {
        let event = Event(
            userID: "test-user-123",
            name: EventName("test_event"),
            properties: Properties(["key": "value"])
        )

        XCTAssertFalse(event.id.isEmpty, "Event ID should be generated")
        XCTAssertEqual(event.userID, "test-user-123")
        XCTAssertEqual(event.name.stringValue, "test_event")
        XCTAssertEqual(event.properties.count, 1)
        XCTAssertNotNil(event.timestamp)
    }

    func testEventWithCustomID() {
        let customID = "custom-event-id-456"
        let event = Event(
            id: customID,
            userID: "test-user-789",
            name: EventName("custom_id_event"),
            properties: Properties()
        )

        XCTAssertEqual(event.id, customID)
        XCTAssertEqual(event.userID, "test-user-789")
        XCTAssertEqual(event.name.stringValue, "custom_id_event")
        XCTAssertTrue(event.properties.isEmpty)
    }

    func testEventWithCustomTimestamp() {
        let customTimestamp = Date(timeIntervalSince1970: 1640995200) // 2022-01-01
        let event = Event(
            userID: "timestamp-user",
            name: EventName("timestamp_event"),
            timestamp: customTimestamp
        )

        XCTAssertEqual(event.timestamp, customTimestamp)
        XCTAssertEqual(event.userID, "timestamp-user")
        XCTAssertEqual(event.name.stringValue, "timestamp_event")
    }

    // MARK: - Event Properties Tests

    func testEventWithEmptyProperties() {
        let event = Event(
            userID: "empty-props-user",
            name: EventName("empty_props_event"),
            properties: Properties()
        )

        XCTAssertTrue(event.properties.isEmpty)
        XCTAssertEqual(event.properties.count, 0)
    }

    func testEventWithSimpleProperties() {
        let properties = Properties([
            "string_prop": "test_value",
            "int_prop": 42,
            "double_prop": 3.14159,
            "bool_prop": true
        ])

        let event = Event(
            userID: "simple-props-user",
            name: EventName("simple_props_event"),
            properties: properties
        )

        XCTAssertEqual(event.properties.count, 4)
        XCTAssertEqual(event.properties.string(for: "string_prop"), "test_value")
        XCTAssertEqual(event.properties.int(for: "int_prop"), 42)
        XCTAssertEqual(event.properties.double(for: "double_prop"), 3.14159)
        XCTAssertEqual(event.properties.bool(for: "bool_prop"), true)
    }

    func testEventWithComplexProperties() {
        let complexProperties = Properties([
            "nested_object": ["key": "value", "count": 10],
            "array_data": [1, 2, 3, 4, 5],
            "mixed_array": ["string", 42, true],
            "empty_object": [:],
            "empty_array": []
        ])

        let event = Event(
            userID: "complex-props-user",
            name: EventName("complex_props_event"),
            properties: complexProperties
        )

        XCTAssertEqual(event.properties.count, 5)
        XCTAssertNotNil(event.properties["nested_object"])
        XCTAssertNotNil(event.properties["array_data"])
        XCTAssertNotNil(event.properties["mixed_array"])
    }

    // MARK: - Event Builder Pattern Tests

    func testEventBuilderPattern() {
        let event = Event(
            userID: "builder-user",
            name: EventName("builder_event"),
            properties: {
                Properties([
                    "built_prop": "builder_value",
                    "built_count": 1
                ])
            },
            timestamp: Date()
        )

        XCTAssertEqual(event.userID, "builder-user")
        XCTAssertEqual(event.name.stringValue, "builder_event")
        XCTAssertEqual(event.properties.count, 2)
        XCTAssertEqual(event.properties.string(for: "built_prop"), "builder_value")
        XCTAssertEqual(event.properties.int(for: "built_count"), 1)
    }

    // MARK: - Event Validation Tests

    func testEventWithEmptyUserID() {
        let event = Event(
            userID: "",
            name: EventName("empty_user_event"),
            properties: Properties()
        )

        XCTAssertEqual(event.userID, "")
        // Note: Empty userID might be valid in some contexts
    }

    func testEventWithLongUserID() {
        let longUserID = String(repeating: "a", count: 1000)
        let event = Event(
            userID: longUserID,
            name: EventName("long_user_event"),
            properties: Properties()
        )

        XCTAssertEqual(event.userID, longUserID)
        XCTAssertEqual(event.userID.count, 1000)
    }

    func testEventWithSpecialCharactersInUserID() {
        let specialUserIDs = [
            "user@example.com",
            "user-123_456",
            "用户123", // Unicode characters
            "user with spaces",
            "user/with/slashes",
            "user:with:colons"
        ]

        for userID in specialUserIDs {
            let event = Event(
                userID: userID,
                name: EventName("special_char_event"),
                properties: Properties()
            )

            XCTAssertEqual(event.userID, userID, "Special character userID should be preserved: \(userID)")
        }
    }

    // MARK: - Event Serialization Tests

    func testEventSerialization() {
        let event = Event(
            userID: "serialization-user",
            name: EventName("serialization_event"),
            properties: Properties([
                "serialize_test": "value",
                "serialize_count": 42
            ])
        )

        // Test that event properties can be serialized to JSON
        let jsonData = event.properties.jsonData
        XCTAssertNotNil(jsonData, "Event properties should be serializable to JSON")

        if let jsonData = jsonData {
            XCTAssertGreaterThan(jsonData.count, 0, "JSON data should not be empty")

            // Test that JSON can be deserialized
            do {
                let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
                XCTAssertNotNil(jsonObject, "JSON should be deserializable")
            } catch {
                XCTFail("JSON deserialization failed: \(error)")
            }
        }
    }

    // MARK: - Event Equality Tests

    func testEventEquality() {
        let timestamp = Date()
        let properties = Properties(["test": "value"])

        let event1 = Event(
            id: "same-id",
            userID: "same-user",
            name: EventName("same_event"),
            properties: properties,
            timestamp: timestamp
        )

        let event2 = Event(
            id: "same-id",
            userID: "same-user",
            name: EventName("same_event"),
            properties: properties,
            timestamp: timestamp
        )

        // Note: Events might not implement Equatable, this tests the structure
        XCTAssertEqual(event1.id, event2.id)
        XCTAssertEqual(event1.userID, event2.userID)
        XCTAssertEqual(event1.name.stringValue, event2.name.stringValue)
        XCTAssertEqual(event1.timestamp, event2.timestamp)
    }

    // MARK: - Event Memory Tests

    func testEventMemoryFootprint() {
        var events: [Event] = []

        // Create many events to test memory usage
        for i in 0..<100 {
            let event = Event(
                userID: "memory-user-\(i)",
                name: EventName("memory_event_\(i)"),
                properties: Properties([
                    "index": i,
                    "data": "memory test data \(i)"
                ])
            )
            events.append(event)
        }

        XCTAssertEqual(events.count, 100)

        // Verify some random events
        XCTAssertEqual(events[0].userID, "memory-user-0")
        XCTAssertEqual(events[50].userID, "memory-user-50")
        XCTAssertEqual(events[99].userID, "memory-user-99")
    }

    // MARK: - Event Thread Safety Tests

    func testEventConcurrentCreation() {
        let expectation = XCTestExpectation(description: "Concurrent event creation should not crash")
        expectation.expectedFulfillmentCount = 10

        for i in 0..<10 {
            DispatchQueue.global().async {
                let event = Event(
                    userID: "concurrent-user-\(i)",
                    name: EventName("concurrent_event"),
                    properties: Properties([
                        "thread_id": i,
                        "timestamp": Date().timeIntervalSince1970
                    ])
                )

                XCTAssertFalse(event.id.isEmpty)
                XCTAssertEqual(event.userID, "concurrent-user-\(i)")
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 2.0)
    }

    // MARK: - Event Description Tests

    func testEventDescription() {
        let event = Event(
            userID: "description-user",
            name: EventName("description_event"),
            properties: Properties(["desc": "test"])
        )

        let description = String(describing: event)
        XCTAssertFalse(description.isEmpty, "Event should have string representation")
        XCTAssertTrue(description.contains("Event"), "Description should identify the type")
    }

    // MARK: - Edge Case Tests

    func testEventWithNilValues() {
        // Test event with properties that might contain nil-like values
        let properties = Properties([
            "null_string": "",
            "zero_number": 0,
            "false_bool": false
        ])

        let event = Event(
            userID: "nil-test-user",
            name: EventName("nil_test_event"),
            properties: properties
        )

        XCTAssertEqual(event.properties.count, 3)
        XCTAssertEqual(event.properties.string(for: "null_string"), "")
        XCTAssertEqual(event.properties.int(for: "zero_number"), 0)
        XCTAssertEqual(event.properties.bool(for: "false_bool"), false)
    }

    func testEventWithLargeProperties() {
        let largeString = String(repeating: "large data ", count: 1000)
        let largeArray = Array(0..<1000)

        let properties = Properties([
            "large_string": largeString,
            "large_array": largeArray,
            "normal_prop": "small value"
        ])

        let event = Event(
            userID: "large-props-user",
            name: EventName("large_props_event"),
            properties: properties
        )

        XCTAssertEqual(event.properties.count, 3)
        XCTAssertEqual(event.properties.string(for: "large_string"), largeString)
        XCTAssertEqual(event.properties.string(for: "normal_prop"), "small value")
    }
}
