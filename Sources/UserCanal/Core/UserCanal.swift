// UserCanal.swift
// UserCanal Swift SDK - Convenience Interface
//
// Copyright © 2024 UserCanal. All rights reserved.
//

import Foundation

// MARK: - UserCanal Singleton

/// Convenient singleton interface for UserCanal analytics
/// Provides PostHog/Segment-style developer experience with UserCanal's advanced capabilities
@MainActor
public class UserCanal {

    // MARK: - Singleton

    public static let shared = UserCanal()
    private init() {}

    // MARK: - Internal Properties

    private var client: UserCanalClient?
    private var currentUserID: String?
    private var anonymousID: String?
    private var isInitialized = false
    private var onError: ((any Error) -> Void)?
    private var sessionStarted = false
    private var deviceContextSent = false
    private var lastDeviceContextTime: Date?
    private var config: UserCanalConfig = .default

    // Device context refresh timer
    private var deviceContextTimer: Timer?

    // MARK: - Configuration

    /// Configure UserCanal with API key and options
    /// Call this once during app startup
    /// - Parameters:
    ///   - apiKey: Your UserCanal API key
    ///   - endpoint: Custom endpoint (optional)
    ///   - batchSize: Events per batch (optional, default: 50)
    ///   - flushInterval: Seconds between flushes (optional, default: 30)
    ///   - deviceContextRefresh: How often to refresh device context (optional, default: 24 hours)
    ///   - onError: Error callback (optional)
    public func configure(
        apiKey: String,
        endpoint: String? = nil,
        batchSize: Int? = nil,
        flushInterval: TimeInterval? = nil,
        deviceContextRefresh: TimeInterval = 24 * 60 * 60, // 24 hours
        onError: ((any Error) -> Void)? = nil
    ) {
        self.onError = onError

        // Build configuration
        do {
            self.config = try UserCanalConfig(
                endpoint: endpoint ?? UserCanalConfig.Defaults.endpoint,
                batchSize: batchSize ?? UserCanalConfig.Defaults.batchSize,
                flushInterval: flushInterval.map { .seconds($0) } ?? UserCanalConfig.Defaults.flushInterval
            )
        } catch {
            self.handleError(error)
            return
        }

        // Initialize client asynchronously
        Task {
            do {
                self.client = try await UserCanalClient(apiKey: apiKey, config: config)
                self.isInitialized = true

                // Generate or load anonymous ID
                self.anonymousID = self.getOrCreateAnonymousID()

                // Start device context refresh timer
                self.startDeviceContextTimer(interval: deviceContextRefresh)

                SDKLogger.info("UserCanal configured successfully", category: .general)

            } catch {
                self.handleError(error)
            }
        }
    }

    // MARK: - Event Tracking

    /// Track an event with optional properties
    /// - Parameters:
    ///   - eventName: Event name (typed or string)
    ///   - properties: Event properties (optional)
    public func track(_ eventName: EventName, properties: Properties = Properties()) {
        guard isInitialized else {
            handleError(UserCanalError.clientNotInitialized)
            return
        }

        let userID = getCurrentUserID()

        // Ensure session is started and device context is sent
        ensureSessionStarted()

        Task { [weak self] in
            await self?.client?.event(
                userID: userID,
                eventName: eventName,
                properties: properties
            )
        }
    }

    /// Track an event with string name
    /// - Parameters:
    ///   - eventName: Event name as string
    ///   - properties: Event properties (optional)
    public func track(_ eventName: String, properties: Properties = Properties()) {
        track(EventName(eventName), properties: properties)
    }

    /// Track an event with dictionary properties (convenience)
    /// - Parameters:
    ///   - eventName: Event name
    ///   - properties: Event properties as dictionary
    public func track(_ eventName: EventName, properties: [String: Any]) {
        track(eventName, properties: Properties(properties))
    }

    /// Track an event with string name and dictionary properties
    /// - Parameters:
    ///   - eventName: Event name as string
    ///   - properties: Event properties as dictionary
    public func track(_ eventName: String, properties: [String: Any]) {
        track(EventName(eventName), properties: Properties(properties))
    }

    // MARK: - Revenue Tracking

    /// Track a revenue event
    /// - Parameters:
    ///   - amount: Revenue amount
    ///   - currency: Currency code
    ///   - orderID: Order identifier
    ///   - properties: Additional properties (optional)
    public func eventRevenue(
        amount: Double,
        currency: Currency,
        orderID: String,
        properties: Properties = Properties()
    ) {
        guard isInitialized else {
            handleError(UserCanalError.clientNotInitialized)
            return
        }

        let userID = getCurrentUserID()
        ensureSessionStarted()

        Task { [weak self] in
            await self?.client?.eventRevenue(
                userID: userID,
                orderID: orderID,
                amount: amount,
                currency: currency,
                properties: properties
            )
        }
    }

    /// Track revenue with dictionary properties (convenience)
    public func eventRevenue(
        amount: Double,
        currency: Currency,
        orderID: String,
        properties: [String: Any]
    ) {
        eventRevenue(
            amount: amount,
            currency: currency,
            orderID: orderID,
            properties: Properties(properties)
        )
    }

    // MARK: - User Management

    /// Identify the current user
    /// - Parameters:
    ///   - userID: User identifier
    ///   - traits: User traits/properties (optional)
    public func identify(_ userID: String, traits: Properties = Properties()) {
        guard isInitialized else {
            handleError(UserCanalError.clientNotInitialized)
            return
        }

        currentUserID = userID
        ensureSessionStarted()

        Task { [weak self] in
            await self?.client?.eventIdentify(userID: userID, traits: traits)
        }

        SDKLogger.info("User identified: \(userID)", category: .general)
    }

    /// Identify user with dictionary traits (convenience)
    /// - Parameters:
    ///   - userID: User identifier
    ///   - traits: User traits as dictionary
    public func identify(_ userID: String, traits: [String: Any]) {
        identify(userID, traits: Properties(traits))
    }

    /// Reset user session (logout)
    /// Generates new anonymous ID and clears current user
    public func reset() {
        currentUserID = nil
        anonymousID = generateAnonymousID()
        saveAnonymousID(anonymousID!)
        sessionStarted = false
        deviceContextSent = false

        SDKLogger.info("User session reset", category: .general)
    }

    /// Associate user with a group
    /// - Parameters:
    ///   - groupID: Group identifier
    ///   - properties: Group properties (optional)
    public func group(_ groupID: String, properties: Properties = Properties()) {
        guard isInitialized else {
            handleError(UserCanalError.clientNotInitialized)
            return
        }

        let userID = getCurrentUserID()
        ensureSessionStarted()

        Task { [weak self] in
            await self?.client?.eventGroup(
                userID: userID,
                groupID: groupID,
                properties: properties
            )
        }
    }

    /// Associate user with group using dictionary properties (convenience)
    public func group(_ groupID: String, properties: [String: Any]) {
        group(groupID, properties: Properties(properties))
    }

    // MARK: - Logging

    /// Log a message with specified level
    /// - Parameters:
    ///   - level: Log level
    ///   - message: Log message
    ///   - service: Service name (default: "app")
    ///   - data: Additional log data (optional)
    public func log(
        _ level: LogLevel,
        _ message: String,
        service: String = "app",
        data: Properties = Properties()
    ) {
        guard isInitialized else { return }

        Task { [weak self] in
            switch level {
            case .info:
                await self?.client?.logInfo(service: service, message, data: data)
            case .error:
                await self?.client?.logError(service: service, message, data: data)
            case .debug:
                await self?.client?.logDebug(service: service, message, data: data)
            case .warning:
                await self?.client?.logWarning(service: service, message, data: data)
            case .critical:
                await self?.client?.logCritical(service: service, message, data: data)
            case .alert:
                await self?.client?.logAlert(service: service, message, data: data)
            case .emergency:
                await self?.client?.logEmergency(service: service, message, data: data)
            case .notice:
                await self?.client?.logNotice(service: service, message, data: data)
            case .trace:
                await self?.client?.logTrace(service: service, message, data: data)
            }
        }
    }

    /// Log message with dictionary data (convenience)
    public func log(
        _ level: LogLevel,
        _ message: String,
        service: String = "app",
        data: [String: Any]
    ) {
        log(level, message, service: service, data: Properties(data))
    }

    // Convenience logging methods
    public func logInfo(_ message: String, service: String = "app", data: Properties = Properties()) {
        log(.info, message, service: service, data: data)
    }

    public func logError(_ message: String, service: String = "app", data: Properties = Properties()) {
        log(.error, message, service: service, data: data)
    }

    public func logDebug(_ message: String, service: String = "app", data: Properties = Properties()) {
        log(.debug, message, service: service, data: data)
    }

    public func logWarning(_ message: String, service: String = "app", data: Properties = Properties()) {
        log(.warning, message, service: service, data: data)
    }

    // MARK: - Lifecycle

    /// Manually flush pending events
    /// Use for critical moments like app termination or user logout
    public func flush() async throws {
        guard isInitialized, let client = client else {
            throw UserCanalError.clientNotInitialized
        }

        try await client.flush()
    }

    /// Shutdown the client and cleanup resources
    public func shutdown() async throws {
        deviceContextTimer?.invalidate()
        deviceContextTimer = nil

        if let client = client {
            try await client.close()
        }

        isInitialized = false
        SDKLogger.info("UserCanal shutdown", category: .general)
    }

    // MARK: - Internal Session Management

    private func getCurrentUserID() -> String {
        return currentUserID ?? getAnonymousID()
    }

    private func getAnonymousID() -> String {
        if let anonymousID = anonymousID {
            return anonymousID
        }

        let newID = getOrCreateAnonymousID()
        anonymousID = newID
        return newID
    }

    private func ensureSessionStarted() {
        guard !sessionStarted else { return }

        sessionStarted = true

        // Send device context enrichment once per session
        sendDeviceContextIfNeeded()

        SDKLogger.debug("Session started for user: \(getCurrentUserID())", category: .general)
    }

    private func sendDeviceContextIfNeeded() {
        let now = Date()

        // Send if never sent, or if 24+ hours since last send
        let shouldSend = !deviceContextSent ||
                        lastDeviceContextTime.map { now.timeIntervalSince($0) > 24 * 60 * 60 } ?? true

        guard shouldSend else { return }

        deviceContextSent = true
        lastDeviceContextTime = now

        Task { [weak self] in
            // Create device context enrichment log entry
            let deviceContext = DeviceContext()
            let contextData = await deviceContext.getContext()

            let enrichmentEntry = LogEntry(
                eventType: .enrich,
                level: .info,
                service: "usercanal-sdk",
                message: "Device context enrichment",
                data: Properties(contextData)
            )

            await self?.client?.log(entry: enrichmentEntry)

            SDKLogger.debug("Device context sent", category: .general)
        }
    }

    private func startDeviceContextTimer(interval: TimeInterval) {
        deviceContextTimer?.invalidate()

        deviceContextTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task {
                await self?.sendDeviceContextIfNeeded()
            }
        }
    }

    // MARK: - Anonymous ID Management

    private func getOrCreateAnonymousID() -> String {
        if let stored = loadAnonymousID() {
            return stored
        }

        let newID = generateAnonymousID()
        saveAnonymousID(newID)
        return newID
    }

    private func generateAnonymousID() -> String {
        return "anon_" + UUID().uuidString.lowercased().replacingOccurrences(of: "-", with: "")
    }

    private func loadAnonymousID() -> String? {
        return UserDefaults.standard.string(forKey: "usercanal_anonymous_id")
    }

    private func saveAnonymousID(_ id: String) {
        UserDefaults.standard.set(id, forKey: "usercanal_anonymous_id")
    }

    // MARK: - Error Handling

    private func handleError(_ error: any Error) {
        SDKLogger.error("UserCanal error", error: error, category: .general)
        onError?(error)
    }
}

// MARK: - Additional Common Event Names

extension EventName {

    // Screen Events
    public static let screenInteraction = EventName("Screen Interaction")

    // Feature Events
    public static let buttonTapped = EventName("Button Tapped")

    // Content Events
    public static let contentViewed = EventName("Content Viewed")
    public static let contentShared = EventName("Content Shared")

    // Purchase Events
    public static let subscriptionPurchased = EventName("Subscription Purchased")
    public static let subscriptionCancelled = EventName("Subscription Cancelled")
    public static let purchaseCompleted = EventName("Purchase Completed")
}
