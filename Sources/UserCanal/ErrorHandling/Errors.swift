// Errors.swift
// UserCanal Swift SDK
//
// Copyright © 2024 UserCanal. All rights reserved.
//

import Foundation

// MARK: - Main SDK Error Type

/// Primary error type for the UserCanal Swift SDK
public enum UserCanalError: Error, Sendable {
    
    // MARK: - Configuration Errors
    case invalidConfiguration(String)
    case invalidAPIKey(String)
    case missingConfiguration(String)
    
    // MARK: - Network Errors
    case networkFailure(NetworkFailureReason)
    case connectionTimeout(Duration)
    case connectionFailed(String)
    case dnsResolutionFailed(String)
    
    // MARK: - Protocol Errors
    case protocolError(ProtocolErrorReason)
    case serializationFailed(String)
    case deserializationFailed(String)
    case incompatibleProtocolVersion(expected: String, received: String)
    
    // MARK: - Validation Errors
    case validationError(field: String, reason: String)
    case invalidEventData(String)
    case invalidUserID(String)
    case invalidProperties(String)
    
    // MARK: - Client State Errors
    case clientNotInitialized
    case clientAlreadyClosed
    case clientShuttingDown
    case operationCancelled
    
    // MARK: - Batching Errors
    case batchingError(BatchingErrorReason)
    case queueFull(currentSize: Int, maxSize: Int)
    case flushTimeout(Duration)
    
    // MARK: - Device Context Errors
    case deviceContextError(DeviceContextErrorReason)
    case deviceContextUnavailable(String)
    case permissionDenied(String)
    
    // MARK: - Storage Errors
    case storageError(StorageErrorReason)
    case persistenceFailed(String)
    case dataCorrupted(String)
    
    // MARK: - Authentication Errors
    case authenticationFailed(String)
    case unauthorizedAccess(String)
    case rateLimited(retryAfter: Duration?)
    
    // MARK: - Internal Errors
    case internalError(String, underlyingError: (any Error)?)
    case unexpectedState(String)
    case resourceExhausted(String)
}

// MARK: - Error Reason Types

/// Reasons for network failures
public enum NetworkFailureReason: Sendable, Equatable {
    case noConnection
    case hostUnreachable(String)
    case serverError(statusCode: Int, message: String?)
    case requestTimeout
    case invalidResponse
    case unknownHost(String)
    case connectionReset
    case tooManyRedirects
}

/// Reasons for protocol errors
public enum ProtocolErrorReason: Sendable {
    case invalidMessageFormat
    case unsupportedMessageType(String)
    case messageTooBig(size: Int, maxSize: Int)
    case checksumMismatch
    case compressionError(String)
    case encodingError(String)
}

/// Reasons for batching errors
public enum BatchingErrorReason: Sendable {
    case batchSizeExceeded(currentSize: Int, maxSize: Int)
    case batchTimeout
    case batchProcessingFailed(String)
    case invalidBatchState(String)
    case concurrencyConflict
}

/// Reasons for device context errors
public enum DeviceContextErrorReason: Sendable {
    case contextCollectionFailed(String)
    case unsupportedPlatform
    case insufficientPermissions([String])
    case contextDataCorrupted
    case contextUpdateFailed(String)
}

/// Reasons for storage errors
public enum StorageErrorReason: Sendable, Equatable {
    case diskFull
    case accessDenied
    case corruptedData(String)
    case migrationFailed(String)
    case quotaExceeded(used: Int, limit: Int)
    case ioError(String)
}

// MARK: - Error Recovery Information

/// Information about error recovery options
public struct ErrorRecoveryInfo: Sendable {
    public let isRecoverable: Bool
    public let suggestedRetryDelay: Duration?
    public let maxRetryAttempts: Int?
    public let recoveryActions: [RecoveryAction]
    
    public init(
        isRecoverable: Bool,
        suggestedRetryDelay: Duration? = nil,
        maxRetryAttempts: Int? = nil,
        recoveryActions: [RecoveryAction] = []
    ) {
        self.isRecoverable = isRecoverable
        self.suggestedRetryDelay = suggestedRetryDelay
        self.maxRetryAttempts = maxRetryAttempts
        self.recoveryActions = recoveryActions
    }
}

/// Suggested recovery actions for errors
public enum RecoveryAction: String, Sendable, CaseIterable {
    case retry = "retry"
    case reconfigure = "reconfigure"
    case checkNetworkConnection = "check_network"
    case clearCache = "clear_cache"
    case restartClient = "restart_client"
    case contactSupport = "contact_support"
    case waitAndRetry = "wait_and_retry"
    case validateConfiguration = "validate_configuration"
    case checkPermissions = "check_permissions"
    case freeUpStorage = "free_up_storage"
}

// MARK: - Error Extension - Recovery Info

extension UserCanalError {
    /// Get recovery information for this error
    public var recoveryInfo: ErrorRecoveryInfo {
        switch self {
        case .networkFailure(let reason):
            return reason.recoveryInfo
            
        case .connectionTimeout:
            return ErrorRecoveryInfo(
                isRecoverable: true,
                suggestedRetryDelay: .seconds(2),
                maxRetryAttempts: 3,
                recoveryActions: [.retry, .checkNetworkConnection]
            )
            
        case .validationError:
            return ErrorRecoveryInfo(
                isRecoverable: false,
                recoveryActions: [.validateConfiguration]
            )
            
        case .clientNotInitialized:
            return ErrorRecoveryInfo(
                isRecoverable: true,
                recoveryActions: [.restartClient]
            )
            
        case .queueFull:
            return ErrorRecoveryInfo(
                isRecoverable: true,
                suggestedRetryDelay: .milliseconds(500),
                maxRetryAttempts: 5,
                recoveryActions: [.waitAndRetry, .clearCache]
            )
            
        case .rateLimited(let retryAfter):
            return ErrorRecoveryInfo(
                isRecoverable: true,
                suggestedRetryDelay: retryAfter ?? .seconds(60),
                maxRetryAttempts: 1,
                recoveryActions: [.waitAndRetry]
            )
            
        case .storageError(let reason):
            return reason.recoveryInfo
            
        case .deviceContextError(let reason):
            return reason.recoveryInfo
            
        default:
            return ErrorRecoveryInfo(
                isRecoverable: true,
                suggestedRetryDelay: .seconds(1),
                maxRetryAttempts: 3,
                recoveryActions: [.retry]
            )
        }
    }
}

// MARK: - Recovery Info for Reason Types

extension NetworkFailureReason {
    var recoveryInfo: ErrorRecoveryInfo {
        switch self {
        case .noConnection, .hostUnreachable:
            return ErrorRecoveryInfo(
                isRecoverable: true,
                suggestedRetryDelay: .seconds(5),
                maxRetryAttempts: 3,
                recoveryActions: [.checkNetworkConnection, .waitAndRetry]
            )
            
        case .serverError(let statusCode, _):
            let retryable = (500...599).contains(statusCode)
            return ErrorRecoveryInfo(
                isRecoverable: retryable,
                suggestedRetryDelay: retryable ? .seconds(2) : nil,
                maxRetryAttempts: retryable ? 3 : nil,
                recoveryActions: retryable ? [.retry] : [.contactSupport]
            )
            
        case .requestTimeout:
            return ErrorRecoveryInfo(
                isRecoverable: true,
                suggestedRetryDelay: .seconds(1),
                maxRetryAttempts: 3,
                recoveryActions: [.retry, .checkNetworkConnection]
            )
            
        default:
            return ErrorRecoveryInfo(
                isRecoverable: false,
                recoveryActions: [.contactSupport]
            )
        }
    }
}

extension StorageErrorReason {
    var recoveryInfo: ErrorRecoveryInfo {
        switch self {
        case .diskFull, .quotaExceeded:
            return ErrorRecoveryInfo(
                isRecoverable: true,
                recoveryActions: [.freeUpStorage, .clearCache]
            )
            
        case .accessDenied:
            return ErrorRecoveryInfo(
                isRecoverable: true,
                recoveryActions: [.checkPermissions, .restartClient]
            )
            
        case .corruptedData, .migrationFailed:
            return ErrorRecoveryInfo(
                isRecoverable: true,
                recoveryActions: [.clearCache, .restartClient]
            )
            
        case .ioError:
            return ErrorRecoveryInfo(
                isRecoverable: true,
                suggestedRetryDelay: .seconds(1),
                maxRetryAttempts: 3,
                recoveryActions: [.retry, .freeUpStorage]
            )
        }
    }
}

extension DeviceContextErrorReason {
    var recoveryInfo: ErrorRecoveryInfo {
        switch self {
        case .insufficientPermissions:
            return ErrorRecoveryInfo(
                isRecoverable: true,
                recoveryActions: [.checkPermissions]
            )
            
        case .contextCollectionFailed, .contextUpdateFailed:
            return ErrorRecoveryInfo(
                isRecoverable: true,
                suggestedRetryDelay: .seconds(2),
                maxRetryAttempts: 3,
                recoveryActions: [.retry]
            )
            
        case .unsupportedPlatform:
            return ErrorRecoveryInfo(
                isRecoverable: false,
                recoveryActions: [.contactSupport]
            )
            
        case .contextDataCorrupted:
            return ErrorRecoveryInfo(
                isRecoverable: true,
                recoveryActions: [.clearCache, .restartClient]
            )
        }
    }
}

// MARK: - LocalizedError Conformance

extension UserCanalError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidConfiguration(let details):
            return "Invalid configuration: \(details)"
            
        case .invalidAPIKey(let reason):
            return "Invalid API key: \(reason)"
            
        case .missingConfiguration(let parameter):
            return "Missing required configuration: \(parameter)"
            
        case .networkFailure(let reason):
            return "Network failure: \(reason.localizedDescription)"
            
        case .connectionTimeout(let duration):
            return "Connection timed out after \(duration)"
            
        case .connectionFailed(let reason):
            return "Connection failed: \(reason)"
            
        case .dnsResolutionFailed(let host):
            return "DNS resolution failed for host: \(host)"
            
        case .protocolError(let reason):
            return "Protocol error: \(reason.localizedDescription)"
            
        case .serializationFailed(let details):
            return "Serialization failed: \(details)"
            
        case .deserializationFailed(let details):
            return "Deserialization failed: \(details)"
            
        case .incompatibleProtocolVersion(let expected, let received):
            return "Incompatible protocol version. Expected: \(expected), Received: \(received)"
            
        case .validationError(let field, let reason):
            return "Validation error in field '\(field)': \(reason)"
            
        case .invalidEventData(let details):
            return "Invalid event data: \(details)"
            
        case .invalidUserID(let details):
            return "Invalid user ID: \(details)"
            
        case .invalidProperties(let details):
            return "Invalid properties: \(details)"
            
        case .clientNotInitialized:
            return "Client is not initialized"
            
        case .clientAlreadyClosed:
            return "Client is already closed"
            
        case .clientShuttingDown:
            return "Client is shutting down"
            
        case .operationCancelled:
            return "Operation was cancelled"
            
        case .batchingError(let reason):
            return "Batching error: \(reason.localizedDescription)"
            
        case .queueFull(let currentSize, let maxSize):
            return "Queue is full (\(currentSize)/\(maxSize))"
            
        case .flushTimeout(let duration):
            return "Flush operation timed out after \(duration)"
            
        case .deviceContextError(let reason):
            return "Device context error: \(reason.localizedDescription)"
            
        case .deviceContextUnavailable(let reason):
            return "Device context unavailable: \(reason)"
            
        case .permissionDenied(let resource):
            return "Permission denied for: \(resource)"
            
        case .storageError(let reason):
            return "Storage error: \(reason.localizedDescription)"
            
        case .persistenceFailed(let details):
            return "Persistence failed: \(details)"
            
        case .dataCorrupted(let details):
            return "Data corrupted: \(details)"
            
        case .authenticationFailed(let reason):
            return "Authentication failed: \(reason)"
            
        case .unauthorizedAccess(let resource):
            return "Unauthorized access to: \(resource)"
            
        case .rateLimited(let retryAfter):
            if let retryAfter = retryAfter {
                return "Rate limited. Retry after: \(retryAfter)"
            } else {
                return "Rate limited"
            }
            
        case .internalError(let details, let underlyingError):
            if let underlyingError = underlyingError {
                return "Internal error: \(details). Underlying error: \(underlyingError.localizedDescription)"
            } else {
                return "Internal error: \(details)"
            }
            
        case .unexpectedState(let details):
            return "Unexpected state: \(details)"
            
        case .resourceExhausted(let resource):
            return "Resource exhausted: \(resource)"
        }
    }
    
    public var failureReason: String? {
        switch self {
        case .networkFailure(let reason):
            return reason.failureReason
        case .protocolError(let reason):
            return reason.failureReason
        case .batchingError(let reason):
            return reason.failureReason
        case .storageError(let reason):
            return reason.failureReason
        case .deviceContextError(let reason):
            return reason.failureReason
        default:
            return nil
        }
    }
}

// MARK: - Reason Type LocalizedError Conformance

extension NetworkFailureReason: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .noConnection:
            return "No network connection available"
        case .hostUnreachable(let host):
            return "Host unreachable: \(host)"
        case .serverError(let statusCode, let message):
            return "Server error \(statusCode)" + (message.map { ": \($0)" } ?? "")
        case .requestTimeout:
            return "Request timed out"
        case .invalidResponse:
            return "Invalid response received"
        case .unknownHost(let host):
            return "Unknown host: \(host)"
        case .connectionReset:
            return "Connection was reset"
        case .tooManyRedirects:
            return "Too many redirects"
        }
    }
    
    public var failureReason: String? {
        switch self {
        case .noConnection:
            return "Device is not connected to the internet"
        case .hostUnreachable:
            return "The server cannot be reached"
        case .serverError:
            return "The server encountered an error"
        case .requestTimeout:
            return "The request took too long to complete"
        default:
            return nil
        }
    }
}

extension ProtocolErrorReason: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidMessageFormat:
            return "Invalid message format"
        case .unsupportedMessageType(let type):
            return "Unsupported message type: \(type)"
        case .messageTooBig(let size, let maxSize):
            return "Message too big: \(size) bytes (max: \(maxSize))"
        case .checksumMismatch:
            return "Checksum mismatch"
        case .compressionError(let details):
            return "Compression error: \(details)"
        case .encodingError(let details):
            return "Encoding error: \(details)"
        }
    }
    
    public var failureReason: String? {
        return "Protocol communication failed"
    }
}

extension BatchingErrorReason: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .batchSizeExceeded(let currentSize, let maxSize):
            return "Batch size exceeded: \(currentSize)/\(maxSize)"
        case .batchTimeout:
            return "Batch processing timed out"
        case .batchProcessingFailed(let details):
            return "Batch processing failed: \(details)"
        case .invalidBatchState(let state):
            return "Invalid batch state: \(state)"
        case .concurrencyConflict:
            return "Concurrency conflict in batch processing"
        }
    }
    
    public var failureReason: String? {
        return "Batch processing encountered an error"
    }
}

extension DeviceContextErrorReason: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .contextCollectionFailed(let details):
            return "Device context collection failed: \(details)"
        case .unsupportedPlatform:
            return "Unsupported platform for device context collection"
        case .insufficientPermissions(let permissions):
            return "Insufficient permissions: \(permissions.joined(separator: ", "))"
        case .contextDataCorrupted:
            return "Device context data is corrupted"
        case .contextUpdateFailed(let details):
            return "Device context update failed: \(details)"
        }
    }
    
    public var failureReason: String? {
        return "Device context collection failed"
    }
}

extension StorageErrorReason: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .diskFull:
            return "Disk is full"
        case .accessDenied:
            return "Storage access denied"
        case .corruptedData(let details):
            return "Corrupted data: \(details)"
        case .migrationFailed(let details):
            return "Data migration failed: \(details)"
        case .quotaExceeded(let used, let limit):
            return "Storage quota exceeded: \(used)/\(limit)"
        case .ioError(let details):
            return "I/O error: \(details)"
        }
    }
    
    public var failureReason: String? {
        return "Storage operation failed"
    }
}