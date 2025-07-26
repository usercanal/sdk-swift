// BatchManager.swift
// UserCanal Swift SDK
//
// Copyright © 2024 UserCanal. All rights reserved.
//

import Foundation

/// Working BatchManager implementation that actually sends data to the collector
public actor BatchManager {

    // MARK: - Properties

    /// Configuration for batching
    private let config: UserCanalConfig

    /// API key for authentication
    private let apiKey: Data

    /// Network client for sending batches
    private let networkClient: NetworkClient

    /// Event queue
    private var eventQueue: [Event] = []

    /// Log queue
    private var logQueue: [LogEntry] = []

    /// Identity queue
    private var identityQueue: [Identity] = []

    /// Group queue
    private var groupQueue: [GroupInfo] = []

    /// Revenue queue
    private var revenueQueue: [Revenue] = []

    /// Timer for auto-flush
    private var flushTimer: Task<Void, Never>?

    /// Last flush time
    private var lastFlushTime: Date = Date()

    // MARK: - Initialization

    public init(config: UserCanalConfig, apiKey: Data, networkClient: NetworkClient) {
        self.config = config
        self.apiKey = apiKey
        self.networkClient = networkClient

        // Start auto-flush timer in a task
        Task {
            await startFlushTimer()
        }
    }

    // MARK: - Public Methods

    public func addEvent(_ event: Event) async throws {
        eventQueue.append(event)
        SDKLogger.debug("Added event to queue. Queue size: \(eventQueue.count)", category: .batching)

        // Check if we should flush based on batch size
        if shouldFlushBasedOnSize() {
            try await performFlush()
        }
    }

    public func addLog(_ log: LogEntry) async throws {
        logQueue.append(log)
        SDKLogger.debug("Added log to queue. Queue size: \(logQueue.count)", category: .batching)

        if shouldFlushBasedOnSize() {
            try await performFlush()
        }
    }

    public func addIdentity(_ identity: Identity) async throws {
        identityQueue.append(identity)
        SDKLogger.debug("Added identity to queue. Queue size: \(identityQueue.count)", category: .batching)

        if shouldFlushBasedOnSize() {
            try await performFlush()
        }
    }

    public func addGroup(_ group: GroupInfo) async throws {
        groupQueue.append(group)
        SDKLogger.debug("Added group to queue. Queue size: \(groupQueue.count)", category: .batching)

        if shouldFlushBasedOnSize() {
            try await performFlush()
        }
    }

    public func addRevenue(_ revenue: Revenue) async throws {
        revenueQueue.append(revenue)
        SDKLogger.debug("Added revenue to queue. Queue size: \(revenueQueue.count)", category: .batching)

        if shouldFlushBasedOnSize() {
            try await performFlush()
        }
    }

    public func flush() async throws {
        try await performFlush()
    }

    public func close() async throws {
        flushTimer?.cancel()
        try await performFlush()
    }

    // MARK: - Private Methods

    private func shouldFlushBasedOnSize() -> Bool {
        let totalItems = eventQueue.count + logQueue.count + identityQueue.count + groupQueue.count + revenueQueue.count
        return totalItems >= config.batchSize
    }

    private func performFlush() async throws {
        guard !eventQueue.isEmpty || !logQueue.isEmpty || !identityQueue.isEmpty || !groupQueue.isEmpty || !revenueQueue.isEmpty else {
            SDKLogger.debug("No items to flush", category: .batching)
            return
        }

        let totalItems = eventQueue.count + logQueue.count + identityQueue.count + groupQueue.count + revenueQueue.count
        SDKLogger.info("Flushing batch with \(totalItems) items", category: .batching)

        // Send events if we have any
        if !eventQueue.isEmpty {
            do {
                let events = eventQueue
                eventQueue.removeAll()

                let eventBatch = try FlatBuffersProtocol.createEventBatch(events: events, apiKey: apiKey)
                try await networkClient.sendBatch(eventBatch)

                SDKLogger.info("Successfully sent \(events.count) events (\(eventBatch.count) bytes)", category: .batching)
            } catch {
                SDKLogger.error("Failed to send event batch", error: error, category: .batching)
                throw error
            }
        }

        // Send logs if we have any
        if !logQueue.isEmpty {
            do {
                let logs = logQueue
                logQueue.removeAll()

                let logBatch = try FlatBuffersProtocol.createLogBatch(logs: logs, apiKey: apiKey)
                try await networkClient.sendBatch(logBatch)

                SDKLogger.info("Successfully sent \(logs.count) logs (\(logBatch.count) bytes)", category: .batching)
            } catch {
                SDKLogger.error("Failed to send log batch", error: error, category: .batching)
                throw error
            }
        }

        // For now, just clear other queues (identity, group, revenue)
        // TODO: Implement proper serialization for these types
        if !identityQueue.isEmpty {
            SDKLogger.info("Clearing \(identityQueue.count) identity items (not yet implemented)", category: .batching)
            identityQueue.removeAll()
        }

        if !groupQueue.isEmpty {
            SDKLogger.info("Clearing \(groupQueue.count) group items (not yet implemented)", category: .batching)
            groupQueue.removeAll()
        }

        if !revenueQueue.isEmpty {
            SDKLogger.info("Clearing \(revenueQueue.count) revenue items (not yet implemented)", category: .batching)
            revenueQueue.removeAll()
        }

        lastFlushTime = Date()
        SDKLogger.debug("Batch flush completed", category: .batching)
    }

    private func startFlushTimer() {
        flushTimer?.cancel()

        flushTimer = Task {
            while !Task.isCancelled {
                do {
                    // Simple conversion: use the seconds component of Duration
                    let flushIntervalSeconds = Double(config.flushInterval.components.seconds)

                    try await Task.sleep(for: .seconds(flushIntervalSeconds))
                    try await performTimerFlush()
                } catch {
                    if !Task.isCancelled {
                        SDKLogger.error("Flush timer error", error: error, category: .batching)
                    }
                }
            }
        }
    }

    private func performTimerFlush() async throws {
        let now = Date()
        let timeSinceLastFlush = now.timeIntervalSince(lastFlushTime)
        let flushIntervalSeconds = Double(config.flushInterval.components.seconds)

        if timeSinceLastFlush >= flushIntervalSeconds {
            let totalItems = eventQueue.count + logQueue.count + identityQueue.count + groupQueue.count + revenueQueue.count

            if totalItems > 0 {
                SDKLogger.debug("Timer-based flush triggered with \(totalItems) items", category: .batching)
                try await performFlush()
            }
        }
    }

    deinit {
        flushTimer?.cancel()
    }
}
