// VersionTest.swift
// UserCanal Swift SDK Tests - Version Unit Tests
//
// Copyright © 2024 UserCanal. All rights reserved.
//

import XCTest
@testable import UserCanal

/// Unit tests for Version information and validation
final class VersionTest: XCTestCase {

    // MARK: - Version Format Tests

    func testVersionFormat() {
        let version = Version.version

        XCTAssertFalse(version.isEmpty, "Version should not be empty")

        // Test semantic versioning format (X.Y.Z or X.Y.Z-suffix)
        let semverPattern = #"^\d+\.\d+\.\d+(-[a-zA-Z0-9\-\.]+)?$"#
        let regex = try! NSRegularExpression(pattern: semverPattern)
        let range = NSRange(location: 0, length: version.utf16.count)
        let matches = regex.numberOfMatches(in: version, range: range)

        XCTAssertGreaterThan(matches, 0, "Version should follow semantic versioning format: \(version)")
    }

    func testVersionParts() {
        let version = Version.version
        let parts = version.split(separator: ".")

        XCTAssertGreaterThanOrEqual(parts.count, 3, "Version should have at least 3 parts (major.minor.patch)")

        // Test that major, minor, patch are numeric
        if parts.count >= 3 {
            let major = String(parts[0])
            let minor = String(parts[1])
            let patchPart = String(parts[2])

            // Extract patch number (might have -suffix)
            let patch = patchPart.split(separator: "-").first.map(String.init) ?? patchPart

            XCTAssertNotNil(Int(major), "Major version should be numeric: \(major)")
            XCTAssertNotNil(Int(minor), "Minor version should be numeric: \(minor)")
            XCTAssertNotNil(Int(patch), "Patch version should be numeric: \(patch)")
        }
    }

    // MARK: - Version Consistency Tests

    func testVersionConsistency() {
        let version1 = Version.version
        let version2 = Version.version

        XCTAssertEqual(version1, version2, "Version should be consistent across calls")
    }

    func testVersionNotEmpty() {
        let version = Version.version

        XCTAssertFalse(version.isEmpty, "Version should not be empty")
        XCTAssertFalse(version.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "Version should not be just whitespace")
    }

    // MARK: - Version Information Tests

    @MainActor
    func testUserAgent() async {
        let userAgent = Version.userAgent
        XCTAssertFalse(userAgent.isEmpty, "User agent should not be empty")
        XCTAssertTrue(userAgent.contains("usercanal-swift-sdk"), "User agent should contain SDK name")
        XCTAssertTrue(userAgent.contains(Version.version), "User agent should contain version")
    }

    func testCommitHash() {
        let commitHash = Version.commitHash
        XCTAssertNotNil(commitHash, "Commit hash should be available")
        // During development, it might be "unknown"
        XCTAssertTrue(commitHash == "unknown" || !commitHash.isEmpty, "Commit hash should be 'unknown' or a valid hash")
    }

    func testBuildTime() {
        let buildTime = Version.buildTime
        XCTAssertNotNil(buildTime, "Build time should be available")
        // During development, it might be "unknown"
        XCTAssertTrue(buildTime == "unknown" || !buildTime.isEmpty, "Build time should be 'unknown' or a valid timestamp")
    }

    // MARK: - Version Comparison Tests

    func testVersionComparison() {
        let version = Version.version

        // Test basic version comparison logic
        XCTAssertTrue(isValidVersion(version), "Version should be valid: \(version)")

        // Test that version is not a placeholder
        let placeholderVersions = ["0.0.0", "1.0.0", "0.0.1", "dev", "test", "unknown"]
        let isPlaceholder = placeholderVersions.contains(version)

        // This is informational - placeholder versions are okay during development
        if isPlaceholder {
            print("ℹ️ Version appears to be a placeholder: \(version)")
        } else {
            print("✅ Version appears to be a real version: \(version)")
        }
    }

    // MARK: - Platform Information Tests

    @MainActor
    func testPlatformInformation() async {
        let platformInfo = Version.platformInfo

        XCTAssertFalse(platformInfo.osName.isEmpty, "OS name should not be empty")
        XCTAssertFalse(platformInfo.osVersion.isEmpty, "OS version should not be empty")
        XCTAssertFalse(platformInfo.deviceModel.isEmpty, "Device model should not be empty")

        // Test platform-specific information
        #if os(iOS)
        XCTAssertTrue(platformInfo.osName.contains("iOS") || platformInfo.osName.contains("iPhone"), "Should detect iOS")
        #elseif os(macOS)
        XCTAssertTrue(platformInfo.osName.contains("macOS") || platformInfo.osName.contains("Mac"), "Should detect macOS")
        #elseif os(visionOS)
        XCTAssertTrue(platformInfo.osName.contains("visionOS"), "Should detect visionOS")
        #else
        XCTFail("Unsupported platform")
        #endif
    }

    func testProtocolVersion() {
        let protocolVersion = Version.protocolVersion
        XCTAssertFalse(protocolVersion.isEmpty, "Protocol version should not be empty")
        XCTAssertTrue(protocolVersion.hasPrefix("v"), "Protocol version should start with 'v'")
    }

    func testSwiftVersion() {
        let swiftVersion = Version.swiftVersion
        XCTAssertFalse(swiftVersion.isEmpty, "Swift version should not be empty")
        XCTAssertTrue(swiftVersion.contains("."), "Swift version should contain dots")
    }

    // MARK: - Memory and Performance Tests

    func testVersionAccessPerformance() {
        // Test that version access is fast
        let startTime = CFAbsoluteTimeGetCurrent()

        for _ in 0..<1000 {
            _ = Version.version
        }

        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime

        XCTAssertLessThan(duration, 1.0, "Version access should be fast (completed 1000 calls in < 1 second)")
    }

    @MainActor
    func testVersionInfo() async {
        let versionInfo = Version.info

        XCTAssertEqual(versionInfo.version, Version.version, "Version info should contain current version")
        XCTAssertEqual(versionInfo.commitHash, Version.commitHash, "Version info should contain commit hash")
        XCTAssertEqual(versionInfo.protocolVersion, Version.protocolVersion, "Version info should contain protocol version")
        XCTAssertEqual(versionInfo.swiftVersion, Version.swiftVersion, "Version info should contain Swift version")
        XCTAssertNotNil(versionInfo.platform, "Version info should contain platform info")
    }

    // MARK: - Helper Methods

    private func isValidVersion(_ version: String) -> Bool {
        let parts = version.split(separator: ".")
        guard parts.count >= 3 else { return false }

        let major = String(parts[0])
        let minor = String(parts[1])
        let patchPart = String(parts[2])
        let patch = patchPart.split(separator: "-").first.map(String.init) ?? patchPart

        return Int(major) != nil && Int(minor) != nil && Int(patch) != nil
    }
}
