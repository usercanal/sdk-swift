// UserCanalClient.swift
// UserCanal Swift SDK
//
// Copyright © 2024 UserCanal. All rights reserved.
//

import Foundation

// MARK: - UserCanal Client

/// Main client for UserCanal analytics and logging
/// Thread-safe actor implementation for Swift 6 concurrency
public actor UserCanalClient {

    // MARK: - Properties

    /// Client configuration
    private let config: UserCanalConfig

    /// API key for authentication
    private let apiKey: String

    /// Internal client state
    private var state: ClientState = .initializing

    /// Internal batching system
    private var batcher: BatchManager?

    /// Internal network client
    private var networkClient: NetworkClient?

    /// Device context collector
    private var deviceContext: DeviceContext?

    /// Client statistics
    private var stats: ClientStats = ClientStats()

    // MARK: - Client State

    private enum ClientState: Sendable, Equatable {
        case initializing
        case ready
        case closing
        case closed
        case failed(any Error)

        static func == (lhs: ClientState, rhs: ClientState) -> Bool {
            switch (lhs, rhs) {
            case (.initializing, .initializing),
                 (.ready, .ready),
                 (.closing, .closing),
                 (.closed, .closed):
                return true
            case (.failed, .failed):
                return true // Compare by case, not error details
            default:
                return false
            }
        }
    }

    // MARK: - Initialization

    /// Create a new UserCanal client
    /// - Parameters:
    ///   - apiKey: Your UserCanal API key
    ///   - config: Optional configuration (uses defaults if not provided)
    public init(apiKey: String, config: UserCanalConfig = .default) async throws {
        guard !apiKey.isEmpty else {
            throw UserCanalError.invalidAPIKey("API key cannot be empty")
        }

        self.apiKey = apiKey
        self.config = config

        // Configure SDK logging with user settings
        // Auto-enable debug logging when debug level is set
        let debugEnabled = config.enableDebugLogging || config.logLevel == .debug || config.logLevel == .trace
        SDKLogger.configure(debugEnabled: debugEnabled, logLevel: config.logLevel)

        SDKLogger.trace("Client initialization starting", category: .client)

        do {
            // Initialize network client (no connection yet)
            let networkClient = try NetworkClient(apiKey: apiKey, endpoint: config.endpoint)
            self.networkClient = networkClient

            // Convert API key to data
            guard let apiKeyData = Data(fromHexString: apiKey) else {
                throw UserCanalError.invalidAPIKey("Invalid hex format")
            }

            // Initialize batch manager
            let batchManager = BatchManager(config: config, apiKey: apiKeyData, networkClient: networkClient)
            self.batcher = batchManager

            // Initialize device context if enabled
            if config.collectDeviceContext {
                self.deviceContext = DeviceContext()
            }

            self.state = .ready
            SDKLogger.info("Client ready", category: .client)

        } catch {
            self.state = .failed(error)
            SDKLogger.error("Client initialization failed", error: error, category: .client)
            throw error
        }
    }

    /// Create a new UserCanal client with configuration builder
    /// - Parameters:
    ///   - apiKey: Your UserCanal API key
    ///   - configBuilder: Configuration builder closure
    public init(
        apiKey: String,
        configBuilder: () throws -> UserCanalConfig
    ) async throws {
        let config = try configBuilder()
        try await self.init(apiKey: apiKey, config: config)
    }

    // MARK: - Event Tracking

    /// Track an analytics event (fire-and-forget)
    /// - Parameters:
    ///   - userID: User identifier
    ///   - name: Event name
    ///   - properties: Event properties (optional)
    public func event(
        userID: String,
        eventName: EventName,
        properties: Properties = Properties()
    ) {
        Task { [weak self] in
            await self?.trackEvent(userID: userID, name: eventName, properties: properties)
        }
    }

    /// Track an analytics event with specific event type (fire-and-forget)
    /// - Parameters:
    ///   - userID: User identifier
    ///   - eventName: Event name
    ///   - eventType: Event type for CDP processing
    ///   - properties: Event properties (optional)
    public func eventWithType(
        userID: String,
        eventName: EventName,
        eventType: EventType,
        properties: Properties = Properties()
    ) {
        Task { [weak self] in
            await self?.trackEventWithType(userID: userID, name: eventName, eventType: eventType, properties: properties)
        }
    }

    /// Internal async event tracking with specific event type
    private func trackEventWithType(
        userID: String,
        name: EventName,
        eventType: EventType,
        properties: Properties
    ) async {
        do {
            SDKLogger.trace("trackEventWithType called with event type: \(eventType) (raw: \(eventType.rawValue))", category: .events)

            guard state == .ready else {
                SDKLogger.warning("Client not ready, dropping event", category: .client)
                return
            }

            // Validate input
            guard !userID.isEmpty else {
                SDKLogger.error("Empty user ID, dropping event", category: .general)
                return
            }

            // Create event with specific type
            var event = Event(
                userID: userID,
                name: name,
                eventType: eventType,
                properties: properties,
                generateId: config.generateEventIds
            )

            SDKLogger.trace("Created event with type: \(event.eventType) (raw: \(event.eventType.rawValue))", category: .events)

            // Enrich with device context if enabled
            event = await enrichEventWithDeviceContext(event)

            // Validate event
            try event.validate()

            // Send to batch manager
            guard let batcher = self.batcher else {
                SDKLogger.error("Batch manager not initialized", category: .general)
                return
            }

            try await batcher.addEvent(event)

            SDKLogger.trace("Event sent: \(name.stringValue)", category: .events)

        } catch {
            SDKLogger.error("Failed to track event: \(error.localizedDescription)", category: .events)
        }
    }

    /// Internal async event tracking
    private func trackEvent(
        userID: String,
        name: EventName,
        properties: Properties
    ) async {
        do {
            guard state == .ready else {
                SDKLogger.warning("Client not ready, dropping event", category: .client)
                return
            }

            // Validate input
            guard !userID.isEmpty else {
                SDKLogger.error("Empty user ID, dropping event", category: .general)
                return
            }

            // Create event
            var event = Event(
                userID: userID,
                name: name,
                properties: properties,
                generateId: config.generateEventIds
            )

            // Enrich with device context if enabled
            event = await enrichEventWithDeviceContext(event)

            // Validate event
            try event.validate()

            // Send to batch manager
            guard let batcher = self.batcher else {
                SDKLogger.error("Batch manager not initialized", category: .general)
                return
            }

            try await batcher.addEvent(event)

            // Update stats
            stats.incrementEvents()

        } catch {
            SDKLogger.error("Failed to track event: \(error)", category: .general)
        }
    }

    /// Identify a user with traits (fire-and-forget)
    /// Internal user identification (async)
    /// - Parameters:
    ///   - userID: User identifier
    ///   - traits: User traits/properties
    public func eventIdentify(
        userID: String,
        traits: Properties = Properties()
    ) {
        Task { [weak self] in
            await self?.identifyUser(userID: userID, traits: traits)
        }
    }

    /// Internal async user identification
    private func identifyUser(userID: String, traits: Properties) async {
        do {
            guard state == .ready else {
                SDKLogger.warning("Client not ready, dropping identify", category: .client)
                return
            }

            // Validate input
            guard !userID.isEmpty else {
                SDKLogger.error("Empty user ID, dropping identify", category: .general)
                return
            }

            // Create identify event
            let identifyEvent = Event(
                userID: userID,
                name: EventName("user_identified"),
                eventType: .identify,
                properties: traits
            )

            // Validate event
            try identifyEvent.validate()

            SDKLogger.debug("Identifying user: \(userID)", category: .general)

            // Send to batch manager
            guard let batcher = self.batcher else {
                SDKLogger.error("Batch manager not initialized", category: .general)
                return
            }

            try await batcher.addEvent(identifyEvent)

            // Update stats
            stats.incrementIdentities()

        } catch {
            SDKLogger.error("Failed to identify user: \(error)", category: .general)
        }
    }

    /// Associate user with group (fire-and-forget)
    /// - Parameters:
    ///   - userID: User identifier
    ///   - groupID: Group identifier
    ///   - properties: Group properties (optional)
    public func eventGroup(
        userID: String,
        groupID: String,
        properties: Properties = Properties()
    ) {
        Task { [weak self] in
            await self?.groupUser(userID: userID, groupID: groupID, properties: properties)
        }
    }

    /// Internal async group association
    private func groupUser(userID: String, groupID: String, properties: Properties) async {
        do {
            guard state == .ready else {
                SDKLogger.warning("Client not ready, dropping group", category: .client)
                return
            }

            // Validate input
            guard !userID.isEmpty else {
                SDKLogger.error("Empty user ID, dropping group", category: .general)
                return
            }

            guard !groupID.isEmpty else {
                SDKLogger.error("Empty group ID, dropping group", category: .general)
                return
            }

            // Create group event with group_id in properties
            var groupProperties = properties
            groupProperties["group_id"] = groupID

            let groupEvent = Event(
                userID: userID,
                name: EventName("user_grouped"),
                eventType: .group,
                properties: groupProperties
            )

            // Validate event
            try groupEvent.validate()

            SDKLogger.debug("Associating user \(userID) with group: \(groupID)", category: .general)

            // Send to batch manager
            guard let batcher = self.batcher else {
                SDKLogger.error("Batch manager not initialized", category: .general)
                return
            }

            try await batcher.addEvent(groupEvent)

            // Update stats
            stats.incrementGroups()

        } catch {
            SDKLogger.error("Failed to associate user with group: \(error)", category: .general)
        }
    }

    /// Alias user (identity resolution) - connects previous ID to new user ID
    /// - Parameters:
    ///   - previousId: Previous user identifier (anonymous ID, old user ID, etc.)
    ///   - userId: New user identifier to merge with
    public func eventAlias(
        previousId: String,
        userId: String
    ) {
        Task { [weak self] in
            await self?.aliasUser(previousId: previousId, userId: userId)
        }
    }

    /// Internal async user aliasing for identity resolution
    private func aliasUser(previousId: String, userId: String) async {
        do {
            guard state == .ready else {
                SDKLogger.warning("Client not ready, dropping alias", category: .client)
                return
            }

            // Validate input
            guard !previousId.isEmpty else {
                SDKLogger.error("Empty previous ID, dropping alias", category: .general)
                return
            }

            guard !userId.isEmpty else {
                SDKLogger.error("Empty user ID, dropping alias", category: .general)
                return
            }

            // Create alias event with both IDs in properties
            let aliasEvent = Event(
                userID: userId, // The "main" user ID
                name: EventName("user_aliased"),
                eventType: .alias,
                properties: Properties([
                    "previous_id": previousId,
                    "user_id": userId
                ])
            )

            // Validate event
            try aliasEvent.validate()

            SDKLogger.debug("Aliasing user: \(previousId) -> \(userId)", category: .general)

            // Send to batch manager
            guard let batcher = self.batcher else {
                SDKLogger.error("Batch manager not initialized", category: .general)
                return
            }

            try await batcher.addEvent(aliasEvent)

            // Update stats (reuse groups counter for now)
            stats.incrementGroups()

        } catch {
            SDKLogger.error("Failed to alias user: \(error)", category: .general)
        }
    }

    /// Track revenue event (fire-and-forget)
    /// - Parameters:
    ///   - userID: User identifier
    ///   - orderID: Order identifier
    ///   - amount: Revenue amount
    ///   - currency: Currency code
    ///   - properties: Additional properties (optional)
    public func eventRevenue(
        userID: String,
        orderID: String,
        amount: Double,
        currency: Currency,
        properties: Properties = Properties()
    ) {
        Task { [weak self] in
            await self?.trackRevenue(userID: userID, orderID: orderID, amount: amount, currency: currency, properties: properties)
        }
    }

    /// Internal async revenue tracking
    private func trackRevenue(userID: String, orderID: String, amount: Double, currency: Currency, properties: Properties) async {
        do {
            guard state == .ready else {
                SDKLogger.warning("Client not ready, dropping revenue", category: .client)
                return
            }

            // Validate input
            guard !userID.isEmpty else {
                SDKLogger.error("Empty user ID, dropping revenue", category: .general)
                return
            }

            guard amount >= 0 else {
                SDKLogger.error("Negative revenue amount, dropping revenue", category: .general)
                return
            }

            // Create revenue event with revenue data in properties
            var revenueProperties = properties
            revenueProperties["order_id"] = orderID
            revenueProperties["amount"] = amount
            revenueProperties["currency"] = currency.currencyCode

            let revenueEvent = Event(
                userID: userID,
                name: EventName("revenue_tracked"),
                eventType: .track,
                properties: revenueProperties
            )

            // Validate event
            try revenueEvent.validate()

            SDKLogger.debug("Tracking revenue: \(amount) \(currency) for user: \(userID)", category: .general)

            // Send to batch manager
            guard let batcher = self.batcher else {
                SDKLogger.error("Batch manager not initialized", category: .general)
                return
            }

            try await batcher.addEvent(revenueEvent)

            // Update stats
            stats.incrementRevenue()

        } catch {
            SDKLogger.error("Failed to track revenue: \(error)", category: .general)
        }
    }

    // MARK: - Logging

    /// Log an informational message (fire-and-forget)
    /// - Parameters:
    ///   - service: Service name
    ///   - message: Log message
    ///   - data: Structured log data (optional)
    public func logInfo(
        service: String,
        _ message: String,
        data: Properties = Properties()
    ) {
        Task { [weak self] in
            await self?.log(level: .info, service: service, message: message, data: data)
        }
    }

    /// Log an error message (fire-and-forget)
    /// - Parameters:
    ///   - service: Service name
    ///   - message: Log message
    ///   - data: Structured log data (optional)
    public func logError(
        service: String,
        _ message: String,
        data: Properties = Properties()
    ) {
        Task { [weak self] in
            await self?.log(level: .error, service: service, message: message, data: data)
        }
    }

    /// Log a debug message (fire-and-forget)
    /// - Parameters:
    ///   - service: Service name
    ///   - message: Log message
    ///   - data: Structured log data (optional)
    public func logDebug(
        service: String,
        _ message: String,
        data: Properties = Properties()
    ) {
        Task { [weak self] in
            await self?.log(level: .debug, service: service, message: message, data: data)
        }
    }

    /// Log a warning message (fire-and-forget)
    /// - Parameters:
    ///   - service: Service name
    ///   - message: Log message
    ///   - data: Structured log data (optional)
    public func logWarning(
        service: String,
        _ message: String,
        data: Properties = Properties()
    ) {
        Task { [weak self] in
            await self?.log(level: .warning, service: service, message: message, data: data)
        }
    }

    /// Log a critical message (fire-and-forget)
    /// - Parameters:
    ///   - service: Service name
    ///   - message: Log message
    ///   - data: Structured log data (optional)
    public func logCritical(
        service: String,
        _ message: String,
        data: Properties = Properties()
    ) {
        Task { [weak self] in
            await self?.log(level: .critical, service: service, message: message, data: data)
        }
    }

    /// Log an alert message (fire-and-forget)
    /// - Parameters:
    ///   - service: Service name
    ///   - message: Log message
    ///   - data: Structured log data (optional)
    public func logAlert(
        service: String,
        _ message: String,
        data: Properties = Properties()
    ) {
        Task { [weak self] in
            await self?.log(level: .alert, service: service, message: message, data: data)
        }
    }

    /// Log an emergency message (fire-and-forget)
    /// - Parameters:
    ///   - service: Service name
    ///   - message: Log message
    ///   - data: Structured log data (optional)
    public func logEmergency(
        service: String,
        _ message: String,
        data: Properties = Properties()
    ) {
        Task { [weak self] in
            await self?.log(level: .emergency, service: service, message: message, data: data)
        }
    }

    /// Log a notice message (fire-and-forget)
    /// - Parameters:
    ///   - service: Service name
    ///   - message: Log message
    ///   - data: Structured log data (optional)
    public func logNotice(
        service: String,
        _ message: String,
        data: Properties = Properties()
    ) {
        Task { [weak self] in
            await self?.log(level: .notice, service: service, message: message, data: data)
        }
    }

    /// Log a trace message (fire-and-forget)
    /// - Parameters:
    ///   - service: Service name
    ///   - message: Log message
    ///   - data: Structured log data (optional)
    public func logTrace(
        service: String,
        _ message: String,
        data: Properties = Properties()
    ) {
        Task { [weak self] in
            await self?.log(level: .trace, service: service, message: message, data: data)
        }
    }

    /// Log a custom log entry (fire-and-forget)
    /// - Parameters:
    ///   - entry: LogEntry object with full control over all fields
    public func log(
        entry: LogEntry
    ) {
        Task { [weak self] in
            await self?.logEntry(entry)
        }
    }

    /// Log multiple entries in a batch (fire-and-forget)
    /// - Parameters:
    ///   - entries: Array of LogEntry objects
    public func logBatch(
        entries: [LogEntry]
    ) {
        Task { [weak self] in
            await self?.logBatchEntries(entries)
        }
    }

    /// Internal logging implementation for single log entry
    private func logEntry(_ entry: LogEntry) async {
        do {
            guard state == .ready else {
                SDKLogger.warning("Client not ready, dropping log", category: .client)
                return
            }

            // Validate log entry
            try entry.validate()

            SDKLogger.debug("Log \(entry.level): \(entry.message) [service: \(entry.service)]", category: .general)

            // Send to batch manager
            guard let batcher = self.batcher else {
                SDKLogger.error("Batch manager not initialized", category: .general)
                return
            }

            try await batcher.addLog(entry)

            // Update stats
            stats.incrementLogs()

        } catch {
            SDKLogger.error("Failed to log entry: \(error)", category: .general)
        }
    }

    /// Internal batch logging implementation
    private func logBatchEntries(_ entries: [LogEntry]) async {
        do {
            guard state == .ready else {
                SDKLogger.warning("Client not ready, dropping log batch", category: .client)
                return
            }

            guard !entries.isEmpty else {
                SDKLogger.warning("Empty log batch, dropping", category: .general)
                return
            }

            // Validate all entries
            for (index, entry) in entries.enumerated() {
                do {
                    try entry.validate()
                } catch {
                    SDKLogger.error("Invalid log entry at index \(index): \(error)", category: .general)
                    return
                }
            }

            SDKLogger.debug("Logging batch: \(entries.count) entries", category: .general)

            // Send to batch manager
            guard let batcher = self.batcher else {
                SDKLogger.error("Batch manager not initialized", category: .general)
                return
            }

            for entry in entries {
                try await batcher.addLog(entry)
            }

            // Update stats
            for _ in entries {
                stats.incrementLogs()
            }

        } catch {
            SDKLogger.error("Failed to log batch: \(error)", category: .general)
        }
    }

    /// Internal logging implementation (always uses LogCollect type 1)
    private func log(
        level: LogLevel,
        service: String,
        message: String,
        data: Properties
    ) async {
        do {
            guard state == .ready else {
                SDKLogger.warning("Client not ready, dropping log", category: .client)
                return
            }

            // Validate input
            guard !message.isEmpty else {
                SDKLogger.error("Empty log message, dropping log", category: .general)
                return
            }

            // Create log entry with LogCollect type (type 1)
            let logEntry = LogEntry(
                eventType: .log,  // This maps to LogCollect (type 1)
                level: level,
                source: getSourceInfo(),
                service: service,
                message: message,
                data: data
            )

            // Validate log entry
            try logEntry.validate()

            SDKLogger.debug("Logging \(level) message", category: .general)

            // Send to batch manager
            guard let batcher = self.batcher else {
                SDKLogger.error("Batch manager not initialized", category: .general)
                return
            }

            try await batcher.addLog(logEntry)

            // Update stats
            stats.incrementLogs()

        } catch {
            SDKLogger.error("Failed to log message: \(error)", category: .general)
        }
    }

    /// Get bundle identifier for service name
    private func getBundleIdentifier() -> String {
        return Bundle.main.bundleIdentifier ?? "unknown"
    }

    /// Get source info for logging
    private func getSourceInfo() -> String {
        return "ios-sdk"
    }

    // MARK: - Client Management

    /// Force flush all pending events and logs
    /// Flush all pending data (async - call when needed)
    /// - Note: This method should be called before app termination or backgrounding
    public func flush() async throws {
        guard state == .ready else {
            throw UserCanalError.clientNotInitialized
        }

        guard let batcher = self.batcher else {
            throw UserCanalError.clientNotInitialized
        }

        try await batcher.flush()

        SDKLogger.info("Flush completed", category: .general)

        // Update stats
        stats.incrementFlush()
    }

    /// Get client statistics
    public var statistics: ClientStats {
        get async {
            return stats
        }
    }

    // MARK: - Device Context Enrichment

    /// Enrich event with device context if enabled
    private func enrichEventWithDeviceContext(_ event: Event) async -> Event {
        guard let deviceContext = deviceContext else {
            return event
        }

        // Get device context
        let context = await deviceContext.getMinimalContext()

        // Create enriched properties by merging device context with existing properties
        let enrichedProperties = event.properties.modified { builder in
            // Add device context properties if they don't already exist
            for (key, value) in context {
                if event.properties[key] == nil {
                    _ = builder.set(key, value)
                }
            }
            return builder
        }

        // Return new event with enriched properties
        return Event(
            id: event.id.isEmpty ? nil : event.id,
            userID: event.userID,
            name: event.name,
            properties: enrichedProperties,
            timestamp: event.timestamp,
            generateId: !event.id.isEmpty
        )
    }

    /// Close the client and cleanup resources
    public func close() async throws {
        guard state != .closed && state != .closing else {
            return
        }

        state = .closing

        SDKLogger.info("Closing UserCanal client", category: .general)

        do {
            // Flush any pending data
            try await flush()

            // Close internal components
            try? await batcher?.close()
            await networkClient?.close()

            // Clear references
            self.batcher = nil
            self.networkClient = nil

            state = .closed
            SDKLogger.info("UserCanal client closed successfully", category: .general)

        } catch {
            state = .failed(error)
            SDKLogger.error("Failed to close UserCanal client", error: error, category: .error)
            throw error
        }
    }

    // MARK: - Private Methods

    /// Ensure the client is ready for operations
    private func ensureReady() async throws {
        switch state {
        case .ready:
            return
        case .initializing:
            throw UserCanalError.clientNotInitialized
        case .closing:
            throw UserCanalError.clientShuttingDown
        case .closed:
            throw UserCanalError.clientAlreadyClosed
        case .failed(let error):
            throw UserCanalError.internalError("Client is in failed state", underlyingError: error)
        }
    }
}

// MARK: - Client Statistics

/// Statistics about client operations
public struct ClientStats: Sendable {
    public private(set) var eventsTracked: Int = 0
    public private(set) var identitiesTracked: Int = 0
    public private(set) var groupsTracked: Int = 0
    public private(set) var revenueTracked: Int = 0
    public private(set) var logsTracked: Int = 0
    public private(set) var flushCount: Int = 0

    /// Total items tracked
    public var totalTracked: Int {
        eventsTracked + identitiesTracked + groupsTracked + revenueTracked + logsTracked
    }

    fileprivate mutating func reset() {
        eventsTracked = 0
        identitiesTracked = 0
        groupsTracked = 0
        revenueTracked = 0
        logsTracked = 0
        flushCount = 0
    }

    fileprivate mutating func incrementEvents() {
        eventsTracked += 1
    }

    fileprivate mutating func incrementIdentities() {
        identitiesTracked += 1
    }

    fileprivate mutating func incrementGroups() {
        groupsTracked += 1
    }

    fileprivate mutating func incrementRevenue() {
        revenueTracked += 1
    }

    fileprivate mutating func incrementLogs() {
        logsTracked += 1
    }

    fileprivate mutating func incrementFlush() {
        flushCount += 1
    }
}



// MARK: - Extensions

extension UserCanalClient: CustomStringConvertible {
    public nonisolated var description: String {
        return "UserCanalClient(state: ready)" // Simplified for now
    }
}
