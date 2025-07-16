// NetworkClient.swift
// UserCanal Swift SDK
//
// Copyright © 2024 UserCanal. All rights reserved.
//

import Foundation
import Network

// MARK: - Network Client

/// TCP network client using Swift's Network framework for UserCanal protocol
public actor NetworkClient {
    
    // MARK: - Properties
    
    /// Network connection
    private var connection: NWConnection?
    
    /// Connection state
    private var state: ConnectionState = .disconnected
    
    /// API key for authentication
    private let apiKey: Data
    
    /// Endpoint configuration
    private let endpoint: NWEndpoint
    
    /// Connection parameters
    private let parameters: NWParameters
    
    /// Retry configuration
    private let retryConfig: RetryConfig
    
    /// Connection statistics
    private var stats: NetworkStats = NetworkStats()
    
    /// Queue for network operations
    private let queue: DispatchQueue
    
    /// Connection monitoring
    private var pathMonitor: NWPathMonitor?
    
    /// Health check timer
    private var healthCheckTimer: Task<Void, Never>?
    
    /// Last successful operation time
    private var lastSuccessTime: Date = Date()
    
    /// Connection pool for reuse
    private var connectionPool: [NWConnection] = []
    
    // MARK: - Connection State
    
    private enum ConnectionState: Sendable, Equatable {
        case connecting
        case connected
        case disconnected
        case failed(any Error)
        
        static func == (lhs: ConnectionState, rhs: ConnectionState) -> Bool {
            switch (lhs, rhs) {
            case (.connecting, .connecting),
                 (.connected, .connected),
                 (.disconnected, .disconnected):
                return true
            case (.failed, .failed):
                return true // Compare by case, not error details
            default:
                return false
            }
        }
    }
    
    // MARK: - Initialization
    
    /// Create a new network client
    /// - Parameters:
    ///   - apiKey: API key as hex string
    ///   - endpoint: Server endpoint (host:port)
    ///   - config: Network configuration
    public init(apiKey: String, endpoint: String, config: NetworkConfig = .default) throws {
        // Validate and convert API key
        guard !apiKey.isEmpty else {
            throw UserCanalError.invalidAPIKey("API key cannot be empty")
        }
        
        guard let apiKeyData = Data(fromHexString: apiKey) else {
            throw UserCanalError.invalidAPIKey("API key must be valid hex string")
        }
        
        self.apiKey = apiKeyData
        
        // Parse endpoint
        let components = endpoint.split(separator: ":")
        guard components.count == 2,
              let port = UInt16(components[1]) else {
            throw UserCanalError.invalidConfiguration("Invalid endpoint format. Expected host:port")
        }
        
        let host = String(components[0])
        self.endpoint = NWEndpoint.hostPort(host: NWEndpoint.Host(host), port: NWEndpoint.Port(rawValue: port)!)
        
        // Configure TCP parameters
        self.parameters = NWParameters.tcp
        self.parameters.allowLocalEndpointReuse = true
        self.parameters.includePeerToPeer = false
        
        // Configure TCP options for performance
        let tcpOptions = NWProtocolTCP.Options()
        tcpOptions.noDelay = true
        tcpOptions.enableKeepalive = true
        tcpOptions.keepaliveIdle = 30 // seconds
        tcpOptions.connectionTimeout = 10 // seconds
        self.parameters.defaultProtocolStack.transportProtocol = tcpOptions
        
        self.retryConfig = config.retryConfig
        self.queue = DispatchQueue(label: "com.usercanal.network", qos: .userInitiated)
        
        // Start network path monitoring
        self.pathMonitor = NWPathMonitor()
        self.pathMonitor?.start(queue: queue)
        
        // Start health check monitoring
        Task {
            await startHealthCheckMonitoring()
        }
        
        SDKLogger.info("NetworkClient initialized for endpoint: \(endpoint)", category: .network)
    }
    
    // MARK: - Connection Management
    
    /// Connect to the server
    public func connect() async throws {
        guard state == .disconnected else {
            SDKLogger.warning("Connection attempt while in state: \(state)", category: .network)
            return
        }
        
        state = .connecting
        stats.incrementConnectionAttempts()
        
        SDKLogger.info("Connecting to \(endpoint)", category: .network)
        
        return try await withCheckedThrowingContinuation { continuation in
            let connection = NWConnection(to: endpoint, using: parameters)
            self.connection = connection
            
            connection.stateUpdateHandler = { [weak self] newState in
                Task { [weak self] in
                    await self?.handleStateChange(newState, continuation: continuation)
                }
            }
            
            connection.start(queue: queue)
        }
    }
    
    /// Handle connection state changes
    private func handleStateChange(
        _ newState: NWConnection.State,
        continuation: CheckedContinuation<Void, any Error>? = nil
    ) {
        switch newState {
        case .ready:
            state = .connected
            stats.setLastConnectedTime(Date())
            SDKLogger.info("Connection established", category: .network)
            continuation?.resume()
            
        case .failed(let error):
            state = .failed(error)
            stats.incrementConnectionFailures()
            SDKLogger.error("Connection failed", error: error, category: .network)
            continuation?.resume(throwing: UserCanalError.connectionFailed(error.localizedDescription))
            
        case .cancelled:
            state = .disconnected
            SDKLogger.info("Connection cancelled", category: .network)
            continuation?.resume(throwing: UserCanalError.operationCancelled)
            
        case .waiting(let error):
            SDKLogger.warning("Connection waiting: \(error)", category: .network)
            
        case .preparing:
            SDKLogger.debug("Connection preparing", category: .network)
            
        case .setup:
            SDKLogger.debug("Connection setup", category: .network)
            
        @unknown default:
            SDKLogger.warning("Unknown connection state", category: .network)
        }
    }
    
    /// Disconnect from the server
    public func disconnect() async {
        guard let connection = connection else { return }
        
        SDKLogger.info("Disconnecting from server", category: .network)
        
        connection.cancel()
        self.connection = nil
        state = .disconnected
    }
    
    /// Check if connected
    public var isConnected: Bool {
        return state == .connected && connection?.state == .ready
    }
    
    /// Start health check monitoring
    private func startHealthCheckMonitoring() {
        healthCheckTimer = Task {
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .seconds(30)) // Health check every 30 seconds
                    
                    if isConnected {
                        let isHealthy = await healthCheck()
                        if !isHealthy {
                            SDKLogger.warning("Health check failed, attempting reconnection", category: .network)
                            await attemptReconnection()
                        }
                    }
                } catch {
                    break // Task was cancelled
                }
            }
        }
    }
    
    /// Enhanced connection with pool management
    private func getOrCreateConnection() async throws -> NWConnection {
        // Try to reuse existing connection
        if let existingConnection = connection, existingConnection.state == .ready {
            return existingConnection
        }
        
        // Create new connection
        try await connect()
        
        guard let newConnection = connection else {
            throw UserCanalError.connectionFailed("Failed to create connection")
        }
        
        return newConnection
    }
    
    // MARK: - Data Sending
    
    /// Send a FlatBuffers batch to the server with enhanced error handling
    /// - Parameter data: FlatBuffers encoded batch data
    public func sendBatch(_ data: Data) async throws {
        // Validate batch size
        guard data.count <= NetworkConfig.maxBatchSize else {
            throw UserCanalError.validationError(
                field: "batch",
                reason: "Batch size \(data.count) exceeds maximum \(NetworkConfig.maxBatchSize)"
            )
        }
        
        // Get or create connection with retry logic
        let connection = try await getOrCreateConnection()
        
        // Create length-prefixed frame
        let frame = createFrame(for: data)
        
        SDKLogger.debug("Sending batch: \(data.count) bytes", category: .network)
        
        return try await withCheckedThrowingContinuation { continuation in
            connection.send(
                content: frame,
                completion: .contentProcessed { [weak self] error in
                    Task { [weak self] in
                        if let error = error {
                            await self?.handleSendError(error)
                            continuation.resume(throwing: UserCanalError.networkFailure(.requestTimeout))
                        } else {
                            await self?.handleSendSuccess(frameSize: frame.count)
                            continuation.resume()
                        }
                    }
                }
            )
        }
    }
    
    /// Create length-prefixed frame for data
    private func createFrame(for data: Data) -> Data {
        var frame = Data()
        
        // Length prefix (4 bytes, big endian)
        let length = UInt32(data.count)
        frame.append(contentsOf: length.bigEndianBytes)
        
        // Data payload
        frame.append(data)
        
        return frame
    }
    
    /// Handle successful send
    private func handleSendSuccess(frameSize: Int) {
        stats.addBytesSent(frameSize)
        stats.incrementBatchesSent()
        stats.setLastSendTime(Date())
        lastSuccessTime = Date()
        
        SDKLogger.debug("Batch sent successfully: \(frameSize) bytes", category: .network)
    }
    
    /// Handle send error
    private func handleSendError(_ error: any Error) {
        stats.incrementSendFailures()
        stats.setLastFailureTime(Date())
        
        SDKLogger.error("Failed to send batch", error: error, category: .network)
        
        // Trigger reconnection for certain errors
        if let nwError = error as? NWError, shouldReconnectForError(nwError) {
            Task {
                await attemptReconnection()
            }
        }
    }
    
    /// Check if error should trigger reconnection
    private func shouldReconnectForError(_ error: NWError) -> Bool {
        switch error {
        case .posix(let posixError):
            return posixError == .ECONNRESET || posixError == .EPIPE || posixError == .ENOTCONN
        case .dns:
            return true
        default:
            return false
        }
    }
    
    // MARK: - Retry Logic
    
    /// Attempt reconnection with exponential backoff
    private func attemptReconnection() async {
        guard state != .connecting else { return }
        
        var attempt = 0
        let maxAttempts = retryConfig.maxAttempts
        
        while attempt < maxAttempts {
            attempt += 1
            
            let delay = retryConfig.calculateDelay(for: attempt)
            SDKLogger.info("Reconnection attempt \(attempt)/\(maxAttempts) in \(delay)s", category: .network)
            
            try? await Task.sleep(for: .seconds(delay))
            
            do {
                await disconnect()
                try await connect()
                SDKLogger.info("Reconnection successful after \(attempt) attempts", category: .network)
                return
            } catch {
                SDKLogger.warning("Reconnection attempt \(attempt) failed: \(error)", category: .network)
                
                if attempt == maxAttempts {
                    SDKLogger.error("All reconnection attempts failed", category: .network)
                    state = .failed(error)
                }
            }
        }
    }
    
    // MARK: - Health Check
    
    /// Perform comprehensive connection health check
    public func healthCheck() async -> Bool {
        guard isConnected, let connection = connection else { 
            return false 
        }
        
        // Check connection state
        guard connection.state == .ready else {
            SDKLogger.debug("Health check failed: connection not ready", category: .network)
            return false
        }
        
        // Check if we've had recent successful operations
        let timeSinceLastSuccess = Date().timeIntervalSince(lastSuccessTime)
        if timeSinceLastSuccess > 300 { // 5 minutes without success
            SDKLogger.warning("Health check: No successful operations in \(timeSinceLastSuccess)s", category: .network)
            return false
        }
        
        // Advanced health check: try to detect if connection is actually usable
        return await performAdvancedHealthCheck(connection: connection)
    }
    
    /// Perform advanced health check by testing connection usability
    private func performAdvancedHealthCheck(connection: NWConnection) async -> Bool {
        return await withCheckedContinuation { continuation in
            // Try to get connection metadata which requires active connection
            let metadata = connection.metadata(definition: NWProtocolTCP.definition)
            if metadata != nil {
                continuation.resume(returning: true)
            } else {
                SDKLogger.debug("Advanced health check failed: no TCP metadata", category: .network)
                continuation.resume(returning: false)
            }
        }
    }
    
    // MARK: - Statistics
    
    /// Get network statistics
    public var statistics: NetworkStats {
        return stats
    }
    
    // MARK: - Cleanup
    
    /// Close the network client
    public func close() async {
        SDKLogger.info("Closing network client", category: .network)
        
        // Cancel health check timer
        healthCheckTimer?.cancel()
        healthCheckTimer = nil
        
        // Close all pooled connections
        for pooledConnection in connectionPool {
            pooledConnection.cancel()
        }
        connectionPool.removeAll()
        
        await disconnect()
        pathMonitor?.cancel()
        pathMonitor = nil
        
        SDKLogger.info("Network client closed successfully", category: .network)
    }
}

// MARK: - Network Configuration

/// Configuration for network client
public struct NetworkConfig: Sendable {
    public let retryConfig: RetryConfig
    
    public static let `default` = NetworkConfig(
        retryConfig: RetryConfig.default
    )
    
    public static let maxBatchSize = 10 * 1024 * 1024 // 10MB
    
    public init(retryConfig: RetryConfig) {
        self.retryConfig = retryConfig
    }
}

// MARK: - Retry Configuration

/// Retry configuration for network operations
public struct RetryConfig: Sendable {
    public let maxAttempts: Int
    public let baseDelay: Double
    public let maxDelay: Double
    public let multiplier: Double
    
    public static let `default` = RetryConfig(
        maxAttempts: 5,
        baseDelay: 1.0,
        maxDelay: 30.0,
        multiplier: 1.5
    )
    
    public init(maxAttempts: Int, baseDelay: Double, maxDelay: Double, multiplier: Double) {
        self.maxAttempts = maxAttempts
        self.baseDelay = baseDelay
        self.maxDelay = maxDelay
        self.multiplier = multiplier
    }
    
    /// Calculate delay for retry attempt
    public func calculateDelay(for attempt: Int) -> Double {
        let delay = baseDelay * pow(multiplier, Double(attempt - 1))
        return min(delay, maxDelay)
    }
}

// MARK: - Network Statistics

/// Enhanced statistics for network operations
public struct NetworkStats: Sendable {
    public private(set) var connectionAttempts: Int = 0
    public private(set) var connectionFailures: Int = 0
    public private(set) var batchesSent: Int = 0
    public private(set) var bytesSent: Int = 0
    public private(set) var sendFailures: Int = 0
    public private(set) var lastConnectedTime: Date?
    public private(set) var lastSendTime: Date?
    public private(set) var lastFailureTime: Date?
    public private(set) var healthCheckCount: Int = 0
    public private(set) var healthCheckFailures: Int = 0
    public private(set) var reconnectionCount: Int = 0
    
    /// Connection success rate
    public var connectionSuccessRate: Double {
        guard connectionAttempts > 0 else { return 0.0 }
        return Double(connectionAttempts - connectionFailures) / Double(connectionAttempts)
    }
    
    /// Send success rate
    public var sendSuccessRate: Double {
        let totalSends = batchesSent + sendFailures
        guard totalSends > 0 else { return 0.0 }
        return Double(batchesSent) / Double(totalSends)
    }
    
    /// Health check success rate
    public var healthCheckSuccessRate: Double {
        guard healthCheckCount > 0 else { return 0.0 }
        return Double(healthCheckCount - healthCheckFailures) / Double(healthCheckCount)
    }
    
    fileprivate mutating func incrementConnectionAttempts() {
        connectionAttempts += 1
    }
    
    fileprivate mutating func incrementConnectionFailures() {
        connectionFailures += 1
    }
    
    fileprivate mutating func incrementBatchesSent() {
        batchesSent += 1
    }
    
    fileprivate mutating func addBytesSent(_ bytes: Int) {
        bytesSent += bytes
    }
    
    fileprivate mutating func incrementSendFailures() {
        sendFailures += 1
    }
    
    fileprivate mutating func setLastConnectedTime(_ time: Date) {
        lastConnectedTime = time
    }
    
    fileprivate mutating func setLastSendTime(_ time: Date) {
        lastSendTime = time
    }
    
    fileprivate mutating func setLastFailureTime(_ time: Date) {
        lastFailureTime = time
    }
    
    fileprivate mutating func incrementHealthCheckCount() {
        healthCheckCount += 1
    }
    
    fileprivate mutating func incrementHealthCheckFailures() {
        healthCheckFailures += 1
    }
    
    fileprivate mutating func incrementReconnectionCount() {
        reconnectionCount += 1
    }
    
    /// Connection uptime since last connection
    public var connectionUptime: TimeInterval? {
        guard let lastConnected = lastConnectedTime else { return nil }
        return Date().timeIntervalSince(lastConnected)
    }
    
    /// Average bytes per batch
    public var averageBatchSize: Double {
        guard batchesSent > 0 else { return 0.0 }
        return Double(bytesSent) / Double(batchesSent)
    }
    
    fileprivate mutating func recordHealthCheck(success: Bool) {
        healthCheckCount += 1
        if !success {
            healthCheckFailures += 1
        }
    }
    
    fileprivate mutating func recordReconnection() {
        reconnectionCount += 1
    }
}

// MARK: - Extensions

extension Data {
    /// Create Data from hex string
    init?(fromHexString hex: String) {
        let cleanHex = hex.replacingOccurrences(of: " ", with: "")
        guard cleanHex.count % 2 == 0 else { return nil }
        
        var data = Data()
        var index = cleanHex.startIndex
        
        while index < cleanHex.endIndex {
            let nextIndex = cleanHex.index(index, offsetBy: 2)
            let byteString = cleanHex[index..<nextIndex]
            
            guard let byte = UInt8(byteString, radix: 16) else { return nil }
            data.append(byte)
            
            index = nextIndex
        }
        
        self = data
    }
}

extension UInt32 {
    /// Convert to big endian bytes
    var bigEndianBytes: [UInt8] {
        return [
            UInt8((self >> 24) & 0xFF),
            UInt8((self >> 16) & 0xFF),
            UInt8((self >> 8) & 0xFF),
            UInt8(self & 0xFF)
        ]
    }
}