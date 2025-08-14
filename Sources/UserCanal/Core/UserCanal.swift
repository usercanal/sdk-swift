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
    private var initializationState: InitializationState = .notStarted
    private var onError: ((any Error) -> Void)?
    private var sessionStarted = false
    private var deviceContextSent = false
    private var lastDeviceContextTime: Date?
    private var config: UserCanalConfig = .default
    private var _isOptedOut = false
    private var apiKey: String = ""

    // Event queue for pre-initialization events
    private let eventQueue = EventQueue()
    private let maxQueueSize = 1000

    // Device context refresh timer
    private var deviceContextTimer: Timer?
    private let deviceContextRefresh: TimeInterval = 24 * 60 * 60 // 24 hours

    // MARK: - Initialization State

    private enum InitializationState {
        case notStarted
        case inProgress
        case ready
        case failed(any Error)
    }



    // MARK: - Computed Properties

    private var isReady: Bool {
        if case .ready = initializationState {
            return true
        }
        return false
    }

    // MARK: - Configuration

    /// Configure UserCanal with API key and optional settings (async)
    /// - Parameters:
    ///   - apiKey: Your UserCanal API key
    ///   - endpoint: Custom endpoint (optional)
    ///   - batchSize: Number of events to batch before sending (optional)
    ///   - flushInterval: Interval in seconds between automatic flushes (optional)
    ///   - sessionTimeout: Session timeout in seconds (optional, default: 30 minutes)
    ///   - defaultOptOut: Whether users are opted out by default (optional)
    ///   - generateEventIds: Whether to generate client-side event IDs (optional)
    ///   - onError: Error handling callback (optional)
    public func configure(
        apiKey: String,
        endpoint: String? = nil,
        batchSize: Int? = nil,
        flushInterval: Int? = nil,
        sessionTimeout: TimeInterval? = nil,
        defaultOptOut: Bool? = nil,
        generateEventIds: Bool? = nil,
        logLevel: SystemLogLevel? = nil,
        onError: ((any Error) -> Void)? = nil
    ) async throws {
        self.onError = onError

        guard !apiKey.isEmpty else {
            throw UserCanalError.invalidAPIKey("API key cannot be empty")
        }

        self.apiKey = apiKey

        // Auto-enable debug logging when debug level is set
        let finalLogLevel = logLevel ?? UserCanalConfig.Defaults.logLevel
        let autoDebugLogging = finalLogLevel == .debug || finalLogLevel == .trace

        self.config = try UserCanalConfig(
            endpoint: endpoint ?? UserCanalConfig.Defaults.endpoint,
            batchSize: batchSize ?? UserCanalConfig.Defaults.batchSize,
            flushInterval: flushInterval.map { .seconds(Double($0)) } ?? UserCanalConfig.Defaults.flushInterval,
            enableDebugLogging: autoDebugLogging,
            logLevel: finalLogLevel,
            sessionTimeout: sessionTimeout ?? UserCanalConfig.Defaults.sessionTimeout,
            defaultOptOut: defaultOptOut ?? UserCanalConfig.Defaults.defaultOptOut,
            generateEventIds: generateEventIds ?? UserCanalConfig.Defaults.generateEventIds
        )

        // Set initialization state
        initializationState = .inProgress

        // Initialize client
        self.client = try await UserCanalClient(apiKey: apiKey, config: config)

        // Generate or load anonymous ID
        self.anonymousID = self.getOrCreateAnonymousID()

        // Initialize opt-out state
        self.initializeOptOutState()

        // Start device context refresh timer
        self.startDeviceContextTimer(interval: deviceContextRefresh)

        // Mark as ready and process queued events
        initializationState = .ready
        await processQueuedEvents()

        SDKLogger.info("SDK configured successfully", category: .client)
    }

    /// Configure UserCanal with API key and optional settings (sync - fires and forgets)
    /// - Parameters:
    ///   - apiKey: Your UserCanal API key
    ///   - endpoint: Custom endpoint (optional)
    ///   - batchSize: Number of events to batch before sending (optional)
    ///   - flushInterval: Interval in seconds between automatic flushes (optional)
    ///   - sessionTimeout: Session timeout in seconds (optional, default: 30 minutes)
    ///   - defaultOptOut: Whether users are opted out by default (optional)
    ///   - generateEventIds: Whether to generate client-side event IDs (optional)
    public func configureAsync(
        apiKey: String,
        endpoint: String? = nil,
        batchSize: Int? = nil,
        flushInterval: Int? = nil,
        sessionTimeout: TimeInterval? = nil,
        defaultOptOut: Bool? = nil,
        generateEventIds: Bool? = nil,
        logLevel: SystemLogLevel? = nil
    ) {
        Task {
            do {
                try await configure(
                    apiKey: apiKey,
                    endpoint: endpoint,
                    batchSize: batchSize,
                    flushInterval: flushInterval,
                    sessionTimeout: sessionTimeout,
                    defaultOptOut: defaultOptOut,
                    generateEventIds: generateEventIds,
                    logLevel: logLevel,
                    onError: nil
                )
            } catch {
                initializationState = .failed(error)
                SDKLogger.error("SDK configuration failed", error: error, category: .client)
            }
        }
    }

    // MARK: - Event Tracking

    /// Track an event with optional properties
    /// - Parameters:
    ///   - eventName: Event name (typed or string)
    ///   - properties: Event properties (optional)
    public func track(_ eventName: EventName, properties: Properties = Properties()) {
        guard !_isOptedOut else {
            SDKLogger.debug("Event dropped - user opted out", category: .events)
            return
        }

        let propertiesInfo = properties.count > 0 ? ": \(properties)" : ""
        SDKLogger.debug("Tracked event \"\(eventName.stringValue)\"\(propertiesInfo)", category: .events)

        // If ready, process immediately
        if isReady {
            ensureSessionStarted()
            Task {
                await self.client?.event(
                    userID: getCurrentUserID(),
                    eventName: eventName,
                    properties: properties
                )
            }
        } else {
            // Queue the event for later processing
            Task {
                await eventQueue.enqueue(.track(eventName: eventName, properties: properties), maxSize: maxQueueSize)
            }
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

    // MARK: - Enrichment

    /// Enrich data with contextual information (internal method)
    /// - Parameter event: The enrichment event to send
    private func enrich(event: Event) async {
        guard !_isOptedOut else {
            SDKLogger.debug("Enrichment dropped - user opted out", category: .events)
            return
        }

        let propertiesInfo = event.properties.count > 0 ? ": \(Array(event.properties.keys).prefix(3).joined(separator: ", "))" : ""
        SDKLogger.debug("Enriched with \(event.name.stringValue.replacingOccurrences(of: "_", with: " "))\(propertiesInfo)", category: .events)
        SDKLogger.trace("Enrich event: \(event.name.stringValue)", category: .events)

        // If ready, process immediately
        if isReady {
            ensureSessionStarted()
            Task {

                await self.client?.eventWithType(
                    userID: getCurrentUserID(),
                    eventName: event.name,
                    eventType: event.eventType,
                    properties: event.properties
                )
            }
        } else {
            // Queue the enrichment for later processing
            Task {
                SDKLogger.trace("Queueing enrichment event", category: .events)
                await eventQueue.enqueue(.event(eventType: event.eventType, eventName: event.name, properties: event.properties), maxSize: maxQueueSize)
            }
        }
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
        guard !_isOptedOut else {
            SDKLogger.debug("Revenue event dropped - user opted out", category: .events)
            return
        }

        let propertiesInfo = properties.count > 0 ? ": \(properties)" : ""
        SDKLogger.debug("Tracked revenue \(amount) \(currency) for order \"\(orderID)\"\(propertiesInfo)", category: .events)

        // If ready, process immediately
        if isReady {
            ensureSessionStarted()
            Task {
                await self.client?.eventRevenue(
                    userID: getCurrentUserID(),
                    orderID: orderID,
                    amount: amount,
                    currency: currency,
                    properties: properties
                )
            }
        } else {
            // Queue the event for later processing
            Task {
                await eventQueue.enqueue(.revenue(userID: getCurrentUserID(), orderID: orderID, amount: amount, currency: currency, properties: properties), maxSize: maxQueueSize)
            }
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
        guard !_isOptedOut else {
            SDKLogger.debug("Identify event dropped - user opted out", category: .events)
            return
        }

        let traitsInfo = traits.count > 0 ? ": \(traits)" : ""
        SDKLogger.debug("Identified user \"\(userID)\"\(traitsInfo)", category: .events)

        currentUserID = userID

        // If ready, process immediately
        if isReady {
            ensureSessionStarted()
            Task {
                await self.client?.eventIdentify(userID: userID, traits: traits)
            }
        } else {
            // Queue the event for later processing
            Task {
                await eventQueue.enqueue(.identify(userID: userID, traits: traits), maxSize: maxQueueSize)
            }
        }
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

        // Reset opt-out state to default
        _isOptedOut = config.defaultOptOut
        saveOptOutState(_isOptedOut)

        SDKLogger.debug("User session reset", category: .client)
    }

    /// Associate user with a group
    /// - Parameters:
    ///   - groupID: Group identifier
    ///   - properties: Group properties (optional)
    public func group(_ groupID: String, properties: Properties = Properties()) {
        guard !_isOptedOut else {
            SDKLogger.debug("Group event dropped - user opted out", category: .events)
            return
        }

        let propertiesInfo = properties.count > 0 ? ": \(properties)" : ""
        SDKLogger.debug("Associated user with group \"\(groupID)\"\(propertiesInfo)", category: .events)

        // If ready, process immediately
        if isReady {
            ensureSessionStarted()
            Task {
                await self.client?.eventGroup(
                    userID: getCurrentUserID(),
                    groupID: groupID,
                    properties: properties
                )
            }
        } else {
            // Queue the event for later processing
            Task {
                await eventQueue.enqueue(.group(groupID: groupID, properties: properties), maxSize: maxQueueSize)
            }
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
        let dataInfo = data.count > 0 ? ": \(data)" : ""
        SDKLogger.debug("Log \(level): \(message) [service: \(service)]\(dataInfo)", category: .events)

        guard isReady else {
            return
        }

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

    // MARK: - Identity Resolution

    /// Alias user (identity resolution) - connects previous ID to new user ID
    /// - Parameters:
    ///   - previousId: Previous user identifier (anonymous ID, old user ID, etc.)
    ///   - userId: New user identifier to merge with
    public func alias(_ previousId: String, userId: String) {
        guard !_isOptedOut else {
            SDKLogger.debug("Alias event dropped - user opted out", category: .events)
            return
        }

        SDKLogger.debug("Aliasing user: \(previousId) -> \(userId)", category: .events)

        // If ready, process immediately
        if isReady {
            ensureSessionStarted()
            Task {
                await self.client?.eventAlias(previousId: previousId, userId: userId)
            }
        } else {
            // Queue the alias for later processing
            Task {
                await eventQueue.enqueue(.alias(previousId: previousId, userId: userId), maxSize: maxQueueSize)
            }
        }
    }

    // MARK: - Logging

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

    // MARK: - Opt-out Management

    /// Opt-out the current user from all data collection
    /// Events and logs will be dropped locally without sending to server
    public func optOut() {
        _isOptedOut = true
        saveOptOutState(true)
        SDKLogger.debug("User opted out of data collection", category: .client)
    }

    /// Opt-in the current user to resume data collection
    /// Restores normal event and log tracking
    public func optIn() {
        _isOptedOut = false
        saveOptOutState(false)
        SDKLogger.debug("User opted in to data collection", category: .client)
    }

    /// Check if the current user is opted out
    /// - Returns: true if user is opted out, false if opted in
    public func isOptedOut() -> Bool {
        return _isOptedOut
    }



    // MARK: - Lifecycle

    /// Manually flush pending events
    /// Use for critical moments like app termination or user logout
    public func flush() async throws {
        guard isReady, let client = client else {
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

        initializationState = .notStarted
        SDKLogger.debug("SDK shutdown", category: .client)
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

        // Note: Device context now handled by SessionManager

        SDKLogger.debug("Session started for user: \(getCurrentUserID())", category: .events)
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
            // Create device context enrichment event
            let deviceContext = DeviceContext()
            let contextData = await deviceContext.getContext()

            // Device context enrichment should be an Event with EventType.ENRICH
            let enrichmentEvent = Event(
                userID: self?.currentUserID ?? "unknown",
                name: EventName("device_context_enrichment"),
                eventType: .context,
                properties: Properties(contextData)
            )

            await self?.enrich(event: enrichmentEvent)

            SDKLogger.trace("Device context sent", category: .device)
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
        return UUID().uuidString
    }



    private func loadAnonymousID() -> String? {
        return UserDefaults.standard.string(forKey: "usercanal_anonymous_id")
    }

    private func saveAnonymousID(_ id: String) {
        UserDefaults.standard.set(id, forKey: "usercanal_anonymous_id")
    }

    // MARK: - Opt-out State Management

    private func initializeOptOutState() {
        // Load saved opt-out state, or use config default
        if let savedState = loadOptOutState() {
            _isOptedOut = savedState
        } else {
            _isOptedOut = config.defaultOptOut
            saveOptOutState(_isOptedOut)
        }

        let status = _isOptedOut ? "opted out" : "opted in"
        SDKLogger.trace("User is \(status) for data collection", category: .client)
    }

    private func loadOptOutState() -> Bool? {
        guard UserDefaults.standard.object(forKey: "usercanal_opt_out") != nil else {
            return nil
        }
        return UserDefaults.standard.bool(forKey: "usercanal_opt_out")
    }

    private func saveOptOutState(_ optedOut: Bool) {
        UserDefaults.standard.set(optedOut, forKey: "usercanal_opt_out")
    }

    // MARK: - Error Handling

    private func handleError(_ error: any Error) {
        SDKLogger.error("SDK error", error: error, category: .error)
        onError?(error)
    }

    // MARK: - Event Queue Management

    private func processQueuedEvents() async {
        let eventsToProcess = await eventQueue.dequeueAll()

        guard !eventsToProcess.isEmpty else { return }

        SDKLogger.debug("Processing \(eventsToProcess.count) queued events", category: .events)

        for event in eventsToProcess {
            switch event {
            case .track(let eventName, let properties):
                // Process track event
                ensureSessionStarted()
                await client?.event(
                    userID: getCurrentUserID(),
                    eventName: eventName,
                    properties: properties
                )

            case .event(let eventType, let eventName, let properties):
                // Process generic event with specific type
                ensureSessionStarted()
                await client?.eventWithType(
                    userID: getCurrentUserID(),
                    eventName: eventName,
                    eventType: eventType,
                    properties: properties
                )

            case .revenue(let userID, let orderID, let amount, let currency, let properties):
                // Process revenue event
                ensureSessionStarted()
                await client?.eventRevenue(
                    userID: userID ?? getCurrentUserID(),
                    orderID: orderID,
                    amount: amount,
                    currency: currency,
                    properties: properties
                )

            case .identify(let userID, let traits):
                // Process identify event
                currentUserID = userID
                ensureSessionStarted()
                await client?.eventIdentify(userID: userID, traits: traits)
                SDKLogger.debug("User identified: \(userID)", category: .events)

            case .group(let groupID, let properties):
                // Process group event
                ensureSessionStarted()
                await client?.eventGroup(
                    userID: getCurrentUserID(),
                    groupID: groupID,
                    properties: properties
                )

            case .alias(let previousId, let userId):
                // Process alias event
                ensureSessionStarted()
                await client?.eventAlias(previousId: previousId, userId: userId)
                SDKLogger.debug("User aliased: \(previousId) -> \(userId)", category: .events)
            }
        }

        SDKLogger.debug("Finished processing queued events", category: .events)
    }
}

// MARK: - Queued Event Types

private enum QueuedEvent {
    case track(eventName: EventName, properties: Properties)
    case event(eventType: EventType, eventName: EventName, properties: Properties)
    case revenue(userID: String?, orderID: String, amount: Double, currency: Currency, properties: Properties)
    case identify(userID: String, traits: Properties)
    case group(groupID: String, properties: Properties)
    case alias(previousId: String, userId: String)
}

// MARK: - Event Queue Actor

private actor EventQueue {
    private var events: [QueuedEvent] = []

    func enqueue(_ event: QueuedEvent, maxSize: Int) {
        // Check queue size limit
        if events.count >= maxSize {
            // Remove oldest event to make room
            events.removeFirst()
            SDKLogger.warning("Event queue full, dropping oldest event", category: .events)
        }

        events.append(event)
        SDKLogger.trace("Event queued (queue size: \(events.count))", category: .events)
    }

    func dequeueAll() -> [QueuedEvent] {
        let allEvents = events
        events.removeAll()
        return allEvents
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
