// EventNameTest.swift
// UserCanal Swift SDK Tests - EventName Unit Tests
//
// Copyright © 2024 UserCanal. All rights reserved.
//

import XCTest
@testable import UserCanal

/// Unit tests for EventName - event name validation and handling
final class EventNameTest: XCTestCase {

    // MARK: - EventName Creation Tests

    func testEventNameInitialization() {
        let eventName = EventName("test_event")

        XCTAssertEqual(eventName.stringValue, "test_event")
        XCTAssertFalse(eventName.stringValue.isEmpty)
    }

    func testEventNameFromString() {
        let testNames = [
            "page_view",
            "user_signup",
            "button_click",
            "purchase_completed",
            "video_played"
        ]

        for name in testNames {
            let eventName = EventName(name)
            XCTAssertEqual(eventName.stringValue, name, "EventName should preserve string: \(name)")
        }
    }

    // MARK: - EventName Validation Tests

    func testValidEventNames() {
        let validNames = [
            "valid_event",
            "ValidEvent",
            "valid-event",
            "valid.event",
            "valid123event",
            "event_123",
            "a",
            "login",
            "logout",
            "page_view",
            "button_click_home_page"
        ]

        for name in validNames {
            let eventName = EventName(name)
            XCTAssertEqual(eventName.stringValue, name, "Valid event name should be accepted: \(name)")
        }
    }

    func testEventNameWithSpecialCharacters() {
        let specialNames = [
            "event with spaces",
            "event@symbol",
            "event#hash",
            "event$dollar",
            "event%percent",
            "event&amp",
            "event(paren)",
            "event+plus",
            "event=equals",
            "event[bracket]",
            "event{brace}",
            "event|pipe",
            "event\\backslash",
            "event:colon",
            "event;semicolon",
            "event\"quote",
            "event'apostrophe",
            "event<less>",
            "event,comma",
            "event?question",
            "event/slash"
        ]

        for name in specialNames {
            let eventName = EventName(name)
            XCTAssertEqual(eventName.stringValue, name, "EventName should preserve special characters: \(name)")
        }
    }

    func testEventNameWithUnicodeCharacters() {
        let unicodeNames = [
            "événement", // French
            "イベント", // Japanese
            "事件", // Chinese
            "событие", // Russian
            "حدث", // Arabic
            "घटना", // Hindi
            "이벤트", // Korean
            "evento_🎉", // Emoji
            "test_αβγ", // Greek letters
            "møde_æøå" // Danish characters
        ]

        for name in unicodeNames {
            let eventName = EventName(name)
            XCTAssertEqual(eventName.stringValue, name, "EventName should preserve Unicode characters: \(name)")
        }
    }

    // MARK: - Edge Case Tests

    func testEmptyEventName() {
        let eventName = EventName("")

        XCTAssertEqual(eventName.stringValue, "")
        XCTAssertTrue(eventName.stringValue.isEmpty)
    }

    func testWhitespaceEventName() {
        let whitespaceNames = [
            " ",
            "  ",
            "\t",
            "\n",
            " \t\n ",
            "   event   ",
            "\tevent\t",
            "\nevent\n"
        ]

        for name in whitespaceNames {
            let eventName = EventName(name)
            XCTAssertEqual(eventName.stringValue, name, "EventName should preserve whitespace: \(name)")
        }
    }

    func testVeryLongEventName() {
        let longName = String(repeating: "long_event_name_", count: 100)
        let eventName = EventName(longName)

        XCTAssertEqual(eventName.stringValue, longName)
        XCTAssertEqual(eventName.stringValue.count, longName.count)
    }

    func testEventNameWithControlCharacters() {
        let controlChars = [
            "event\u{0000}null",
            "event\u{0001}control",
            "event\u{0008}backspace",
            "event\u{0009}tab",
            "event\u{000A}newline",
            "event\u{000D}return",
            "event\u{001F}unit_separator"
        ]

        for name in controlChars {
            let eventName = EventName(name)
            XCTAssertEqual(eventName.stringValue, name, "EventName should preserve control characters: \(name)")
        }
    }

    // MARK: - EventName Equality Tests

    func testEventNameEquality() {
        let name1 = EventName("same_event")
        let name2 = EventName("same_event")
        let name3 = EventName("different_event")

        XCTAssertEqual(name1.stringValue, name2.stringValue, "Same event names should be equal")
        XCTAssertNotEqual(name1.stringValue, name3.stringValue, "Different event names should not be equal")
    }

    func testEventNameCaseSensitivity() {
        let lowerCase = EventName("event_name")
        let upperCase = EventName("EVENT_NAME")
        let mixedCase = EventName("Event_Name")

        XCTAssertNotEqual(lowerCase.stringValue, upperCase.stringValue, "Event names should be case sensitive")
        XCTAssertNotEqual(lowerCase.stringValue, mixedCase.stringValue, "Event names should be case sensitive")
        XCTAssertNotEqual(upperCase.stringValue, mixedCase.stringValue, "Event names should be case sensitive")
    }

    // MARK: - EventName Performance Tests

    func testEventNamePerformance() {
        let testName = "performance_test_event"

        let startTime = CFAbsoluteTimeGetCurrent()

        for _ in 0..<10000 {
            let eventName = EventName(testName)
            _ = eventName.stringValue
        }

        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime

        XCTAssertLessThan(duration, 1.0, "EventName creation should be fast (10000 operations in < 1 second)")
    }

    func testEventNameMemoryFootprint() {
        var eventNames: [EventName] = []

        for i in 0..<1000 {
            let eventName = EventName("memory_test_event_\(i)")
            eventNames.append(eventName)
        }

        XCTAssertEqual(eventNames.count, 1000)

        // Verify some random event names
        XCTAssertEqual(eventNames[0].stringValue, "memory_test_event_0")
        XCTAssertEqual(eventNames[500].stringValue, "memory_test_event_500")
        XCTAssertEqual(eventNames[999].stringValue, "memory_test_event_999")
    }

    // MARK: - EventName Thread Safety Tests

    func testEventNameConcurrency() {
        let expectation = XCTestExpectation(description: "Concurrent EventName creation should not crash")
        expectation.expectedFulfillmentCount = 10

        for i in 0..<10 {
            DispatchQueue.global().async {
                let eventName = EventName("concurrent_event_\(i)")
                XCTAssertEqual(eventName.stringValue, "concurrent_event_\(i)")
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 2.0)
    }

    // MARK: - EventName String Representation Tests

    func testEventNameDescription() {
        let eventName = EventName("description_test")
        let description = String(describing: eventName)

        XCTAssertFalse(description.isEmpty, "EventName should have string representation")
        // The description format depends on implementation
    }

    func testEventNameDebugDescription() {
        let eventName = EventName("debug_test")
        let debugDescription = String(reflecting: eventName)

        XCTAssertFalse(debugDescription.isEmpty, "EventName should have debug description")
        XCTAssertTrue(debugDescription.contains("EventName") || debugDescription.contains("debug_test"),
                     "Debug description should contain type or value information")
    }

    // MARK: - EventName Conversion Tests

    func testEventNameStringConversion() {
        let originalString = "string_conversion_test"
        let eventName = EventName(originalString)
        let convertedString = eventName.stringValue

        XCTAssertEqual(originalString, convertedString, "String conversion should be lossless")
    }

    func testEventNameInterpolation() {
        let baseName = "interpolation"
        let suffix = "test"
        let eventName = EventName("\(baseName)_\(suffix)")

        XCTAssertEqual(eventName.stringValue, "interpolation_test")
    }

    // MARK: - EventName Validation Logic Tests

    func testEventNameValidationRules() {
        // Test common event naming conventions
        let conventionalNames = [
            "snake_case_event",
            "camelCaseEvent",
            "kebab-case-event",
            "dot.case.event",
            "PascalCaseEvent",
            "UPPER_CASE_EVENT"
        ]

        for name in conventionalNames {
            let eventName = EventName(name)
            XCTAssertEqual(eventName.stringValue, name, "Conventional naming should be preserved: \(name)")
        }
    }

    // MARK: - EventName Error Handling Tests

    func testEventNameErrorHandling() {
        // Test that EventName handles various edge cases gracefully
        let edgeCases = [
            "",
            " ",
            "\0",
            String(repeating: "x", count: 10000),
            "normal_event_name"
        ]

        for edgeCase in edgeCases {
            let eventName = EventName(edgeCase)
            // Should not crash or throw
            XCTAssertEqual(eventName.stringValue, edgeCase, "EventName should handle edge case: \(edgeCase.debugDescription)")
        }
    }
}
