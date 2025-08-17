// LogEntry.swift
// UserCanal Swift SDK
//
// Copyright © 2024 UserCanal. All rights reserved.
//

import Foundation

// MARK: - LogEntry

/// Represents a structured log entry
public struct LogEntry: Sendable {

    // MARK: - Properties

    /// Type of log event for routing
    public let eventType: LogEventType

    /// Session ID for distributed tracing and correlation (16-byte UUID)
    public let sessionID: Data

    /// Log level/severity
    public let level: LogLevel

    /// Timestamp when the log was created
    public let timestamp: Date

    /// Source identifier (hostname, instance, etc.)
    public let source: String

    /// Service name that generated the log
    public let service: String

    /// Log message
    public let message: String

    /// Structured log data
    public let data: Properties

    // MARK: - Initialization

    /// Create a new log entry
    public init(
        eventType: LogEventType = .log,
        sessionID: Data = Data(),
        level: LogLevel,
        timestamp: Date = Date(),
        source: String = ProcessInfo.processInfo.hostName,
        service: String,
        message: String,
        data: Properties = Properties()
    ) {
        self.eventType = eventType
        self.sessionID = sessionID
        self.level = level
        self.timestamp = timestamp
        self.source = source
        self.service = service
        self.message = message
        self.data = data
    }

    /// Create a log entry with data builder
    public init(
        eventType: LogEventType = .log,
        sessionID: Data = Data(),
        level: LogLevel,
        timestamp: Date = Date(),
        source: String = ProcessInfo.processInfo.hostName,
        service: String,
        message: String,
        data: () -> Properties
    ) {
        self.eventType = eventType
        self.sessionID = sessionID
        self.level = level
        self.timestamp = timestamp
        self.source = source
        self.service = service
        self.message = message
        self.data = data()
    }
}

// MARK: - LogLevel

/// Log severity levels following RFC 5424 with additional TRACE level
public enum LogLevel: UInt8, Sendable, CaseIterable, Codable {
    case emergency = 0  // System is unusable
    case alert = 1      // Action must be taken immediately
    case critical = 2   // Critical conditions
    case error = 3      // Error conditions
    case warning = 4    // Warning conditions
    case notice = 5     // Normal but significant condition
    case info = 6       // Informational messages
    case debug = 7      // Debug-level messages
    case trace = 8      // Detailed trace information

    /// Human-readable description
    public var description: String {
        switch self {
        case .emergency: return "EMERGENCY"
        case .alert: return "ALERT"
        case .critical: return "CRITICAL"
        case .error: return "ERROR"
        case .warning: return "WARNING"
        case .notice: return "NOTICE"
        case .info: return "INFO"
        case .debug: return "DEBUG"
        case .trace: return "TRACE"
        }
    }

    /// Short string representation
    public var shortString: String {
        switch self {
        case .emergency: return "EMRG"
        case .alert: return "ALRT"
        case .critical: return "CRIT"
        case .error: return "ERRR"
        case .warning: return "WARN"
        case .notice: return "NOTE"
        case .info: return "INFO"
        case .debug: return "DEBG"
        case .trace: return "TRCE"
        }
    }
}

// MARK: - LogEventType

/// Log event types for routing and processing
public enum LogEventType: UInt8, Sendable, CaseIterable, Codable {
    case unknown = 0
    case log = 1       // Standard log collection (LogCollect)
    case enrich = 2    // Log enrichment/annotation (LogEnrich)

    /// Human-readable description
    public var description: String {
        switch self {
        case .unknown: return "UNKNOWN"
        case .log: return "LOG"
        case .enrich: return "ENRICH"
        }
    }
}

// MARK: - Validation Extensions

extension LogEntry {
    /// Validate the log entry
    public func validate() throws {
        guard !service.isEmpty else {
            throw UserCanalError.validationError(field: "service", reason: "Service name cannot be empty")
        }

        guard !message.isEmpty else {
            throw UserCanalError.validationError(field: "message", reason: "Log message cannot be empty")
        }

        guard !source.isEmpty else {
            throw UserCanalError.validationError(field: "source", reason: "Source cannot be empty")
        }
    }
}

// MARK: - Codable Conformance

extension LogEntry: Codable {}

// MARK: - CustomStringConvertible

extension LogEntry: CustomStringConvertible {
    public var description: String {
        return "LogEntry(level: \(level.description), service: \(service), message: \(message), timestamp: \(timestamp))"
    }
}

extension LogLevel: CustomStringConvertible {}

extension LogEventType: CustomStringConvertible {}

// MARK: - Comparable

extension LogLevel: Comparable {
    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Convenience Constructors

extension LogEntry {

    /// Create an info log entry
    public static func info(
        service: String,
        message: String,
        data: Properties = Properties(),
        sessionID: Data = Data(),
        source: String = ProcessInfo.processInfo.hostName
    ) -> LogEntry {
        return LogEntry(
            eventType: .log,
            sessionID: sessionID,
            level: .info,
            source: source,
            service: service,
            message: message,
            data: data
        )
    }

    /// Create an error log entry
    public static func error(
        service: String,
        message: String,
        data: Properties = Properties(),
        sessionID: Data = Data(),
        source: String = ProcessInfo.processInfo.hostName
    ) -> LogEntry {
        return LogEntry(
            eventType: .log,
            sessionID: sessionID,
            level: .error,
            source: source,
            service: service,
            message: message,
            data: data
        )
    }

    /// Create a debug log entry
    public static func debug(
        service: String,
        message: String,
        data: Properties = Properties(),
        sessionID: Data = Data(),
        source: String = ProcessInfo.processInfo.hostName
    ) -> LogEntry {
        return LogEntry(
            eventType: .log,
            sessionID: sessionID,
            level: .debug,
            source: source,
            service: service,
            message: message,
            data: data
        )
    }

    /// Create a warning log entry
    public static func warning(
        service: String,
        message: String,
        data: Properties = Properties(),
        sessionID: Data = Data(),
        source: String = ProcessInfo.processInfo.hostName
    ) -> LogEntry {
        return LogEntry(
            eventType: .log,
            sessionID: sessionID,
            level: .warning,
            source: source,
            service: service,
            message: message,
            data: data
        )
    }

    /// Create an enrichment log entry
    public static func enrichment(
        service: String,
        message: String,
        data: Properties = Properties(),
        sessionID: Data = Data(),
        source: String = ProcessInfo.processInfo.hostName
    ) -> LogEntry {
        return LogEntry(
            eventType: .enrich,
            sessionID: sessionID,
            level: .info,
            source: source,
            service: service,
            message: message,
            data: data
        )
    }
}
