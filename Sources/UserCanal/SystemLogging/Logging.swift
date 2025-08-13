// Logging.swift
// UserCanal Swift SDK - System Logging
//
// Copyright © 2024 UserCanal. All rights reserved.
//

import Foundation
import OSLog

// MARK: - System Logging

/// Internal SDK logging system (not user-facing logs)
/// This is for debugging the SDK itself, not for user application logs
public actor SDKLogger {

    // MARK: - Configuration

    /// Whether debug logging is enabled
    public static var isDebugEnabled: Bool = false

    /// Current log level threshold
    public static var logLevel: SystemLogLevel = .info

    // MARK: - Log Categories

    private static let generalLogger = Logger(subsystem: "com.usercanal.sdk", category: "general")
    private static let clientLogger = Logger(subsystem: "com.usercanal.sdk", category: "client")
    private static let networkLogger = Logger(subsystem: "com.usercanal.sdk", category: "network")
    private static let batchingLogger = Logger(subsystem: "com.usercanal.sdk", category: "batching")
    private static let deviceLogger = Logger(subsystem: "com.usercanal.sdk", category: "device")
    private static let eventLogger = Logger(subsystem: "com.usercanal.sdk", category: "events")
    private static let errorLogger = Logger(subsystem: "com.usercanal.sdk", category: "error")
    private static let configLogger = Logger(subsystem: "com.usercanal.sdk", category: "config")
    private static let sessionLogger = Logger(subsystem: "com.usercanal.sdk", category: "session")

    // MARK: - Public Logging Methods

    /// Log an info message
    public static func info(_ message: String, category: LogCategory = .general) {
        log(.info, message, category: category)
    }

    /// Log an error message
    public static func error(_ message: String, error: (any Error)? = nil, category: LogCategory = .general) {
        let fullMessage = error != nil ? "\(message): \(error!.localizedDescription)" : message
        log(.error, fullMessage, category: category)
    }

    /// Log a debug message
    public static func debug(_ message: String, category: LogCategory = .general) {
        log(.debug, message, category: category)
    }

    /// Log a warning message
    public static func warning(_ message: String, category: LogCategory = .general) {
        log(.warning, message, category: category)
    }

    /// Log a critical message
    public static func critical(_ message: String, category: LogCategory = .general) {
        log(.critical, message, category: category)
    }

    /// Log a trace message
    public static func trace(_ message: String, category: LogCategory = .general) {
        log(.trace, message, category: category)
    }

    // MARK: - Internal Logging

    private static func log(_ level: SystemLogLevel, _ message: String, category: LogCategory) {
        // Check if we should log this level
        guard level.priority <= logLevel.priority else { return }

        let logger = loggerFor(category: category)
        let formattedMessage = "[\(level.rawValue.uppercased())] UserCanal: \(message)"

        // Use appropriate OSLog level
        switch level.osLogType {
        case .fault:
            logger.fault("\(formattedMessage)")
        case .error:
            logger.error("\(formattedMessage)")
        case .info:
            logger.info("\(formattedMessage)")
        case .debug:
            logger.debug("\(formattedMessage)")
        default:
            logger.log("\(formattedMessage)")
        }

        // OSLog handles console output automatically - no need for duplicate print
    }

    // MARK: - Helper Methods

    private static func loggerFor(category: LogCategory) -> Logger {
        switch category {
        case .general:
            return generalLogger
        case .client:
            return clientLogger
        case .network:
            return networkLogger
        case .batching:
            return batchingLogger
        case .device:
            return deviceLogger
        case .events:
            return eventLogger
        case .error:
            return errorLogger
        case .config:
            return configLogger
        case .session:
            return sessionLogger
        }
    }
}

// MARK: - System Log Level

/// System log level enumeration for internal SDK logging
/// This is separate from user-facing LogLevel to avoid conflicts
public enum SystemLogLevel: String, Sendable, CaseIterable, Comparable, Codable {
    case emergency = "emergency"
    case alert = "alert"
    case critical = "critical"
    case error = "error"
    case warning = "warning"
    case notice = "notice"
    case info = "info"
    case debug = "debug"
    case trace = "trace"

    public static func < (lhs: SystemLogLevel, rhs: SystemLogLevel) -> Bool {
        return lhs.priority < rhs.priority
    }

    /// Priority order for log levels (lower = higher priority)
    var priority: Int {
        switch self {
        case .emergency: return 0
        case .alert: return 1
        case .critical: return 2
        case .error: return 3
        case .warning: return 4
        case .notice: return 5
        case .info: return 6
        case .debug: return 7
        case .trace: return 8
        }
    }

    /// Convert to OSLog level
    public var osLogType: OSLogType {
        switch self {
        case .emergency, .alert, .critical:
            return .fault
        case .error:
            return .error
        case .warning, .notice, .info:
            return .info
        case .debug, .trace:
            return .debug
        }
    }
}

// MARK: - Log Categories

/// Categories for organizing SDK logs
public enum LogCategory: String, Sendable, CaseIterable {
    case general = "general"
    case client = "client"
    case network = "network"
    case batching = "batching"
    case device = "device"
    case events = "events"
    case error = "error"
    case config = "config"
    case session = "session"
}

// MARK: - Configuration Extensions

extension SDKLogger {

    /// Configure SDK logging
    public static func configure(debugEnabled: Bool = false, logLevel: SystemLogLevel = .info) {
        self.isDebugEnabled = debugEnabled
        self.logLevel = logLevel

        if debugEnabled {
            info("Logging configured: debug enabled, level: \(logLevel.rawValue)")
        }
    }

    /// Enable debug logging
    public static func enableDebug() {
        isDebugEnabled = true
        logLevel = .debug
        info("Debug logging enabled")
    }

    /// Disable debug logging
    public static func disableDebug() {
        isDebugEnabled = false
        logLevel = .info
        info("Debug logging disabled")
    }
}

// MARK: - Convenience Extensions

extension SDKLogger {

    /// Log network activity
    public static func networkActivity(_ message: String, level: SystemLogLevel = .debug) {
        log(level, message, category: .network)
    }

    /// Log batching activity
    public static func batchingActivity(_ message: String, level: SystemLogLevel = .debug) {
        log(level, message, category: .batching)
    }

    /// Log device context activity
    public static func deviceActivity(_ message: String, level: SystemLogLevel = .debug) {
        log(level, message, category: .device)
    }

    /// Log event processing activity
    public static func eventActivity(_ message: String, level: SystemLogLevel = .debug) {
        log(level, message, category: .events)
    }

    /// Log client lifecycle activity
    public static func clientActivity(_ message: String, level: SystemLogLevel = .info) {
        log(level, message, category: .client)
    }
}
