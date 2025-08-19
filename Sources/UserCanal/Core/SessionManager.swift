// SessionManager.swift
// UserCanal Swift SDK - Session and Device Management
//
// CONTEXT Event Strategy:
// - Session Start: Once per session (app launch or after 30min+ background)
// - App Background: When user puts app in background
// - App Foreground: Only when returning after session timeout (30min+)
// - App Terminate: When app shuts down
// - Active/Inactive: State tracked but NO context events (too frequent)
//
// Copyright © 2024 UserCanal. All rights reserved.
//

import Foundation
#if os(iOS) || os(visionOS)
import UIKit
#endif

/// Manages session lifecycle and device context for iOS applications
/// Handles session generation, app state changes, and context event sending
public actor SessionManager {

    // MARK: - Properties

    /// Current session ID (16-byte UUID data)
    private var currentSessionID: Data

    /// Current device ID (16-byte UUID data) - persisted in keychain
    private let deviceID: Data

    /// Session timeout interval (default: 30 minutes)
    private let sessionTimeout: TimeInterval

    /// Timestamp when app went to background
    private var backgroundTime: Date?

    /// Current app state
    private var currentAppState: AppState = .unknown

    /// Last sent context event reason to prevent duplicates
    private var lastContextEventReason: String?

    /// Timestamp of last context event to prevent rapid duplicates
    private var lastContextEventTime: Date?

    /// Minimum interval between context events (in seconds)
    private let contextEventCooldown: TimeInterval = 1.0

    /// Reference to client for sending context events
    private weak var client: UserCanalClient?

    /// Device context for comprehensive context events
    private let deviceContext: DeviceContext

    /// Notification center for app lifecycle events
    private let notificationCenter: NotificationCenter

    // MARK: - Constants

    private static let deviceIDKeychainKey = "com.usercanal.device_id"
    public static let defaultSessionTimeout: TimeInterval = 30 * 60 // 30 minutes

    // MARK: - Initialization

    /// Initialize session manager
    /// - Parameters:
    ///   - client: Reference to UserCanal client for sending context events
    ///   - sessionTimeout: Session timeout in seconds (default: 30 minutes)
    ///   - notificationCenter: Notification center for app lifecycle events
    public init(
        client: UserCanalClient? = nil,
        sessionTimeout: TimeInterval = defaultSessionTimeout,
        notificationCenter: NotificationCenter = .default
    ) {
        self.client = client
        self.sessionTimeout = sessionTimeout
        self.notificationCenter = notificationCenter
        self.deviceContext = DeviceContext()

        // Load or generate device ID
        self.deviceID = Self.loadOrGenerateDeviceID()

        // Generate initial session ID
        self.currentSessionID = Self.generateSessionID()

        // Log consolidated session info
        let deviceIdStr = self.deviceID.map { String(format: "%02x", $0) }.joined()
        let sessionIdStr = self.currentSessionID.map { String(format: "%02x", $0) }.joined()
        SDKLogger.info("Session started (Device: \(deviceIdStr), Session: \(sessionIdStr))", category: .session)

        // Send initial context event FIRST, then set up lifecycle observers
        // This prevents duplicate context events on app launch
        Task {
            SDKLogger.trace("Sending initial context event", category: .session)
            await sendInitialContextEvent()

            SDKLogger.trace("Setting up app lifecycle observers", category: .session)
            await setupAppLifecycleObservers()
        }
    }

    // MARK: - Public Interface

    /// Get current session ID
    /// - Returns: Current session ID as 16-byte Data
    public func getCurrentSessionID() -> Data {
        return currentSessionID
    }

    /// Get device ID
    /// - Returns: Device ID as 16-byte Data
    public func getDeviceID() -> Data {
        return deviceID
    }

    /// Force start a new session
    /// Generates new session ID and sends context event
    public func startNewSession(reason: String = "manual") async {
        currentSessionID = Self.generateSessionID()
        await sendContextEvent(reason: reason)
    }

    /// Set client reference for sending context events
    /// - Parameter client: UserCanal client instance
    public func setClient(_ client: UserCanalClient) {
        self.client = client
    }

    /// Get current app state
    /// - Returns: Current app state
    public func getCurrentAppState() -> AppState {
        return currentAppState
    }

    // MARK: - App Lifecycle Management

    private func setupAppLifecycleObservers() {
        #if os(iOS) || os(visionOS)
        // App lifecycle notifications
        notificationCenter.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { await self?.handleAppDidEnterBackground() }
        }

        notificationCenter.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { await self?.handleAppWillEnterForeground() }
        }

        notificationCenter.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { await self?.handleAppDidBecomeActive() }
        }

        notificationCenter.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { await self?.handleAppWillResignActive() }
        }

        notificationCenter.addObserver(
            forName: UIApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { await self?.handleAppWillTerminate() }
        }
        #endif
    }

    // MARK: - App State Handlers

    private func handleAppDidEnterBackground() async {
        backgroundTime = Date()
        currentAppState = .background
        await sendContextEvent(reason: "app_background")
    }

    private func handleAppWillEnterForeground() async {
        let shouldStartNewSession = await shouldCreateNewSession()

        if shouldStartNewSession {
            await startNewSession(reason: "session_timeout")
        }

        currentAppState = .active
        backgroundTime = nil
        await sendContextEvent(reason: "app_foreground")
    }

    private func handleAppDidBecomeActive() async {
        // Only update state, don't send CONTEXT events for active/inactive transitions
        // These happen too frequently during development and aren't needed for session management
        // See FEATURES.md for complete CONTEXT event documentation
        if currentAppState != .active {
            currentAppState = .active
            SDKLogger.debug("App state changed: active", category: .session)
        }
    }

    private func handleAppWillResignActive() async {
        // Only update state, don't send CONTEXT events for active/inactive transitions
        // These happen too frequently during development and aren't needed for session management
        // See FEATURES.md for complete CONTEXT event documentation
        if currentAppState != .inactive {
            currentAppState = .inactive
            SDKLogger.debug("App state changed: inactive", category: .session)
        }
    }

    private func handleAppWillTerminate() async {
        currentAppState = .notRunning
        await sendContextEvent(reason: "app_terminate")
    }

    // MARK: - Session Logic

    private func shouldCreateNewSession() async -> Bool {
        guard let backgroundTime = backgroundTime else {
            return false
        }

        let timeInBackground = Date().timeIntervalSince(backgroundTime)
        return timeInBackground > sessionTimeout
    }

    // MARK: - Context Events

    private func sendContextEvent(reason: String) async {
        guard let client = client else {
            SDKLogger.warning("Client not available for context event", category: .session)
            return
        }

        // Prevent duplicate events with cooldown period
        let now = Date()
        if let lastTime = lastContextEventTime,
           let lastReason = lastContextEventReason,
           lastReason == reason,
           now.timeIntervalSince(lastTime) < contextEventCooldown {
            SDKLogger.trace("Skipping duplicate context event: \(reason)", category: .session)
            return
        }

        // Update tracking
        lastContextEventReason = reason
        lastContextEventTime = now

        // Create context properties with full device context
        let contextProperties = await buildContextProperties(reason: reason)

        // Use more specific event names based on reason
        let eventName: EventName
        switch reason {
        case "session_start":
            eventName = .sessionStarted
        case "app_background":
            eventName = .appBackgrounded
        case "app_foreground":
            eventName = .appForegrounded
        case "app_active":
            eventName = .appActive
        case "app_inactive":
            eventName = .appInactive
        case "app_terminate":
            eventName = .appTerminated
        case "session_timeout":
            eventName = .sessionTimeout
        default:
            eventName = .sessionStarted
        }

        // Create context event
        let contextEvent = Event(
            userID: "system", // Context events use system user
            name: eventName,
            eventType: .track, // Will be overridden to .context by client
            properties: contextProperties
        )

        SDKLogger.info("Context event \"\(eventName.stringValue)\" sent", category: .session)

        // Send context event using internal method with explicit device/session IDs
        await client.eventContext(contextEvent, deviceID: deviceID, sessionID: currentSessionID)
    }

    private func buildContextProperties(reason: String) async -> Properties {
        var contextDict: [String: any Sendable] = [:]

        // Session information
        contextDict["session_reason"] = reason
        contextDict["app_state"] = currentAppState.rawValue

        if let backgroundTime = backgroundTime {
            contextDict["background_duration"] = Date().timeIntervalSince(backgroundTime)
        }

        // Get comprehensive device context and merge it
        SDKLogger.trace("Collecting device context...", category: .session)
        let deviceInfo = await deviceContext.getContext()

        if deviceInfo.isEmpty {
            SDKLogger.warning("Device context is EMPTY! No device data collected!", category: .session)
        } else {
            SDKLogger.trace("Device context collected: \(deviceInfo.count) properties", category: .session)
            // Log first few keys to see what we got
            let firstKeys = Array(deviceInfo.keys.prefix(5))
            SDKLogger.trace("Device context keys: \(firstKeys)", category: .session)
        }

        for (key, value) in deviceInfo {
            contextDict[key] = value
        }

        // Create Properties from the dictionary
        let properties = Properties(sendable: contextDict)
        SDKLogger.trace("Final context properties count: \(properties.count)", category: .session)

        // Log specific device properties we expect
        if let appVersion = properties["app_version"] {
            SDKLogger.trace("✅ app_version found: \(appVersion)", category: .session)
        } else {
            SDKLogger.warning("❌ app_version MISSING", category: .session)
        }

        if let deviceType = properties["device_type"] {
            SDKLogger.trace("✅ device_type found: \(deviceType)", category: .session)
        } else {
            SDKLogger.warning("❌ device_type MISSING", category: .session)
        }

        if let batteryLevel = properties["battery_level"] {
            SDKLogger.trace("✅ battery_level found: \(batteryLevel)", category: .session)
        } else {
            SDKLogger.trace("ℹ️ battery_level not available (normal on simulator)", category: .session)
        }

        return properties
    }

    private func sendInitialContextEvent() async {
        SDKLogger.trace("sendInitialContextEvent() called", category: .session)

        // Small delay to ensure app state is properly initialized
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        SDKLogger.trace("Initial delay complete", category: .session)

        // Update current app state before sending
        #if os(iOS) || os(visionOS)
        let appState = await MainActor.run {
            switch UIApplication.shared.applicationState {
            case .active:
                SDKLogger.trace("App state detected: active", category: .session)
                return AppState.active
            case .inactive:
                SDKLogger.trace("App state detected: inactive", category: .session)
                return AppState.inactive
            case .background:
                SDKLogger.trace("App state detected: background", category: .session)
                return AppState.background
            @unknown default:
                SDKLogger.trace("App state detected: unknown", category: .session)
                return AppState.unknown
            }
        }
        currentAppState = appState
        SDKLogger.trace("Current app state set to: \(appState.rawValue)", category: .session)
        #endif

        // Send session start context event
        lastContextEventReason = nil
        lastContextEventTime = nil
        SDKLogger.trace("Sending session_start context event", category: .session)
        await sendContextEvent(reason: "session_start")
    }

    private func getAppInfo() -> [String: String]? {
        guard let infoDictionary = Bundle.main.infoDictionary else {
            return nil
        }

        var appInfo: [String: String] = [:]

        if let appVersion = infoDictionary["CFBundleShortVersionString"] as? String {
            appInfo["app_version"] = appVersion
        }

        if let buildNumber = infoDictionary["CFBundleVersion"] as? String {
            appInfo["app_build"] = buildNumber
        }

        if let bundleID = infoDictionary["CFBundleIdentifier"] as? String {
            appInfo["app_bundle_id"] = bundleID
        }

        return appInfo.isEmpty ? nil : appInfo
    }

    // MARK: - Device ID Management

    private static func loadOrGenerateDeviceID() -> Data {
        // Try to load existing device ID from keychain
        if let existingDeviceID = loadDeviceIDFromKeychain() {
            return existingDeviceID
        }

        // Generate new device ID and save to keychain
        let newDeviceID = generateDeviceID()
        saveDeviceIDToKeychain(newDeviceID)
        return newDeviceID
    }

    private static func generateDeviceID() -> Data {
        let uuid = UUID().uuid
        return withUnsafeBytes(of: uuid) { Data($0) }
    }

    private static func generateSessionID() -> Data {
        let uuid = UUID().uuid
        return withUnsafeBytes(of: uuid) { Data($0) }
    }

    // MARK: - Keychain Management

    private static func loadDeviceIDFromKeychain() -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: deviceIDKeychainKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess, let data = result as? Data, data.count == 16 {
            return data
        }

        return nil
    }

    private static func saveDeviceIDToKeychain(_ deviceID: Data) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: deviceIDKeychainKey,
            kSecValueData as String: deviceID
        ]

        // Try to add the item
        let addStatus = SecItemAdd(query as CFDictionary, nil)

        // If item already exists, update it
        if addStatus == errSecDuplicateItem {
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: deviceIDKeychainKey
            ]

            let updateAttributes: [String: Any] = [
                kSecValueData as String: deviceID
            ]

            SecItemUpdate(updateQuery as CFDictionary, updateAttributes as CFDictionary)
        }
    }

    // MARK: - Cleanup

    deinit {
        notificationCenter.removeObserver(self)
    }
}

// MARK: - Extensions

extension SessionManager {

    /// Session configuration options
    public struct Configuration {
        public let sessionTimeout: TimeInterval
        public let sendContextEvents: Bool

        public init(
            sessionTimeout: TimeInterval = 30 * 60,
            sendContextEvents: Bool = true
        ) {
            self.sessionTimeout = sessionTimeout
            self.sendContextEvents = sendContextEvents
        }
    }
}

extension UUID {
    /// Convert UUID to 16-byte Data
    var data: Data {
        return withUnsafeBytes(of: uuid) { Data($0) }
    }
}
