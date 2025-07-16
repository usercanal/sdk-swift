// BatchManager.swift
// UserCanal Swift SDK
//
// Copyright © 2024 UserCanal. All rights reserved.
//

import Foundation

// MARK: - Batch Manager

/// Advanced batch manager with prioritization and persistence for efficient network transmission
public actor BatchManager {
    
    // MARK: - Properties
    
    /// Configuration for batching
    private let config: UserCanalConfig
    
    /// API key for authentication
    private let apiKey: Data
    
    /// Network client for sending batches
    private let networkClient: NetworkClient
    
    /// Priority event queue (high priority events)
    private var priorityEventQueue: [Event] = []
    
    /// Regular event queue
    private var eventQueue: [Event] = []
    
    /// Log queue with priority levels
    private var criticalLogQueue: [LogEntry] = []
    private var logQueue: [LogEntry] = []
    
    /// Identity queue
    private var identityQueue: [Identity] = []
    
    /// Group queue
    private var groupQueue: [GroupInfo] = []
    
    /// Revenue queue (high priority)
    private var revenueQueue: [Revenue] = []
    
    /// Failed batches for retry
    private var failedBatches: [FailedBatch] = []
    
    /// Last flush time
    private var lastFlushTime: Date = Date()
    
    /// Flush timer task
    private var flushTimer: Task<Void, Never>?
    
    /// Statistics
    private var stats: BatchStats = BatchStats()
    
    /// Persistence manager for offline storage
    private var persistenceManager: PersistenceManager?
    
    // MARK: - Initialization
    
    /// Create a new batch manager with advanced features
    /// - Parameters:
    ///   - config: Client configuration
    ///   - apiKey: API key as data
    ///   - networkClient: Network client for sending
    public init(config: UserCanalConfig, apiKey: Data, networkClient: NetworkClient) {
        self.config = config
        self.apiKey = apiKey
        self.networkClient = networkClient
        
        // Initialize persistence if enabled
        if config.enableOfflineStorage {
            self.persistenceManager = PersistenceManager(maxEvents: config.maxOfflineEvents)
        }
        
        // Start periodic flush timer
        Task {
            await startFlushTimer()
        }
        
        // Load any persisted data
        Task {
            await loadPersistedData()
        }
        
        SDKLogger.info("BatchManager initialized with advanced features", category: .batching)
    }
    
    // MARK: - Adding Items
    
    /// Add an event to the batch queue with priority handling
    /// - Parameter event: Event to add
    public func addEvent(_ event: Event) async throws {
        let priority = determineEventPriority(event)
        
        if priority == .high {
            try await validateAndAddEvent(event, isPriority: true)
        } else {
            try await validateAndAddEvent(event, isPriority: false)
        }
        
        await checkAutoFlush(priority: priority)
    }
    
    /// Add an identity to the batch queue
    /// - Parameter identity: Identity to add
    public func addIdentity(_ identity: Identity) async throws {
        try await validateAndAddIdentity(identity)
        await checkAutoFlush()
    }
    
    /// Add a group to the batch queue
    /// - Parameter group: Group info to add
    public func addGroup(_ group: GroupInfo) async throws {
        try await validateAndAddGroup(group)
        await checkAutoFlush()
    }
    
    /// Add revenue to the batch queue (always high priority)
    /// - Parameter revenue: Revenue to add
    public func addRevenue(_ revenue: Revenue) async throws {
        try await validateAndAddRevenue(revenue)
        await checkAutoFlush(priority: .high)
    }
    
    /// Add a log entry to the batch queue with priority handling
    /// - Parameter log: Log entry to add
    public func addLog(_ log: LogEntry) async throws {
        let priority = determineLogPriority(log)
        
        if priority == .high {
            try await validateAndAddLog(log, isCritical: true)
        } else {
            try await validateAndAddLog(log, isCritical: false)
        }
        
        await checkAutoFlush(priority: priority)
    }
    
    // MARK: - Private Add Helpers
    
    /// Validate and add item to queue with enhanced overflow handling
    private func validateAndAdd<T: Sendable>(_ item: T, to queue: inout [T], type: String) async throws {
        let queueLimit = config.batchSize * 3 // Increased limit for better buffering
        
        // Check queue size limit
        if queue.count >= queueLimit {
            // Try to persist to storage if available
            if let persistenceManager = persistenceManager {
                try await persistenceManager.persistItem(item, type: type)
                SDKLogger.warning("Queue full, persisted \(type) to storage", category: .batching)
                stats.incrementItemsPersisted()
                return
            } else {
                throw UserCanalError.queueFull(currentSize: queue.count, maxSize: queueLimit)
            }
        }
        
        queue.append(item)
        stats.incrementItemsQueued()
        
        SDKLogger.debug("Added \(type) to queue (queue size: \(queue.count))", category: .batching)
    }
    
    /// Validate and add event to appropriate queue
    private func validateAndAddEvent(_ event: Event, isPriority: Bool) async throws {
        let queueLimit = config.batchSize * 3
        let queue = isPriority ? priorityEventQueue : eventQueue
        let type = isPriority ? "priority event" : "event"
        
        if queue.count >= queueLimit {
            if let persistenceManager = persistenceManager {
                try await persistenceManager.persistItem(event, type: type)
                SDKLogger.warning("Queue full, persisted \(type) to storage", category: .batching)
                stats.incrementItemsPersisted()
                return
            } else {
                throw UserCanalError.queueFull(currentSize: queue.count, maxSize: queueLimit)
            }
        }
        
        if isPriority {
            priorityEventQueue.append(event)
        } else {
            eventQueue.append(event)
        }
        stats.incrementItemsQueued()
        
        SDKLogger.debug("Added \(type) to queue (queue size: \(queue.count))", category: .batching)
    }
    
    /// Validate and add identity to queue
    private func validateAndAddIdentity(_ identity: Identity) async throws {
        let queueLimit = config.batchSize * 3
        
        if identityQueue.count >= queueLimit {
            if let persistenceManager = persistenceManager {
                try await persistenceManager.persistItem(identity, type: "identity")
                SDKLogger.warning("Queue full, persisted identity to storage", category: .batching)
                stats.incrementItemsPersisted()
                return
            } else {
                throw UserCanalError.queueFull(currentSize: identityQueue.count, maxSize: queueLimit)
            }
        }
        
        identityQueue.append(identity)
        stats.incrementItemsQueued()
        
        SDKLogger.debug("Added identity to queue (queue size: \(identityQueue.count))", category: .batching)
    }
    
    /// Validate and add group to queue
    private func validateAndAddGroup(_ group: GroupInfo) async throws {
        let queueLimit = config.batchSize * 3
        
        if groupQueue.count >= queueLimit {
            if let persistenceManager = persistenceManager {
                try await persistenceManager.persistItem(group, type: "group")
                SDKLogger.warning("Queue full, persisted group to storage", category: .batching)
                stats.incrementItemsPersisted()
                return
            } else {
                throw UserCanalError.queueFull(currentSize: groupQueue.count, maxSize: queueLimit)
            }
        }
        
        groupQueue.append(group)
        stats.incrementItemsQueued()
        
        SDKLogger.debug("Added group to queue (queue size: \(groupQueue.count))", category: .batching)
    }
    
    /// Validate and add revenue to queue
    private func validateAndAddRevenue(_ revenue: Revenue) async throws {
        let queueLimit = config.batchSize * 3
        
        if revenueQueue.count >= queueLimit {
            if let persistenceManager = persistenceManager {
                try await persistenceManager.persistItem(revenue, type: "revenue")
                SDKLogger.warning("Queue full, persisted revenue to storage", category: .batching)
                stats.incrementItemsPersisted()
                return
            } else {
                throw UserCanalError.queueFull(currentSize: revenueQueue.count, maxSize: queueLimit)
            }
        }
        
        revenueQueue.append(revenue)
        stats.incrementItemsQueued()
        
        SDKLogger.debug("Added revenue to queue (queue size: \(revenueQueue.count))", category: .batching)
    }
    
    /// Validate and add log to appropriate queue
    private func validateAndAddLog(_ log: LogEntry, isCritical: Bool) async throws {
        let queueLimit = config.batchSize * 3
        let queue = isCritical ? criticalLogQueue : logQueue
        let type = isCritical ? "critical log" : "log"
        
        if queue.count >= queueLimit {
            if let persistenceManager = persistenceManager {
                try await persistenceManager.persistItem(log, type: type)
                SDKLogger.warning("Queue full, persisted \(type) to storage", category: .batching)
                stats.incrementItemsPersisted()
                return
            } else {
                throw UserCanalError.queueFull(currentSize: queue.count, maxSize: queueLimit)
            }
        }
        
        if isCritical {
            criticalLogQueue.append(log)
        } else {
            logQueue.append(log)
        }
        stats.incrementItemsQueued()
        
        SDKLogger.debug("Added \(type) to queue (queue size: \(queue.count))", category: .batching)
    }
    
    /// Determine event priority based on event type and properties
    private func determineEventPriority(_ event: Event) -> Priority {
        // Revenue and critical business events are high priority
        switch event.name.category {
        case .revenue, .subscription, .trial:
            return .high
        case .error:
            return .high
        case .session:
            // Session start/end are important for analytics
            return event.name == .sessionStarted || event.name == .sessionEnded ? .high : .normal
        default:
            // Check if event has high_priority property
            if event.properties.bool(for: "high_priority") == true {
                return .high
            }
            return .normal
        }
    }
    
    /// Determine log priority based on log level
    private func determineLogPriority(_ log: LogEntry) -> Priority {
        switch log.level {
        case .emergency, .alert, .critical, .error:
            return .high
        default:
            return .normal
        }
    }
    
    // MARK: - Flushing
    
    /// Check if auto-flush should be triggered with priority handling
    private func checkAutoFlush(priority: Priority = .normal) async {
        let priorityItems = priorityEventQueue.count + criticalLogQueue.count + revenueQueue.count
        let totalItems = priorityItems + eventQueue.count + logQueue.count + identityQueue.count + groupQueue.count
        
        // Immediate flush for high priority items
        if priority == .high && priorityItems > 0 {
            SDKLogger.debug("Triggering immediate flush for high priority items", category: .batching)
            await performFlush(priorityOnly: true)
            return
        }
        
        // Size-based flush for regular items
        if totalItems >= config.batchSize {
            SDKLogger.debug("Triggering size-based flush (\(totalItems) items)", category: .batching)
            await performFlush()
        }
        
        // Flush critical logs immediately if we have too many
        if criticalLogQueue.count >= 5 {
            SDKLogger.debug("Triggering critical log flush", category: .batching)
            await performFlush(priorityOnly: true)
        }
    }
    
    /// Start the periodic flush timer
    private func startFlushTimer() {
        flushTimer = Task {
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: Duration.seconds(config.flushInterval.timeInterval))
                    await performTimerFlush()
                } catch {
                    // Task was cancelled
                    break
                }
            }
        }
    }
    
    /// Perform timer-based flush
    private func performTimerFlush() async {
        let timeSinceLastFlush = Date().timeIntervalSince(lastFlushTime)
        
        if timeSinceLastFlush >= config.flushInterval.timeInterval {
            let totalItems = eventQueue.count + logQueue.count + identityQueue.count + groupQueue.count + revenueQueue.count
            
            if totalItems > 0 {
                SDKLogger.debug("Triggering time-based flush (\(totalItems) items)", category: .batching)
                await performFlush()
            }
        }
    }
    
    /// Manually flush all queued items
    public func flush() async throws {
        SDKLogger.info("Manual flush requested", category: .batching)
        await performFlush()
    }
    
    /// Perform the actual flush operation with enhanced error handling
    private func performFlush(priorityOnly: Bool = false) async {
        do {
            // Retry any failed batches first
            await retryFailedBatches()
            
            if priorityOnly {
                // Flush only high priority items
                try await flushPriorityItems()
            } else {
                // Flush all items
                try await flushAllItems()
            }
            
            lastFlushTime = Date()
            stats.incrementFlushCount()
            
            SDKLogger.info("Flush completed successfully", category: .batching)
            
        } catch {
            stats.incrementFlushFailures()
            SDKLogger.error("Flush failed", error: error, category: .batching)
            
            // Store failed batches for retry
            await handleFlushFailure(error: error)
        }
    }
    
    /// Flush only priority items
    private func flushPriorityItems() async throws {
        // Flush priority events
        let priorityEvents = combinePriorityEventTypes()
        if !priorityEvents.isEmpty {
            try await flushEvents(priorityEvents)
            clearPriorityQueues()
        }
        
        // Flush critical logs
        if !criticalLogQueue.isEmpty {
            try await flushLogs(Array(criticalLogQueue))
            criticalLogQueue.removeAll()
        }
    }
    
    /// Flush all items
    private func flushAllItems() async throws {
        // Flush all events (priority first, then regular)
        let allEvents = combineAllEventTypes()
        if !allEvents.isEmpty {
            try await flushEvents(allEvents)
            clearAllEventQueues()
        }
        
        // Flush all logs (critical first, then regular)
        let allLogs = criticalLogQueue + logQueue
        if !allLogs.isEmpty {
            try await flushLogs(allLogs)
            criticalLogQueue.removeAll()
            logQueue.removeAll()
        }
    }
    
    /// Combine priority event types into a single events array
    private func combinePriorityEventTypes() -> [Event] {
        var allEvents: [Event] = []
        
        // Add priority events first
        allEvents.append(contentsOf: priorityEventQueue)
        
        // Convert revenue to events (always high priority)
        for revenue in revenueQueue {
            let event = Event(
                userID: revenue.userID,
                name: .orderCompleted,
                properties: revenue.properties.modified { builder in
                    builder
                        .set("order_id", revenue.orderID)
                        .set("amount", revenue.amount)
                        .set("currency", revenue.currency.currencyCode)
                        .set("revenue_type", revenue.type.rawValue)
                        .set("products", revenue.products.map { product in
                            [
                                "id": product.id,
                                "name": product.name,
                                "price": product.price,
                                "quantity": product.quantity
                            ]
                        })
                },
                timestamp: revenue.timestamp
            )
            allEvents.append(event)
        }
        
        return allEvents
    }
    
    /// Combine all event types into a single events array
    private func combineAllEventTypes() -> [Event] {
        var allEvents: [Event] = []
        
        // Add priority events first
        allEvents.append(contentsOf: priorityEventQueue)
        
        // Add regular events
        allEvents.append(contentsOf: eventQueue)
        
        // Convert identities to events
        for identity in identityQueue {
            let event = Event(
                userID: identity.userID,
                name: .userSignedUp,
                properties: identity.properties,
                timestamp: identity.timestamp
            )
            allEvents.append(event)
        }
        
        // Convert groups to events
        for group in groupQueue {
            let event = Event(
                userID: group.userID,
                name: EventName("Group Associated"),
                properties: group.properties.modified { builder in
                    builder.set("group_id", group.groupID)
                },
                timestamp: group.timestamp
            )
            allEvents.append(event)
        }
        
        // Convert revenue to events
        for revenue in revenueQueue {
            let event = Event(
                userID: revenue.userID,
                name: .orderCompleted,
                properties: revenue.properties.modified { builder in
                    builder
                        .set("order_id", revenue.orderID)
                        .set("amount", revenue.amount)
                        .set("currency", revenue.currency.currencyCode)
                        .set("revenue_type", revenue.type.rawValue)
                        .set("products", revenue.products.map { product in
                            [
                                "id": product.id,
                                "name": product.name,
                                "price": product.price,
                                "quantity": product.quantity
                            ]
                        })
                },
                timestamp: revenue.timestamp
            )
            allEvents.append(event)
        }
        
        return allEvents
    }
    
    /// Clear priority event queues
    private func clearPriorityQueues() {
        priorityEventQueue.removeAll()
        revenueQueue.removeAll()
    }
    
    /// Clear all event queues
    private func clearAllEventQueues() {
        priorityEventQueue.removeAll()
        eventQueue.removeAll()
        identityQueue.removeAll()
        groupQueue.removeAll()
        revenueQueue.removeAll()
    }
    
    /// Flush events batch with enhanced error handling
    private func flushEvents(_ events: [Event]) async throws {
        guard !events.isEmpty else { return }
        
        SDKLogger.debug("Flushing \(events.count) events", category: .batching)
        
        do {
            // Create FlatBuffers batch
            let batchData = try FlatBuffersProtocol.createEventBatch(events: events, apiKey: apiKey)
            
            // Send via network client
            try await networkClient.sendBatch(batchData)
            
            stats.incrementEventBatchesSent()
            stats.addEventsSent(events.count)
            
            SDKLogger.debug("Events batch sent successfully", category: .batching)
            
        } catch {
            // Store failed batch for retry
            let failedBatch = FailedBatch(
                events: events,
                logs: [],
                timestamp: Date(),
                retryCount: 0,
                error: error
            )
            failedBatches.append(failedBatch)
            stats.incrementBatchesRetained()
            
            throw error
        }
    }
    
    /// Flush logs batch
    private func flushLogs(_ logs: [LogEntry]) async throws {
        guard !logs.isEmpty else { return }
        
        SDKLogger.debug("Flushing \(logs.count) logs", category: .batching)
        
        // Create FlatBuffers batch
        let batchData = try FlatBuffersProtocol.createLogBatch(logs: logs, apiKey: apiKey)
        
        // Send via network client
        try await networkClient.sendBatch(batchData)
        
        stats.incrementLogBatchesSent()
        stats.addLogsSent(logs.count)
        
        SDKLogger.debug("Logs batch sent successfully", category: .batching)
    }
    
    // MARK: - Statistics
    
    /// Get batch statistics
    public var statistics: BatchStats {
        return stats
    }
    
    /// Get current queue sizes with priority information
    public var queueSizes: QueueSizes {
        return QueueSizes(
            events: eventQueue.count,
            priorityEvents: priorityEventQueue.count,
            identities: identityQueue.count,
            groups: groupQueue.count,
            revenue: revenueQueue.count,
            logs: logQueue.count,
            criticalLogs: criticalLogQueue.count,
            failedBatches: failedBatches.count
        )
    }
    
    /// Load persisted data from storage
    private func loadPersistedData() async {
        guard let persistenceManager = persistenceManager else { return }
        
        do {
            let persistedData = try await persistenceManager.loadPersistedData()
            
            // Add persisted items back to queues
            for item in persistedData.events {
                eventQueue.append(item)
            }
            
            for item in persistedData.logs {
                logQueue.append(item)
            }
            
            SDKLogger.info("Loaded \(persistedData.events.count) events and \(persistedData.logs.count) logs from storage", category: .batching)
            
        } catch {
            SDKLogger.error("Failed to load persisted data", error: error, category: .batching)
        }
    }
    
    /// Retry failed batches
    private func retryFailedBatches() async {
        let currentTime = Date()
        var batchesToRetry: [FailedBatch] = []
        
        // Find batches ready for retry
        for (index, batch) in failedBatches.enumerated().reversed() {
            let timeSinceFailure = currentTime.timeIntervalSince(batch.timestamp)
            let retryDelay = calculateRetryDelay(retryCount: batch.retryCount)
            
            if timeSinceFailure >= retryDelay && batch.retryCount < 3 {
                batchesToRetry.append(batch)
                failedBatches.remove(at: index)
            }
        }
        
        // Retry batches
        for batch in batchesToRetry {
            do {
                if !batch.events.isEmpty {
                    try await flushEvents(batch.events)
                }
                if !batch.logs.isEmpty {
                    try await flushLogs(batch.logs)
                }
                
                SDKLogger.debug("Successfully retried failed batch", category: .batching)
                
            } catch {
                // Increment retry count and add back to failed batches
                let updatedBatch = FailedBatch(
                    events: batch.events,
                    logs: batch.logs,
                    timestamp: currentTime,
                    retryCount: batch.retryCount + 1,
                    error: error
                )
                failedBatches.append(updatedBatch)
                
                SDKLogger.warning("Failed batch retry attempt \(updatedBatch.retryCount)", category: .batching)
            }
        }
    }
    
    /// Calculate retry delay based on retry count
    private func calculateRetryDelay(retryCount: Int) -> TimeInterval {
        // Exponential backoff: 1s, 2s, 4s
        return pow(2.0, Double(retryCount))
    }
    
    /// Handle flush failure by storing data for retry
    private func handleFlushFailure(error: any Error) async {
        // Persist current queues if persistence is enabled
        if let persistenceManager = persistenceManager {
            do {
                let allEvents = combineAllEventTypes()
                let allLogs = criticalLogQueue + logQueue
                
                try await persistenceManager.persistBatch(events: allEvents, logs: allLogs)
                SDKLogger.info("Persisted failed batch data to storage", category: .batching)
                
            } catch {
                SDKLogger.error("Failed to persist batch data", error: error, category: .batching)
            }
        }
    }
    
    // MARK: - Cleanup
    
    /// Close the batch manager
    public func close() async {
        SDKLogger.info("Closing batch manager", category: .batching)
        
        // Cancel flush timer
        flushTimer?.cancel()
        flushTimer = nil
        
        // Perform final flush
        await performFlush()
        
        SDKLogger.info("Batch manager closed", category: .batching)
    }
}

// MARK: - Supporting Types

/// Priority levels for batching
private enum Priority {
    case high
    case normal
}

/// Failed batch for retry logic
private struct FailedBatch {
    let events: [Event]
    let logs: [LogEntry]
    let timestamp: Date
    let retryCount: Int
    let error: any Error
}

/// Persistence manager for offline storage
private actor PersistenceManager {
    private let maxEvents: Int
    private var persistedEvents: [Event] = []
    private var persistedLogs: [LogEntry] = []
    
    init(maxEvents: Int) {
        self.maxEvents = maxEvents
    }
    
    func persistItem<T>(_ item: T, type: String) async throws {
        if let event = item as? Event {
            if persistedEvents.count < maxEvents {
                persistedEvents.append(event)
            }
        } else if let log = item as? LogEntry {
            if persistedLogs.count < maxEvents {
                persistedLogs.append(log)
            }
        }
    }
    
    func persistBatch(events: [Event], logs: [LogEntry]) async throws {
        let availableEventSpace = maxEvents - persistedEvents.count
        let availableLogSpace = maxEvents - persistedLogs.count
        
        persistedEvents.append(contentsOf: Array(events.prefix(availableEventSpace)))
        persistedLogs.append(contentsOf: Array(logs.prefix(availableLogSpace)))
    }
    
    func loadPersistedData() async throws -> (events: [Event], logs: [LogEntry]) {
        let events = persistedEvents
        let logs = persistedLogs
        
        // Clear persisted data after loading
        persistedEvents.removeAll()
        persistedLogs.removeAll()
        
        return (events: events, logs: logs)
    }
}

// MARK: - Statistics

/// Enhanced statistics for batch operations
public struct BatchStats: Sendable {
    public private(set) var itemsQueued: Int = 0
    public private(set) var itemsPersisted: Int = 0
    public private(set) var eventBatchesSent: Int = 0
    public private(set) var logBatchesSent: Int = 0
    public private(set) var eventsSent: Int = 0
    public private(set) var logsSent: Int = 0
    public private(set) var flushCount: Int = 0
    public private(set) var flushFailures: Int = 0
    public private(set) var batchesRetained: Int = 0
    public private(set) var priorityFlushCount: Int = 0
    
    /// Total batches sent
    public var totalBatchesSent: Int {
        eventBatchesSent + logBatchesSent
    }
    
    /// Total items sent
    public var totalItemsSent: Int {
        eventsSent + logsSent
    }
    
    /// Flush success rate
    public var flushSuccessRate: Double {
        let totalAttempts = flushCount + flushFailures
        guard totalAttempts > 0 else { return 0.0 }
        return Double(flushCount) / Double(totalAttempts)
    }
    
    /// Items successfully processed (sent + persisted)
    public var totalItemsProcessed: Int {
        totalItemsSent + itemsPersisted
    }
    
    /// Priority flush ratio
    public var priorityFlushRatio: Double {
        guard flushCount > 0 else { return 0.0 }
        return Double(priorityFlushCount) / Double(flushCount)
    }
    
    fileprivate mutating func incrementItemsQueued() {
        itemsQueued += 1
    }
    
    fileprivate mutating func incrementItemsPersisted() {
        itemsPersisted += 1
    }
    
    fileprivate mutating func incrementEventBatchesSent() {
        eventBatchesSent += 1
    }
    
    fileprivate mutating func incrementLogBatchesSent() {
        logBatchesSent += 1
    }
    
    fileprivate mutating func addEventsSent(_ count: Int) {
        eventsSent += count
    }
    
    fileprivate mutating func addLogsSent(_ count: Int) {
        logsSent += count
    }
    
    fileprivate mutating func incrementFlushCount() {
        flushCount += 1
    }
    
    fileprivate mutating func incrementFlushFailures() {
        flushFailures += 1
    }
    
    fileprivate mutating func incrementBatchesRetained() {
        batchesRetained += 1
    }
    
    fileprivate mutating func incrementPriorityFlushCount() {
        priorityFlushCount += 1
    }
}

/// Enhanced queue sizes with priority information
public struct QueueSizes: Sendable {
    public let events: Int
    public let priorityEvents: Int
    public let identities: Int
    public let groups: Int
    public let revenue: Int
    public let logs: Int
    public let criticalLogs: Int
    public let failedBatches: Int
    
    /// Total items in all queues
    public var total: Int {
        events + priorityEvents + identities + groups + revenue + logs + criticalLogs
    }
}


// MARK: - Duration Extension

extension Duration {
    /// Convert to TimeInterval for compatibility
    var timeInterval: TimeInterval {
        let (seconds, attoseconds) = self.components
        return TimeInterval(seconds) + (TimeInterval(attoseconds) / 1_000_000_000_000_000_000)
    }
}