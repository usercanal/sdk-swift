// Version.swift
// UserCanal Swift SDK
//
// Copyright © 2024 UserCanal. All rights reserved.
//

import Foundation
#if os(iOS) || os(visionOS)
import UIKit
#endif

/// Version information for the UserCanal Swift SDK
public struct Version: Sendable {

    // MARK: - Version Information

    /// The current SDK version
    public static let version = "1.0.0-dev"

    /// The Git commit hash (set during build)
    public static let commitHash = "unknown"

    /// The build timestamp (set during build)
    public static let buildTime = "unknown"

    /// The protocol version for compatibility with other SDKs
    public static let protocolVersion = "v1"

    /// The Swift version used to build this SDK
    public static let swiftVersion = "6.0"

    // MARK: - Runtime Information

    /// Current device/platform information
    @MainActor
    public static var platformInfo: PlatformInfo {
        PlatformInfo()
    }

    /// Complete version information
    @MainActor
    public static var info: VersionInfo {
        VersionInfo(
            version: version,
            commitHash: commitHash,
            buildTime: buildTime,
            protocolVersion: protocolVersion,
            swiftVersion: swiftVersion,
            platform: platformInfo
        )
    }

    /// User agent string for network requests
    @MainActor
    public static var userAgent: String {
        let platform = platformInfo
        return "usercanal-swift-sdk/\(version) (\(platform.osName) \(platform.osVersion); \(platform.deviceModel)) Swift/\(swiftVersion)"
    }

    /// Short version string
    public static var short: String {
        version
    }

    /// Whether this is a production build
    public static var isProduction: Bool {
        !version.contains("dev") && !version.contains("beta")
    }
}

// MARK: - Supporting Types

/// Platform-specific information
public struct PlatformInfo: Sendable, Codable {
    public let osName: String
    public let osVersion: String
    public let deviceModel: String
    public let architecture: String

    @MainActor
    public init() {
        #if os(iOS)
        self.osName = "iOS"
        #elseif os(macOS)
        self.osName = "macOS"
        #elseif os(visionOS)
        self.osName = "visionOS"
        #else
        self.osName = "Unknown"
        #endif

        let processInfo = ProcessInfo.processInfo
        self.osVersion = processInfo.operatingSystemVersionString

        #if os(iOS) || os(visionOS)
        self.deviceModel = UIDevice.current.model
        #elseif os(macOS)
        self.deviceModel = "Mac"
        #else
        self.deviceModel = "Unknown"
        #endif

        #if arch(arm64)
        self.architecture = "arm64"
        #elseif arch(x86_64)
        self.architecture = "x86_64"
        #elseif arch(arm)
        self.architecture = "arm"
        #else
        self.architecture = "unknown"
        #endif
    }
}

/// Complete version information structure
public struct VersionInfo: Sendable, Codable {
    public let version: String
    public let commitHash: String
    public let buildTime: String
    public let protocolVersion: String
    public let swiftVersion: String
    public let platform: PlatformInfo

    /// JSON representation of version info
    public var jsonString: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        guard let data = try? encoder.encode(self),
              let string = String(data: data, encoding: .utf8) else {
            return "{\"error\": \"Failed to encode version info\"}"
        }

        return string
    }

    /// Formatted string representation
    public var description: String {
        """
        UserCanal Swift SDK \(version) (Protocol \(protocolVersion))
        Commit: \(commitHash)
        Built: \(buildTime)
        Swift \(swiftVersion) on \(platform.osName) \(platform.osVersion) (\(platform.architecture))
        Device: \(platform.deviceModel)
        """
    }
}

// MARK: - CustomStringConvertible

extension VersionInfo: CustomStringConvertible {}

extension PlatformInfo: CustomStringConvertible {
    public var description: String {
        "\(osName) \(osVersion) on \(deviceModel) (\(architecture))"
    }
}
