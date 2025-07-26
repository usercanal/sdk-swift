// PropertiesTest.swift
// UserCanal Swift SDK Tests - Properties Unit Tests
//
// Copyright © 2024 UserCanal. All rights reserved.
//

import XCTest
@testable import UserCanal

/// Unit tests for Properties - property collection validation
final class PropertiesTest: XCTestCase {

    // MARK: - Properties Creation Tests

    func testEmptyProperties() {
        let properties = Properties()

        XCTAssertTrue(properties.isEmpty)
        XCTAssertEqual(properties.count, 0)
        XCTAssertTrue(properties.keys.isEmpty)
    }

    func testPropertiesFromDictionary() {
        let dict: [String: Any] = [
            "string": "test_value",
            "int": 42,
            "double": 3.14159,
            "bool": true
        ]

        let properties = Properties(dict)

        XCTAssertFalse(properties.isEmpty)
        XCTAssertEqual(properties.count, 4)
        XCTAssertEqual(properties.string(for: "string"), "test_value")
        XCTAssertEqual(properties.int(for: "int"), 42)
        XCTAssertEqual(properties.double(for: "double"), 3.14159)
        XCTAssertEqual(properties.bool(for: "bool"), true)
    }

    func testPropertiesFromSendableDictionary() {
        let sendableDict: [String: any Sendable] = [
            "sendable_string": "test",
            "sendable_int": 123,
            "sendable_bool": false
        ]

        let properties = Properties(sendable: sendableDict)

        XCTAssertEqual(properties.count, 3)
        XCTAssertEqual(properties.string(for: "sendable_string"), "test")
        XCTAssertEqual(properties.int(for: "sendable_int"), 123)
        XCTAssertEqual(properties.bool(for: "sendable_bool"), false)
    }

    // MARK: - Properties Access Tests

    func testSubscriptAccess() {
        let properties = Properties([
            "key1": "value1",
            "key2": 100,
            "key3": true
        ])

        XCTAssertEqual(properties["key1"] as? String, "value1")
        XCTAssertEqual(properties["key2"] as? Int, 100)
        XCTAssertEqual(properties["key3"] as? Bool, true)
        XCTAssertNil(properties["nonexistent"])
    }

    func testTypedAccess() {
        let properties = Properties([
            "string_key": "string_value",
            "int_key": 456,
            "double_key": 2.71828,
            "bool_key": false,
            "date_key": Date(timeIntervalSince1970: 1640995200),
            "array_key": [1, 2, 3],
            "nested_key": ["nested": "value"]
        ])

        XCTAssertEqual(properties.string(for: "string_key"), "string_value")
        XCTAssertEqual(properties.int(for: "int_key"), 456)
        XCTAssertEqual(properties.double(for: "double_key"), 2.71828)
        XCTAssertEqual(properties.bool(for: "bool_key"), false)
        XCTAssertNotNil(properties.date(for: "date_key"))
        XCTAssertNotNil(properties.array(for: "array_key"))
        XCTAssertNotNil(properties.properties(for: "nested_key"))
    }

    func testInvalidTypeAccess() {
        let properties = Properties([
            "string_key": "not_a_number",
            "int_key": 42
        ])

        XCTAssertNil(properties.int(for: "string_key"))
        XCTAssertNil(properties.string(for: "int_key"))
        XCTAssertNil(properties.bool(for: "nonexistent"))
    }

    // MARK: - Properties Information Tests

    func testKeysProperty() {
        let properties = Properties([
            "key1": "value1",
            "key2": "value2",
            "key3": "value3"
        ])

        let keys = properties.keys
        XCTAssertEqual(keys.count, 3)
        XCTAssertTrue(keys.contains("key1"))
        XCTAssertTrue(keys.contains("key2"))
        XCTAssertTrue(keys.contains("key3"))
    }

    func testContainsKey() {
        let properties = Properties([
            "existing_key": "value"
        ])

        XCTAssertTrue(properties.contains("existing_key"))
        XCTAssertFalse(properties.contains("nonexistent_key"))
    }

    // MARK: - Properties Conversion Tests

    func testDictionaryConversion() {
        let originalDict: [String: Any] = [
            "string": "test",
            "number": 42,
            "bool": true,
            "date": Date()
        ]

        let properties = Properties(originalDict)
        let convertedDict = properties.dictionary

        XCTAssertEqual(convertedDict.count, 3)
        XCTAssertEqual(convertedDict["string"] as? String, "test")
        XCTAssertEqual(convertedDict["number"] as? Int, 42)
        XCTAssertEqual(convertedDict["bool"] as? Bool, true)
    }

    func testJSONSerialization() {
        let properties = Properties([
            "string_prop": "json_test",
            "int_prop": 789,
            "bool_prop": true
        ])

        let jsonData = properties.jsonData
        XCTAssertNotNil(jsonData)

        if let jsonData = jsonData {
            XCTAssertGreaterThan(jsonData.count, 0)

            do {
                let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: [])
                let dict = jsonObject as? [String: Any]
                XCTAssertNotNil(dict)
                XCTAssertEqual(dict?["string_prop"] as? String, "json_test")
                XCTAssertEqual(dict?["int_prop"] as? Int, 789)
                XCTAssertEqual(dict?["bool_prop"] as? Bool, true)
            } catch {
                XCTFail("JSON deserialization failed: \(error)")
            }
        }
    }

    func testJSONStringConversion() {
        let properties = Properties([
            "test": "json_string"
        ])

        let jsonString = properties.jsonString
        XCTAssertNotNil(jsonString)
        XCTAssertFalse(jsonString?.isEmpty ?? true)
    }

    // MARK: - Dictionary Literal Support Tests

    func testDictionaryLiteralInitialization() {
        let properties: Properties = [
            "literal_string": "test",
            "literal_int": 999,
            "literal_bool": false
        ]

        XCTAssertEqual(properties.count, 3)
        XCTAssertEqual(properties.string(for: "literal_string"), "test")
        XCTAssertEqual(properties.int(for: "literal_int"), 999)
        XCTAssertEqual(properties.bool(for: "literal_bool"), false)
    }

    // MARK: - Properties Builder Tests

    func testPropertiesBuilder() {
        let properties = Properties.build { builder in
            builder
                .set("built_string", "builder_test")
                .set("built_int", 123)
                .set("built_bool", true)
        }

        XCTAssertEqual(properties.count, 3)
        XCTAssertEqual(properties.string(for: "built_string"), "builder_test")
        XCTAssertEqual(properties.int(for: "built_int"), 123)
        XCTAssertEqual(properties.bool(for: "built_bool"), true)
    }

    func testPropertiesModification() {
        let originalProperties = Properties(["original": "value"])

        let modifiedProperties = originalProperties.modified { builder in
            builder
                .set("new_key", "new_value")
                .set("original", "modified_value")
        }

        XCTAssertEqual(originalProperties.count, 1)
        XCTAssertEqual(originalProperties.string(for: "original"), "value")

        XCTAssertEqual(modifiedProperties.count, 2)
        XCTAssertEqual(modifiedProperties.string(for: "original"), "modified_value")
        XCTAssertEqual(modifiedProperties.string(for: "new_key"), "new_value")
    }

    func testPropertiesBuilderMerge() {
        let existingProperties = Properties(["existing": "data"])

        let mergedProperties = Properties.build { builder in
            builder
                .merge(with: existingProperties)
                .set("additional", "info")
        }

        XCTAssertEqual(mergedProperties.count, 2)
        XCTAssertEqual(mergedProperties.string(for: "existing"), "data")
        XCTAssertEqual(mergedProperties.string(for: "additional"), "info")
    }

    func testPropertiesBuilderRemove() {
        let properties = Properties.build { builder in
            builder
                .set("keep", "this")
                .set("remove", "this")
                .remove("remove")
        }

        XCTAssertEqual(properties.count, 1)
        XCTAssertEqual(properties.string(for: "keep"), "this")
        XCTAssertNil(properties["remove"])
    }

    // MARK: - Collection Conformance Tests

    func testCollectionIteration() {
        let properties = Properties([
            "first": "value1",
            "second": "value2",
            "third": "value3"
        ])

        var iteratedKeys: Set<String> = []
        var iteratedValues: [Any] = []

        for (key, value) in properties {
            iteratedKeys.insert(key)
            iteratedValues.append(value)
        }

        XCTAssertEqual(iteratedKeys.count, 3)
        XCTAssertTrue(iteratedKeys.contains("first"))
        XCTAssertTrue(iteratedKeys.contains("second"))
        XCTAssertTrue(iteratedKeys.contains("third"))
        XCTAssertEqual(iteratedValues.count, 3)
    }

    func testCollectionIndexing() {
        let properties = Properties([
            "indexed": "value"
        ])

        let startIndex = properties.startIndex
        let endIndex = properties.endIndex

        XCTAssertNotEqual(startIndex, endIndex)

        let element = properties[startIndex]
        XCTAssertEqual(element.key, "indexed")
        XCTAssertEqual(element.value as? String, "value")
    }

    // MARK: - Complex Data Types Tests

    func testNestedProperties() {
        let nestedDict = [
            "level1": [
                "level2": [
                    "level3": "deep_value"
                ]
            ]
        ]

        let properties = Properties(nestedDict)

        XCTAssertEqual(properties.count, 1)
        let level1Props = properties.properties(for: "level1")
        XCTAssertNotNil(level1Props)

        if let level1Props = level1Props {
            let level2Props = level1Props.properties(for: "level2")
            XCTAssertNotNil(level2Props)

            if let level2Props = level2Props {
                XCTAssertEqual(level2Props.string(for: "level3"), "deep_value")
            }
        }
    }

    func testArrayProperties() {
        let properties = Properties([
            "simple_array": [1, 2, 3],
            "mixed_array": ["string", 42, true, 3.14],
            "nested_array": [[1, 2], [3, 4]]
        ])

        let simpleArray = properties.array(for: "simple_array")
        XCTAssertNotNil(simpleArray)
        XCTAssertEqual(simpleArray?.count, 3)

        let mixedArray = properties.array(for: "mixed_array")
        XCTAssertNotNil(mixedArray)
        XCTAssertEqual(mixedArray?.count, 4)

        let nestedArray = properties.array(for: "nested_array")
        XCTAssertNotNil(nestedArray)
        XCTAssertEqual(nestedArray?.count, 2)
    }

    // MARK: - Edge Cases Tests

    func testEmptyStringKeys() {
        let properties = Properties([
            "": "empty_key_value",
            " ": "space_key_value"
        ])

        XCTAssertEqual(properties.count, 2)
        XCTAssertEqual(properties.string(for: ""), "empty_key_value")
        XCTAssertEqual(properties.string(for: " "), "space_key_value")
    }

    func testNilValues() {
        // Properties should handle nil values gracefully
        let properties = Properties([
            "nil_value": NSNull(),
            "empty_string": "",
            "zero_number": 0,
            "false_bool": false
        ])

        XCTAssertEqual(properties.count, 4)
        XCTAssertEqual(properties.string(for: "empty_string"), "")
        XCTAssertEqual(properties.int(for: "zero_number"), 0)
        XCTAssertEqual(properties.bool(for: "false_bool"), false)
    }

    func testLargeProperties() {
        var largeDict: [String: Any] = [:]
        for i in 0..<1000 {
            largeDict["key_\(i)"] = "value_\(i)"
        }

        let properties = Properties(largeDict)

        XCTAssertEqual(properties.count, 1000)
        XCTAssertEqual(properties.string(for: "key_0"), "value_0")
        XCTAssertEqual(properties.string(for: "key_500"), "value_500")
        XCTAssertEqual(properties.string(for: "key_999"), "value_999")
    }

    // MARK: - Thread Safety Tests

    func testConcurrentAccess() {
        let properties = Properties([
            "concurrent": "test",
            "thread_safe": true
        ])

        let expectation = XCTestExpectation(description: "Concurrent access should not crash")
        expectation.expectedFulfillmentCount = 10

        for _ in 0..<10 {
            DispatchQueue.global().async {
                let value = properties.string(for: "concurrent")
                XCTAssertEqual(value, "test")

                let bool = properties.bool(for: "thread_safe")
                XCTAssertEqual(bool, true)

                let count = properties.count
                XCTAssertEqual(count, 2)

                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 2.0)
    }

    // MARK: - Performance Tests

    func testPropertiesPerformance() {
        let largeDict = (0..<10000).reduce(into: [String: Any]()) { dict, i in
            dict["performance_key_\(i)"] = "performance_value_\(i)"
        }

        let startTime = CFAbsoluteTimeGetCurrent()
        let properties = Properties(largeDict)
        let endTime = CFAbsoluteTimeGetCurrent()

        XCTAssertEqual(properties.count, 10000)
        XCTAssertLessThan(endTime - startTime, 1.0, "Properties creation should be fast")
    }

    func testPropertiesAccessPerformance() {
        let properties = Properties([
            "perf_test": "performance_value"
        ])

        let startTime = CFAbsoluteTimeGetCurrent()

        for _ in 0..<10000 {
            _ = properties.string(for: "perf_test")
        }

        let endTime = CFAbsoluteTimeGetCurrent()

        XCTAssertLessThan(endTime - startTime, 1.0, "Properties access should be fast")
    }

    // MARK: - Memory Tests

    func testPropertiesMemoryFootprint() {
        var propertiesArray: [Properties] = []

        for i in 0..<100 {
            let properties = Properties([
                "memory_test_\(i)": "value_\(i)",
                "index": i
            ])
            propertiesArray.append(properties)
        }

        XCTAssertEqual(propertiesArray.count, 100)

        // Verify some random properties
        XCTAssertEqual(propertiesArray[0].string(for: "memory_test_0"), "value_0")
        XCTAssertEqual(propertiesArray[50].string(for: "memory_test_50"), "value_50")
        XCTAssertEqual(propertiesArray[99].string(for: "memory_test_99"), "value_99")
    }
}
