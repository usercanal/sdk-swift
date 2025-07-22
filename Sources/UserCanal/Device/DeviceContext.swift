// DeviceContext.swift
// UserCanal Swift SDK
//
// Copyright © 2024 UserCanal. All rights reserved.
//

import Foundation
#if os(iOS) || os(visionOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif
#if canImport(Network)
import Network
#endif

/// Device context collection for automatic enrichment of events
public actor DeviceContext {

    // MARK: - Cached Context

    private var cachedContext: [String: any Sendable]?
    private var lastUpdateTime: Date?
    private let cacheInterval: TimeInterval = 300 // 5 minutes

    // MARK: - Initialization

    public init() {}

    // MARK: - Public Interface

    /// Get current device context as properties
    /// - Returns: Dictionary of device context properties
    public func getContext() async -> [String: any Sendable] {
        // Check if cache is still valid
        if let cached = cachedContext,
           let lastUpdate = lastUpdateTime,
           Date().timeIntervalSince(lastUpdate) < cacheInterval {
            return cached
        }

        // Collect fresh context
        let context = await collectDeviceContext()

        // Cache the result
        cachedContext = context
        lastUpdateTime = Date()

        return context
    }

    /// Force refresh of device context cache
    public func refreshContext() async {
        cachedContext = nil
        lastUpdateTime = nil
        _ = await getContext()
    }

    // MARK: - Context Collection

    private func collectDeviceContext() async -> [String: any Sendable] {
        var context: [String: any Sendable] = [:]

        // Basic device information
        context["device_type"] = await getDeviceType().rawValue
        context["operating_system"] = getOperatingSystem().rawValue
        context["os_version"] = getOSVersion()
        context["device_model"] = await getDeviceModel()

        // App information
        context["app_version"] = getAppVersion()
        context["app_build"] = getAppBuild()
        context["app_bundle_id"] = getBundleIdentifier()

        // Screen information
        if let screenInfo = await getScreenInfo() {
            for (key, value) in screenInfo {
                context[key] = value
            }
        }

        // Memory information
        context["memory_total"] = getTotalMemory()
        context["memory_available"] = getAvailableMemory()

        // Storage information
        if let storageInfo = getStorageInfo() {
            for (key, value) in storageInfo {
                context[key] = value
            }
        }

        // Network information
        if let networkInfo = await getNetworkInfo() {
            for (key, value) in networkInfo {
                context[key] = value
            }
        }

        // Battery information (iOS only)
        #if os(iOS) || os(visionOS)
        if let batteryInfo = await getBatteryInfo() {
            for (key, value) in batteryInfo {
                context[key] = value
            }
        }
        #endif

        // Locale and timezone
        context["locale"] = getLocale()
        context["timezone"] = getTimezone()

        // App state
        context["app_state"] = await getAppState()

        return context
    }

    // MARK: - Device Type Detection

    private func getDeviceType() async -> DeviceType {
        #if os(iOS)
        return await getIOSDeviceType()
        #elseif os(visionOS)
        return .vr
        #elseif os(tvOS)
        return .tv
        #elseif os(watchOS)
        return .watch
        #elseif os(macOS)
        return .desktop
        #else
        return .unknown
        #endif
    }

    #if os(iOS)
    @MainActor
    private func getIOSDeviceType() -> DeviceType {
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            return .mobile
        case .pad:
            return .tablet
        case .tv:
            return .tv
        case .carPlay:
            return .mobile
        case .mac:
            return .desktop
        case .vision:
            return .vr
        @unknown default:
            return .mobile
        }
    }
    #endif

    private func getOperatingSystem() -> OSType {
        #if os(iOS)
        return .iOS
        #elseif os(visionOS)
        return .iOS // visionOS is based on iOS
        #elseif os(macOS)
        return .macOS
        #elseif os(watchOS)
        return .watchOS
        #elseif os(tvOS)
        return .tvOS
        #else
        return .unknown
        #endif
    }

    private func getOSVersion() -> String {
        let processInfo = ProcessInfo.processInfo
        let version = processInfo.operatingSystemVersion
        return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }

    private func getDeviceModel() async -> String {
        #if os(iOS) || os(visionOS)
        return await getIOSDeviceModel()
        #elseif os(macOS)
        return getMacModel()
        #else
        return "Unknown"
        #endif
    }

    #if os(iOS) || os(visionOS)
    @MainActor
    private func getIOSDeviceModel() -> String {
        return UIDevice.current.model
    }
    #endif

    #if os(macOS)
    private func getMacModel() -> String {
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var model = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &model, &size, nil, 0)
        // Remove null termination and convert to String
        if let nullIndex = model.firstIndex(of: 0) {
            let bytes = model[..<nullIndex].map { UInt8(bitPattern: $0) }
            return String(decoding: bytes, as: UTF8.self)
        } else {
            let bytes = model.map { UInt8(bitPattern: $0) }
            return String(decoding: bytes, as: UTF8.self)
        }
    }
    #endif

    // MARK: - App Information

    private func getAppVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    private func getAppBuild() -> String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }

    private func getBundleIdentifier() -> String {
        return Bundle.main.bundleIdentifier ?? "Unknown"
    }

    // MARK: - Screen Information

    private func getScreenInfo() async -> [String: any Sendable]? {
        #if os(iOS) || os(visionOS)
        return await getIOSScreenInfo()
        #elseif os(macOS)
        guard let screen = NSScreen.main else { return nil }
        let frame = screen.frame
        let backingScaleFactor = screen.backingScaleFactor

        return [
            "screen_width": Int(frame.width * backingScaleFactor),
            "screen_height": Int(frame.height * backingScaleFactor),
            "screen_scale": backingScaleFactor,
            "screen_logical_width": Int(frame.width),
            "screen_logical_height": Int(frame.height)
        ]
        #else
        return nil
        #endif
    }

    #if os(iOS) || os(visionOS)
    @MainActor
    private func getIOSScreenInfo() -> [String: any Sendable] {
        let screen = UIScreen.main
        let bounds = screen.bounds
        let scale = screen.scale

        return [
            "screen_width": Int(bounds.width * scale),
            "screen_height": Int(bounds.height * scale),
            "screen_scale": scale,
            "screen_logical_width": Int(bounds.width),
            "screen_logical_height": Int(bounds.height)
        ]
    }
    #endif

    // MARK: - Memory Information

    private func getTotalMemory() -> Int64 {
        return Int64(ProcessInfo.processInfo.physicalMemory)
    }

    private func getAvailableMemory() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }

        if kerr == KERN_SUCCESS {
            return Int64(info.resident_size)
        } else {
            return 0
        }
    }

    // MARK: - Storage Information

    private func getStorageInfo() -> [String: any Sendable]? {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory,
                                                          in: .userDomainMask).first else {
            return nil
        }

        do {
            let values = try documentsPath.resourceValues(forKeys: [
                .volumeAvailableCapacityKey,
                .volumeTotalCapacityKey
            ])

            var storageInfo: [String: any Sendable] = [:]

            if let available = values.volumeAvailableCapacity {
                storageInfo["storage_available"] = available
            }

            if let total = values.volumeTotalCapacity {
                storageInfo["storage_total"] = total
            }

            return storageInfo
        } catch {
            return nil
        }
    }

    // MARK: - Network Information

    private func getNetworkInfo() async -> [String: any Sendable]? {
        // Skip network info collection for now to avoid Swift 6 concurrency issues
        // TODO: Implement network info collection with proper concurrency handling
        return nil
    }

    // MARK: - Battery Information (iOS only)

    #if os(iOS) || os(visionOS)
    @MainActor
    private func getBatteryInfo() async -> [String: any Sendable]? {
        let device = UIDevice.current
        device.isBatteryMonitoringEnabled = true

        guard device.batteryState != .unknown else {
            return nil
        }

        var batteryInfo: [String: any Sendable] = [:]

        batteryInfo["battery_level"] = device.batteryLevel

        switch device.batteryState {
        case .unknown:
            batteryInfo["battery_state"] = "unknown"
        case .unplugged:
            batteryInfo["battery_state"] = "unplugged"
        case .charging:
            batteryInfo["battery_state"] = "charging"
        case .full:
            batteryInfo["battery_state"] = "full"
        @unknown default:
            batteryInfo["battery_state"] = "unknown"
        }

        return batteryInfo
    }
    #endif

    // MARK: - Locale and Timezone

    private func getLocale() -> String {
        return Locale.current.identifier
    }

    private func getTimezone() -> String {
        return TimeZone.current.identifier
    }

    // MARK: - App State

    private func getAppState() async -> String {
        #if os(iOS) || os(visionOS)
        return await getIOSAppState()
        #elseif os(macOS)
        return "unknown" // Cannot access NSApplication.shared from non-main actor
        #else
        return "unknown"
        #endif
    }

    #if os(iOS) || os(visionOS)
    @MainActor
    private func getIOSAppState() -> String {
        switch UIApplication.shared.applicationState {
        case .active:
            return "active"
        case .inactive:
            return "inactive"
        case .background:
            return "background"
        @unknown default:
            return "unknown"
        }
    }
    #endif
}

// MARK: - Extensions

extension DeviceContext {

    /// Get a minimal device context for performance-critical scenarios
    public func getMinimalContext() async -> [String: any Sendable] {
        return [
            "device_type": await getDeviceType().rawValue,
            "operating_system": getOperatingSystem().rawValue,
            "os_version": getOSVersion(),
            "app_version": getAppVersion()
        ]
    }

    /// Check if device context has changed since last collection
    public func hasContextChanged() async -> Bool {
        guard let lastUpdate = lastUpdateTime else { return true }

        // Consider context changed if cache is older than interval
        return Date().timeIntervalSince(lastUpdate) >= cacheInterval
    }
}
