// ConfigurationTest.swift
// UserCanal Swift SDK Tests - Configuration Unit Tests
//
// Copyright © 2024 UserCanal. All rights reserved.
//

import XCTest
@testable import UserCanal

/// Unit tests for UserCanalConfig - SDK configuration validation
final class ConfigurationTest: XCTestCase {

    // MARK: - Default Configuration Tests

    func testDefaultConfiguration() {
        let config = UserCanalConfig()

        XCTAssertEqual(config.endpoint, UserCanalConfig.Defaults.endpoint)
        XCTAssertEqual(config.batchSize, UserCanalConfig.Defaults.batchSize)
        XCTAssertEqual(config.flushInterval, UserCanalConfig.Defaults.flushInterval)
        XCTAssertEqual(config.maxOfflineEvents, UserCanalConfig.Defaults.maxOfflineEvents)
        XCTAssertEqual(config.enableDebugLogging, UserCanalConfig.Defaults.enableDebugLogging)
        XCTAssertEqual(config.enableOfflineStorage, UserCanalConfig.Defaults.enableOfflineStorage)
        XCTAssertEqual(config.generateEventIds, UserCanalConfig.Defaults.generateEventIds)
    }

    // MARK: - Custom Configuration Tests

    func testCustomConfiguration() {
        let config = UserCanalConfig(
            endpoint: "https://custom.usercanal.com",
            batchSize: 200,
            flushInterval: .seconds(60),
            maxOfflineEvents: 2000,
            enableDebugLogging: true,
            enableOfflineStorage: true,
            generateEventIds: false
        )

        XCTAssertEqual(config.endpoint, "https://custom.usercanal.com")
        XCTAssertEqual(config.batchSize, 200)
        XCTAssertEqual(config.flushInterval, .seconds(60))
        XCTAssertEqual(config.maxOfflineEvents, 2000)
        XCTAssertTrue(config.enableDebugLogging)
        XCTAssertTrue(config.enableOfflineStorage)
        XCTAssertFalse(config.generateEventIds)
    }

    // MARK: - Endpoint Validation Tests

    func testDefaultEndpoint() {
        let config = UserCanalConfig()
        XCTAssertFalse(config.endpoint.isEmpty, "Default endpoint should not be empty")
        XCTAssertTrue(config.endpoint.hasPrefix("http"), "Endpoint should be a valid URL")
    }

    func testCustomEndpoint() {
        let customEndpoint = "https://custom.usercanal.com"
        let config = UserCanalConfig(endpoint: customEndpoint)
        XCTAssertEqual(config.endpoint, customEndpoint, "Custom endpoint should be preserved")
    }

    func testEndpointVariations() {
        let validEndpoints = [
            "https://api.usercanal.com",
            "https://custom.usercanal.com",
            "https://staging.usercanal.com",
            "http://localhost:8080",
            "https://api.custom-domain.com"
        ]

        for endpoint in validEndpoints {
            let config = UserCanalConfig(endpoint: endpoint)
            XCTAssertEqual(config.endpoint, endpoint, "Valid endpoint should be preserved: \(endpoint)")
        }
    }

    // MARK: - Duration Parameter Tests

    func testFlushIntervalValidation() {
        let validIntervals: [Duration] = [.seconds(1), .seconds(5), .seconds(30), .seconds(60), .seconds(300)]

        for interval in validIntervals {
            let config = UserCanalConfig(flushInterval: interval)
            XCTAssertEqual(config.flushInterval, interval, "Valid flush interval should be preserved: \(interval)")
        }
    }

    func testFlushIntervalBoundaries() {
        // Test edge cases
        let edgeCases: [Duration] = [.milliseconds(100), .seconds(0), .seconds(3600)]

        for interval in edgeCases {
            let config = UserCanalConfig(flushInterval: interval)
            XCTAssertEqual(config.flushInterval, interval, "Edge case flush interval should be stored: \(interval)")
        }
    }

    func testBatchSizeValidation() {
        let validSizes = [1, 10, 100, 500, 1000]

        for size in validSizes {
            let config = UserCanalConfig(batchSize: size)
            XCTAssertEqual(config.batchSize, size, "Valid batch size should be preserved: \(size)")
        }
    }

    func testBatchSizeBoundaries() {
        let edgeCases = [1, 10000]

        for size in edgeCases {
            let config = UserCanalConfig(batchSize: size)
            XCTAssertEqual(config.batchSize, size, "Edge case batch size should be stored: \(size)")
        }
    }

    func testMaxOfflineEventsValidation() {
        let validCounts = [0, 100, 1000, 5000, 10000]

        for count in validCounts {
            let config = UserCanalConfig(maxOfflineEvents: count)
            XCTAssertEqual(config.maxOfflineEvents, count, "Valid offline events count should be preserved: \(count)")
        }
    }

    // MARK: - Boolean Flag Tests

    func testBooleanFlags() {
        // Test all combinations of boolean flags
        let flagCombinations = [
            (debug: true, offline: true, generateIds: true),
            (debug: true, offline: true, generateIds: false),
            (debug: true, offline: false, generateIds: true),
            (debug: true, offline: false, generateIds: false),
            (debug: false, offline: true, generateIds: true),
            (debug: false, offline: true, generateIds: false),
            (debug: false, offline: false, generateIds: true),
            (debug: false, offline: false, generateIds: false)
        ]

        for combination in flagCombinations {
            let config = UserCanalConfig(
                enableDebugLogging: combination.debug,
                enableOfflineStorage: combination.offline,
                generateEventIds: combination.generateIds
            )

            XCTAssertEqual(config.enableDebugLogging, combination.debug)
            XCTAssertEqual(config.enableOfflineStorage, combination.offline)
            XCTAssertEqual(config.generateEventIds, combination.generateIds)
        }
    }

    // MARK: - Configuration Immutability Tests

    func testConfigurationImmutability() {
        let config = UserCanalConfig(
            endpoint: "https://test.com",
            batchSize: 150,
            flushInterval: .seconds(45),
            enableDebugLogging: true
        )

        // Verify values are preserved (testing immutability)
        XCTAssertEqual(config.endpoint, "https://test.com")
        XCTAssertEqual(config.batchSize, 150)
        XCTAssertEqual(config.flushInterval, .seconds(45))
        XCTAssertTrue(config.enableDebugLogging)
    }

    // MARK: - Network Configuration Tests

    func testNetworkConfiguration() {
        let config = UserCanalConfig(
            networkTimeout: .seconds(30),
            maxRetries: 5,
            closeTimeout: .seconds(10)
        )

        XCTAssertEqual(config.networkTimeout, .seconds(30))
        XCTAssertEqual(config.maxRetries, 5)
        XCTAssertEqual(config.closeTimeout, .seconds(10))
    }

    // MARK: - String Representation Tests

    func testConfigurationDescription() {
        let config = UserCanalConfig(
            endpoint: "https://desc.test.com",
            enableDebugLogging: true
        )

        // Test that config can be converted to string (useful for debugging)
        let description = String(describing: config)
        XCTAssertFalse(description.isEmpty, "Configuration should have string representation")
        XCTAssertTrue(description.contains("UserCanalConfig"), "Description should identify the type")
    }

    // MARK: - Memory Tests

    func testConfigurationMemoryFootprint() {
        // Test creating many configurations doesn't cause memory issues
        var configs: [UserCanalConfig] = []

        for i in 0..<100 {
            let config = UserCanalConfig(
                endpoint: "https://memory-test-\(i).com",
                batchSize: i % 500 + 1,
                flushInterval: .seconds(i % 60 + 1)
            )
            configs.append(config)
        }

        XCTAssertEqual(configs.count, 100, "All configurations should be created")

        // Verify some random configs are correct
        XCTAssertEqual(configs[0].endpoint, "https://memory-test-0.com")
        XCTAssertEqual(configs[50].endpoint, "https://memory-test-50.com")
        XCTAssertEqual(configs[99].endpoint, "https://memory-test-99.com")
    }
}
