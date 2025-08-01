// PackageTests.swift
// UserCanal Swift SDK Tests - Package Information Tests
//
// Copyright © 2024 UserCanal. All rights reserved.
//

import XCTest
@testable import UserCanal

/// Tests for SDK package information and metadata
final class PackageTests: XCTestCase {

    // MARK: - Version Tests

    func testSDKVersion() {
        let version = Version.version

        XCTAssertFalse(version.isEmpty, "SDK version should not be empty")

        // Test semantic versioning format
        let versionParts = version.split(separator: ".")
        XCTAssertGreaterThanOrEqual(versionParts.count, 3, "Version should have at least major.minor.patch")

        // Test that version parts are numeric (ignoring pre-release suffixes)
        if versionParts.count >= 3 {
            let major = String(versionParts[0])
            let minor = String(versionParts[1])
            let patch = String(versionParts[2]).split(separator: "-").first.map(String.init) ?? String(versionParts[2])

            XCTAssertNotNil(Int(major), "Major version should be numeric")
            XCTAssertNotNil(Int(minor), "Minor version should be numeric")
            XCTAssertNotNil(Int(patch), "Patch version should be numeric")
        }
    }

    func testVersionConsistency() {
        let version1 = Version.version
        let version2 = Version.version

        XCTAssertEqual(version1, version2, "Version should be consistent across calls")
    }

    // MARK: - SDK Metadata Tests

    func testSDKMetadata() {
        // Test that we can access basic SDK information
        let version = Version.version
        XCTAssertFalse(version.isEmpty)

        let commitHash = Version.commitHash
        XCTAssertNotNil(commitHash, "Commit hash should be available")

        let buildTime = Version.buildTime
        XCTAssertNotNil(buildTime, "Build time should be available")

        let protocolVersion = Version.protocolVersion
        XCTAssertFalse(protocolVersion.isEmpty, "Protocol version should not be empty")

        let swiftVersion = Version.swiftVersion
        XCTAssertFalse(swiftVersion.isEmpty, "Swift version should not be empty")
    }

    @MainActor
    func testPlatformInfo() async {
        let platformInfo = Version.platformInfo

        XCTAssertFalse(platformInfo.osName.isEmpty, "OS name should not be empty")
        XCTAssertFalse(platformInfo.osVersion.isEmpty, "OS version should not be empty")
        XCTAssertFalse(platformInfo.deviceModel.isEmpty, "Device model should not be empty")
    }

    @MainActor
    func testUserAgent() async {
        let userAgent = Version.userAgent

        XCTAssertFalse(userAgent.isEmpty, "User agent should not be empty")
        XCTAssertTrue(userAgent.contains("usercanal-swift-sdk"), "User agent should contain SDK name")
        XCTAssertTrue(userAgent.contains(Version.version), "User agent should contain version")
    }

    @MainActor
    func testVersionInfo() async {
        let versionInfo = Version.info

        XCTAssertEqual(versionInfo.version, Version.version, "Version info should match current version")
        XCTAssertEqual(versionInfo.commitHash, Version.commitHash, "Version info should match commit hash")
        XCTAssertEqual(versionInfo.protocolVersion, Version.protocolVersion, "Version info should match protocol version")
        XCTAssertEqual(versionInfo.swiftVersion, Version.swiftVersion, "Version info should match Swift version")
        XCTAssertNotNil(versionInfo.platform, "Version info should contain platform info")
    }

    // MARK: - Module Import Tests

    func testModuleImport() {
        // Test that the UserCanal module can be imported and basic types are accessible
        XCTAssertNotNil(UserCanal.self, "UserCanal module should be importable")
        XCTAssertNotNil(Event.self, "Event type should be accessible")
        XCTAssertNotNil(LogEntry.self, "LogEntry type should be accessible")
        XCTAssertNotNil(Properties.self, "Properties type should be accessible")
        XCTAssertNotNil(EventName.self, "EventName type should be accessible")
        XCTAssertNotNil(UserCanalConfig.self, "UserCanalConfig type should be accessible")
        XCTAssertNotNil(Version.self, "Version type should be accessible")
    }

    // MARK: - Platform Tests

    func testPlatformSupport() {
        // Test that we're running on a supported platform
        #if os(iOS)
        XCTAssertTrue(true, "iOS platform supported")
        #elseif os(macOS)
        XCTAssertTrue(true, "macOS platform supported")
        #elseif os(visionOS)
        XCTAssertTrue(true, "visionOS platform supported")
        #else
        XCTFail("Unsupported platform")
        #endif
    }

    // MARK: - Swift Version Tests

    func testSwiftVersion() {
        // Test that we're using a supported Swift version
        #if swift(>=6.0)
        XCTAssertTrue(true, "Swift 6.0+ supported")
        #else
        XCTFail("Unsupported Swift version - requires Swift 6.0+")
        #endif
    }

    // MARK: - Concurrency Support Tests

    func testConcurrencySupport() {
        // Test that async/await is available
        let expectation = XCTestExpectation(description: "Async/await should be supported")

        Task {
            // Simple async operation
            await Task.yield()
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 1.0)
    }

    // MARK: - Memory Tests

    func testMemoryFootprint() {
        // Test that basic SDK types don't cause memory issues
        var versions: [String] = []

        for _ in 0..<100 {
            versions.append(Version.version)
        }

        XCTAssertEqual(versions.count, 100, "Should be able to create many version references")
        XCTAssertTrue(versions.allSatisfy { $0 == Version.version }, "All versions should be identical")
    }
}
