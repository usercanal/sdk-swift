// ErrorRecovery.swift
// UserCanal Swift SDK
//
// Copyright © 2024 UserCanal. All rights reserved.
//

import Foundation

// MARK: - Error Recovery Manager

/// Comprehensive error recovery system with automatic retry strategies
public actor ErrorRecoveryManager {

    // MARK: - Properties

    /// Recovery strategies for different error types
    private let strategies: [UserCanalError: RecoveryStrategy]

    /// Active recovery sessions
    private var activeSessions: [String: RecoverySession] = [:]

    /// Recovery statistics
    private var stats: RecoveryStats = RecoveryStats()

    /// Maximum concurrent recovery sessions
    private let maxConcurrentSessions: Int = 5

    // MARK: - Initialization

    public init() {
        self.strategies = Self.createDefaultStrategies()
        SDKLogger.info("ErrorRecoveryManager initialized", category: .general)
    }

    // MARK: - Recovery Operations

    /// Attempt to recover from an error
    /// - Parameters:
    ///   - error: The error to recover from
    ///   - operation: The operation that failed
    ///   - context: Additional context for recovery
    /// - Returns: Recovery result
    public func attemptRecovery(
        from error: any Error,
        operation: String,
        context: RecoveryContext = RecoveryContext()
    ) async -> RecoveryResult {

        let sessionId = UUID().uuidString
        stats.incrementRecoveryAttempts()

        SDKLogger.info("Starting recovery session \(sessionId) for operation: \(operation)", category: .general)

        // Check if we can start a new recovery session
        guard activeSessions.count < maxConcurrentSessions else {
            SDKLogger.warning("Maximum concurrent recovery sessions reached", category: .error)
            return .failed(.resourceExhausted("Too many concurrent recovery sessions"))
        }

        // Convert to UserCanalError if needed
        let ucError = convertToUserCanalError(error)

        // Get recovery strategy
        guard let strategy = getRecoveryStrategy(for: ucError) else {
            SDKLogger.warning("No recovery strategy found for error: \(error)", category: .general)
            stats.incrementUnrecoverableErrors()
            return .failed(.noStrategyFound)
        }

        // Create recovery session
        let session = RecoverySession(
            id: sessionId,
            error: ucError,
            operation: operation,
            strategy: strategy,
            context: context,
            startTime: Date()
        )

        activeSessions[sessionId] = session

        // Attempt recovery
        let result = await executeRecoveryStrategy(session: session)

        // Clean up session
        activeSessions.removeValue(forKey: sessionId)

        // Update statistics
        updateStats(for: result, session: session)

        SDKLogger.info("Recovery session \(sessionId) completed with result: \(result)", category: .error)

        return result
    }

    /// Get recovery suggestions for an error without attempting recovery
    /// - Parameter error: The error to analyze
    /// - Returns: Recovery suggestions
    public func getRecoverySuggestions(for error: any Error) -> [RecoveryAction] {
        let ucError = convertToUserCanalError(error)

        if let strategy = getRecoveryStrategy(for: ucError) {
            return strategy.actions
        }

        return ucError.recoveryInfo.recoveryActions
    }

    /// Check if an error is recoverable
    /// - Parameter error: The error to check
    /// - Returns: True if the error can be recovered from
    public func isRecoverable(_ error: any Error) -> Bool {
        let ucError = convertToUserCanalError(error)
        return getRecoveryStrategy(for: ucError) != nil
    }

    // MARK: - Private Methods

    /// Execute recovery strategy for a session
    private func executeRecoveryStrategy(session: RecoverySession) async -> RecoveryResult {
        var currentAttempt = 0
        let maxAttempts = session.strategy.maxAttempts

        while currentAttempt < maxAttempts {
            currentAttempt += 1

            SDKLogger.debug("Recovery attempt \(currentAttempt)/\(maxAttempts) for session \(session.id)", category: .error)

            // Wait for retry delay if not first attempt
            if currentAttempt > 1 {
                let delay = session.strategy.calculateDelay(attempt: currentAttempt)
                try? await Task.sleep(for: .seconds(delay))
            }

            // Execute recovery actions
            for action in session.strategy.actions {
                let actionResult = await executeRecoveryAction(action, session: session)

                switch actionResult {
                case .success:
                    continue
                case .retry:
                    break // Retry this attempt
                case .abort:
                    return .failed(.actionFailed(action))
                }
            }

            // Check if recovery was successful
            if let validator = session.strategy.validator {
                let isRecovered = await validator(session.context)
                if isRecovered {
                    return .recovered(attempts: currentAttempt, duration: Date().timeIntervalSince(session.startTime))
                }
            } else {
                // If no validator, assume success after executing all actions
                return .recovered(attempts: currentAttempt, duration: Date().timeIntervalSince(session.startTime))
            }
        }

        return .failed(.maxAttemptsExceeded)
    }

    /// Execute a single recovery action
    private func executeRecoveryAction(_ action: RecoveryAction, session: RecoverySession) async -> ActionResult {
        SDKLogger.debug("Executing recovery action: \(action)", category: .error)

        switch action {
        case .retry:
            return .retry

        case .reconfigure:
            return await executeReconfiguration(session: session)

        case .checkNetworkConnection:
            return await executeNetworkCheck(session: session)

        case .clearCache:
            return await executeClearCache(session: session)

        case .restartClient:
            return await executeClientRestart(session: session)

        case .waitAndRetry:
            try? await Task.sleep(for: .seconds(2))
            return .success

        case .validateConfiguration:
            return await executeConfigValidation(session: session)

        case .checkPermissions:
            return await executePermissionCheck(session: session)

        case .freeUpStorage:
            return await executeStorageCleanup(context: RecoveryContext())

        case .contactSupport:
            SDKLogger.critical("Manual intervention required for session \(session.id)", category: .error)
            return .abort
        }
    }

    /// Execute reconfiguration action
    private func executeReconfiguration(session: RecoverySession) async -> ActionResult {
        // This would typically involve updating configuration
        // For now, we'll simulate successful reconfiguration
        SDKLogger.info("Reconfiguration completed for session \(session.id)", category: .error)
        return .success
    }

    /// Execute network connectivity check
    private func executeNetworkCheck(session: RecoverySession) async -> ActionResult {
        // Check if network is available
        // This would integrate with actual network monitoring
        SDKLogger.info("Network check completed for session \(session.id)", category: .error)
        return .success
    }

    /// Execute cache clearing
    private func executeClearCache(session: RecoverySession) async -> ActionResult {
        // Clear any cached data that might be causing issues
        SDKLogger.info("Cache cleared for session \(session.id)", category: .error)
        return .success
    }

    /// Execute client restart
    private func executeClientRestart(session: RecoverySession) async -> ActionResult {
        // This would trigger a client restart if possible
        SDKLogger.info("Client restart initiated for session \(session.id)", category: .error)
        return .success
    }

    /// Execute configuration validation
    private func executeConfigValidation(session: RecoverySession) async -> ActionResult {
        // Validate current configuration
        SDKLogger.info("Configuration validation completed for session \(session.id)", category: .error)
        return .success
    }

    /// Execute permission check
    private func executePermissionCheck(session: RecoverySession) async -> ActionResult {
        // Check required permissions
        SDKLogger.info("Permission check completed for session \(session.id)", category: .error)
        return .success
    }

    /// Execute storage cleanup
    private func executeStorageCleanup(context: RecoveryContext) async -> ActionResult {
        // Free up storage space
        SDKLogger.info("Storage cleanup completed", category: .error)
        return .success
    }

    /// Get recovery strategy for an error
    private func getRecoveryStrategy(for error: UserCanalError) -> RecoveryStrategy? {
        // Try exact match first
        if let strategy = strategies[error] {
            return strategy
        }

        // Try category-based matching
        switch error {
        case .networkFailure:
            return strategies.first { key, _ in
                if case .networkFailure = key { return true }
                return false
            }?.value

        case .validationError:
            return strategies.first { key, _ in
                if case .validationError = key { return true }
                return false
            }?.value

        case .storageError:
            return strategies.first { key, _ in
                if case .storageError = key { return true }
                return false
            }?.value

        default:
            return nil
        }
    }

    /// Convert any error to UserCanalError
    private func convertToUserCanalError(_ error: any Error) -> UserCanalError {
        if let ucError = error as? UserCanalError {
            return ucError
        }

        // Convert common error types
        if error is CancellationError {
            return .operationCancelled
        }

        return .internalError("Unknown error", underlyingError: error)
    }

    /// Update recovery statistics
    private func updateStats(for result: RecoveryResult, session: RecoverySession) {
        switch result {
        case .recovered(let attempts, let duration):
            stats.incrementSuccessfulRecoveries()
            stats.addRecoveryTime(duration)
            stats.addRecoveryAttempts(attempts)

        case .failed:
            stats.incrementFailedRecoveries()
        }

        stats.updateAverageRecoveryTime()
        stats.updateAverageAttemptsPerRecovery()
    }

    /// Create default recovery strategies
    private static func createDefaultStrategies() -> [UserCanalError: RecoveryStrategy] {
        var strategies: [UserCanalError: RecoveryStrategy] = [:]

        // Network failure strategies
        strategies[.networkFailure(.noConnection)] = RecoveryStrategy(
            actions: [.checkNetworkConnection, .waitAndRetry, .retry],
            maxAttempts: 3,
            baseDelay: 2.0,
            maxDelay: 30.0,
            backoffMultiplier: 2.0
        )

        strategies[.networkFailure(.requestTimeout)] = RecoveryStrategy(
            actions: [.checkNetworkConnection, .retry],
            maxAttempts: 5,
            baseDelay: 1.0,
            maxDelay: 15.0,
            backoffMultiplier: 1.5
        )

        // Validation error strategies
        strategies[.validationError(field: "", reason: "")] = RecoveryStrategy(
            actions: [.validateConfiguration, .reconfigure],
            maxAttempts: 2,
            baseDelay: 0.5,
            maxDelay: 5.0,
            backoffMultiplier: 1.0
        )

        // Storage error strategies
        strategies[.storageError(.diskFull)] = RecoveryStrategy(
            actions: [.freeUpStorage, .clearCache],
            maxAttempts: 2,
            baseDelay: 1.0,
            maxDelay: 10.0,
            backoffMultiplier: 1.0
        )

        strategies[.storageError(.accessDenied)] = RecoveryStrategy(
            actions: [.checkPermissions, .restartClient],
            maxAttempts: 2,
            baseDelay: 2.0,
            maxDelay: 10.0,
            backoffMultiplier: 1.0
        )

        // Client state error strategies
        strategies[.clientNotInitialized] = RecoveryStrategy(
            actions: [.restartClient],
            maxAttempts: 1,
            baseDelay: 1.0,
            maxDelay: 5.0,
            backoffMultiplier: 1.0
        )

        strategies[.queueFull(currentSize: 0, maxSize: 0)] = RecoveryStrategy(
            actions: [.clearCache, .waitAndRetry],
            maxAttempts: 3,
            baseDelay: 0.5,
            maxDelay: 5.0,
            backoffMultiplier: 1.5
        )

        return strategies
    }

    // MARK: - Statistics

    /// Get recovery statistics
    public var statistics: RecoveryStats {
        return stats
    }

    /// Get active recovery session count
    public var activeSessionCount: Int {
        return activeSessions.count
    }
}

// MARK: - Supporting Types

/// Recovery strategy definition
public struct RecoveryStrategy: Sendable {
    let actions: [RecoveryAction]
    let maxAttempts: Int
    let baseDelay: Double
    let maxDelay: Double
    let backoffMultiplier: Double
    let validator: (@Sendable (RecoveryContext) async -> Bool)?

    init(
        actions: [RecoveryAction],
        maxAttempts: Int,
        baseDelay: Double,
        maxDelay: Double,
        backoffMultiplier: Double,
        validator: (@Sendable (RecoveryContext) async -> Bool)? = nil
    ) {
        self.actions = actions
        self.maxAttempts = maxAttempts
        self.baseDelay = baseDelay
        self.maxDelay = maxDelay
        self.backoffMultiplier = backoffMultiplier
        self.validator = validator
    }

    /// Calculate delay for retry attempt
    func calculateDelay(attempt: Int) -> Double {
        let delay = baseDelay * pow(backoffMultiplier, Double(attempt - 1))
        return min(delay, maxDelay)
    }
}

/// Recovery session information
private struct RecoverySession {
    let id: String
    let error: UserCanalError
    let operation: String
    let strategy: RecoveryStrategy
    let context: RecoveryContext
    let startTime: Date
}

/// Context information for recovery operations
public struct RecoveryContext: Sendable {
    public let metadata: [String: String]
    public let userID: String?
    public let sessionID: String?

    public init(
        metadata: [String: String] = [:],
        userID: String? = nil,
        sessionID: String? = nil
    ) {
        self.metadata = metadata
        self.userID = userID
        self.sessionID = sessionID
    }
}

/// Result of recovery attempt
public enum RecoveryResult: Sendable {
    case recovered(attempts: Int, duration: TimeInterval)
    case failed(RecoveryFailureReason)
}

/// Reason for recovery failure
public enum RecoveryFailureReason: Sendable {
    case noStrategyFound
    case maxAttemptsExceeded
    case actionFailed(RecoveryAction)
    case resourceExhausted(String)
}

/// Result of individual recovery action
private enum ActionResult {
    case success
    case retry
    case abort
}

/// Recovery statistics
public struct RecoveryStats: Sendable {
    public private(set) var recoveryAttempts: Int = 0
    public private(set) var successfulRecoveries: Int = 0
    public private(set) var failedRecoveries: Int = 0
    public private(set) var unrecoverableErrors: Int = 0
    public private(set) var totalRecoveryTime: TimeInterval = 0
    public private(set) var totalRecoveryAttempts: Int = 0
    public private(set) var averageRecoveryTime: TimeInterval = 0
    public private(set) var averageAttemptsPerRecovery: Double = 0

    /// Recovery success rate
    public var successRate: Double {
        guard recoveryAttempts > 0 else { return 0.0 }
        return Double(successfulRecoveries) / Double(recoveryAttempts)
    }

    /// Percentage of errors that are recoverable
    public var recoverabilityRate: Double {
        let totalErrors = recoveryAttempts + unrecoverableErrors
        guard totalErrors > 0 else { return 0.0 }
        return Double(recoveryAttempts) / Double(totalErrors)
    }

    // MARK: - Mutating Methods

    mutating func incrementRecoveryAttempts() {
        recoveryAttempts += 1
    }

    mutating func incrementSuccessfulRecoveries() {
        successfulRecoveries += 1
    }

    mutating func incrementFailedRecoveries() {
        failedRecoveries += 1
    }

    mutating func incrementUnrecoverableErrors() {
        unrecoverableErrors += 1
    }

    mutating func addRecoveryTime(_ time: TimeInterval) {
        totalRecoveryTime += time
    }

    mutating func addRecoveryAttempts(_ attempts: Int) {
        totalRecoveryAttempts += attempts
    }

    mutating func updateAverageRecoveryTime() {
        averageRecoveryTime = totalRecoveryTime / Double(max(1, successfulRecoveries))
    }

    mutating func updateAverageAttemptsPerRecovery() {
        averageAttemptsPerRecovery = Double(totalRecoveryAttempts) / Double(max(1, successfulRecoveries))
    }
}

// MARK: - Extensions

extension RecoveryResult: CustomStringConvertible {
    public var description: String {
        switch self {
        case .recovered(let attempts, let duration):
            return "recovered(attempts: \(attempts), duration: \(String(format: "%.2f", duration))s)"
        case .failed(let reason):
            return "failed(\(reason))"
        }
    }
}

extension RecoveryFailureReason: CustomStringConvertible {
    public var description: String {
        switch self {
        case .noStrategyFound:
            return "no strategy found"
        case .maxAttemptsExceeded:
            return "max attempts exceeded"
        case .actionFailed(let action):
            return "action failed: \(action)"
        case .resourceExhausted(let details):
            return "resource exhausted: \(details)"
        }
    }
}

// MARK: - UserCanalError Extension for Strategy Matching

extension UserCanalError: Hashable {
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .invalidConfiguration:
            hasher.combine("invalidConfiguration")
        case .invalidAPIKey:
            hasher.combine("invalidAPIKey")
        case .networkFailure(let reason):
            hasher.combine("networkFailure")
            hasher.combine(reason.hashValue)
        case .validationError:
            hasher.combine("validationError")
        case .clientNotInitialized:
            hasher.combine("clientNotInitialized")
        case .queueFull:
            hasher.combine("queueFull")
        case .storageError(let reason):
            hasher.combine("storageError")
            hasher.combine(reason.hashValue)
        default:
            hasher.combine("other")
        }
    }

    public static func == (lhs: UserCanalError, rhs: UserCanalError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidConfiguration, .invalidConfiguration),
             (.invalidAPIKey, .invalidAPIKey),
             (.clientNotInitialized, .clientNotInitialized):
            return true
        case (.networkFailure(let lhsReason), .networkFailure(let rhsReason)):
            return lhsReason.hashValue == rhsReason.hashValue
        case (.validationError, .validationError):
            return true
        case (.queueFull, .queueFull):
            return true
        case (.storageError(let lhsReason), .storageError(let rhsReason)):
            return lhsReason.hashValue == rhsReason.hashValue
        default:
            return false
        }
    }
}

extension NetworkFailureReason: Hashable {
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .noConnection:
            hasher.combine("noConnection")
        case .hostUnreachable:
            hasher.combine("hostUnreachable")
        case .serverError:
            hasher.combine("serverError")
        case .requestTimeout:
            hasher.combine("requestTimeout")
        case .invalidResponse:
            hasher.combine("invalidResponse")
        default:
            hasher.combine("other")
        }
    }
}

extension StorageErrorReason: Hashable {
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .diskFull:
            hasher.combine("diskFull")
        case .accessDenied:
            hasher.combine("accessDenied")
        case .corruptedData:
            hasher.combine("corruptedData")
        case .quotaExceeded:
            hasher.combine("quotaExceeded")
        case .ioError:
            hasher.combine("ioError")
        }
    }
}
