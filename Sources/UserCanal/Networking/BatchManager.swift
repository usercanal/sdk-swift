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

    /// Unified event queue for all event types (TRACK, IDENTIFY, GROUP, ALIAS, ENRICH)
    private var eventQueue: [Event] = []

    /// Log queue (separate schema)
    private var logQueue: [LogEntry] = []

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
        SDKLogger.trace("Event queued (batch size: \(eventQueue.count))", category: .batching)

        // Check if we should flush based on batch size
        if shouldFlushBasedOnSize() {
            try await performFlush()
        }
    }

    public func addLog(_ log: LogEntry) async throws {
        logQueue.append(log)
        SDKLogger.trace("Log queued (batch size: \(logQueue.count))", category: .batching)

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
        let totalItems = eventQueue.count + logQueue.count
        return totalItems >= config.batchSize
    }

    private func performFlush() async throws {
        guard !eventQueue.isEmpty || !logQueue.isEmpty else {
            SDKLogger.debug("No items to flush", category: .batching)
            return
        }

        // Send events if we have any
        if !eventQueue.isEmpty {
            do {
                let events = eventQueue
                eventQueue.removeAll()

                let eventBatch = try FlatBuffersProtocol.createEventBatch(events: events, apiKey: apiKey)
                try await networkClient.connectIfNeeded()
                try await networkClient.sendBatch(eventBatch)
                await networkClient.disconnect()

                SDKLogger.debug("Sent batch: \(eventBatch.count) bytes with \(events.count) events", category: .batching)
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
                try await networkClient.connectIfNeeded()
                try await networkClient.sendBatch(logBatch)
                await networkClient.disconnect()

                SDKLogger.debug("Sent batch: \(logBatch.count) bytes with \(logs.count) logs", category: .batching)
            } catch {
                SDKLogger.error("Failed to send log batch", error: error, category: .batching)
                throw error
            }
        }



        lastFlushTime = Date()
        SDKLogger.trace("Batch flush completed", category: .batching)
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
            let totalItems = eventQueue.count + logQueue.count

            if totalItems > 0 {
                try await performFlush()
            }
        }
    }

    deinit {
        flushTimer?.cancel()
    }
}
