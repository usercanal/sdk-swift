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

        SDKLogger.trace("NetworkClient initialized for endpoint: \(endpoint)", category: .network)
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

        SDKLogger.trace("Connecting to \(endpoint)", category: .network)

        return try await withCheckedThrowingContinuation { continuation in
            let connection = NWConnection(to: endpoint, using: parameters)
            self.connection = connection

            // Use a single atomic reference to track resume state
            let resumeWrapper = ResumeWrapper(continuation: continuation)

            connection.stateUpdateHandler = { [weak self] newState in
                Task { [weak self] in
                    switch newState {
                    case .ready:
                        await self?.handleStateChange(newState)
                        resumeWrapper.resumeOnce()
                    case .failed(let error):
                        await self?.handleStateChange(newState)
                        resumeWrapper.resumeOnceWithError(UserCanalError.connectionFailed(error.localizedDescription))
                    case .cancelled:
                        await self?.handleStateChange(newState)
                        resumeWrapper.resumeOnceWithError(UserCanalError.connectionFailed("Connection cancelled"))
                    default:
                        await self?.handleStateChange(newState)
                    }
                }
            }

            connection.start(queue: queue)
        }
    }

    /// Handle connection state changes
    private func handleStateChange(_ newState: NWConnection.State) {
        switch newState {
        case .ready:
            state = .connected
            stats.setLastConnectedTime(Date())
            SDKLogger.trace("Connection established", category: .network)
        case .failed(let error):
            state = .failed(error)
            stats.incrementConnectionFailures()
            SDKLogger.error("Connection failed", error: error, category: .network)
        case .cancelled:
            state = .disconnected
            // Don't log cancellation during normal disconnect - it's confusing
        case .waiting(let error):
            SDKLogger.warning("Connection failed: \(error)", category: .network)
        case .preparing:
            break // Too verbose for debug
        case .setup:
            break // Too verbose for debug
        @unknown default:
            SDKLogger.warning("Unknown connection state: \(newState)", category: .network)
        }
    }

    /// Disconnect from the server
    public func disconnect() async {
        guard let connection = connection else { return }

        // Disconnect silently - not needed for debug

        connection.cancel()
        self.connection = nil
        state = .disconnected
    }

    /// Check if connected
    public var isConnected: Bool {
        return state == .connected && connection?.state == .ready
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

        SDKLogger.trace("Sending batch: \(data.count) bytes", category: .network)
        print("🔍 NetworkClient: About to send \(data.count) bytes to \(endpoint)")
        print("🔍 NetworkClient: Connection state: \(connection.state)")

        // Dump complete binary data for debugging
        print("📊 SWIFT SDK BINARY DUMP - COMPLETE FRAME:")
        print("📊 Frame size: \(frame.count) bytes")
        print("📊 Length prefix (first 4 bytes): \(frame.prefix(4).map { String(format: "%02x", $0) }.joined(separator: " "))")
        print("📊 Payload size: \(data.count) bytes")

        // Dump first 64 bytes of frame in chunks of 16
        let dumpSize = min(64, frame.count)
        for i in stride(from: 0, to: dumpSize, by: 16) {
            let end = min(i + 16, dumpSize)
            let chunk = frame[i..<end]
            let hex = chunk.map { String(format: "%02x", $0) }.joined(separator: " ")
            let ascii = chunk.map { $0 >= 32 && $0 <= 126 ? String(Character(UnicodeScalar($0))) : "." }.joined()
            print("📊 \(String(format: "%04x", i)): \(hex.padding(toLength: 47, withPad: " ", startingAt: 0)) |\(ascii)|")
        }

        if frame.count > 64 {
            print("📊 ... (\(frame.count - 64) more bytes)")
        }

        print("🔍 NetworkClient: First 16 bytes: \(data.prefix(16).map { String(format: "%02x", $0) }.joined(separator: " "))")

        return try await withCheckedThrowingContinuation { continuation in
            connection.send(
                content: frame,
                completion: .contentProcessed { [weak self] error in
                    if let error = error {
                        print("❌ NetworkClient: Send failed with error: \(error)")
                    } else {
                        print("✅ NetworkClient: Send completed successfully")
                    }
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

        print("🔍 NetworkClient: Created frame: \(frame.count) bytes (4-byte prefix + \(data.count) payload)")
        print("🔍 NetworkClient: Length prefix: \(String(format: "%08x", length)) (\(length) bytes)")

        return frame
    }

    /// Handle successful send
    private func handleSendSuccess(frameSize: Int) {
        stats.addBytesSent(frameSize)
        stats.incrementBatchesSent()
        stats.setLastSendTime(Date())
        lastSuccessTime = Date()

        print("📡 NetworkClient: Batch transmission confirmed: \(frameSize) bytes")
        // Batch sent details are logged by BatchManager with item counts
    }

    /// Handle send error
    private func handleSendError(_ error: any Error) async {
        stats.incrementSendFailures()
        stats.setLastFailureTime(Date())

        SDKLogger.error("Failed to send batch", error: error, category: .network)

        // Disconnect on error to ensure clean state for next attempt
        await disconnect()
        SDKLogger.debug("Disconnected after send failure", category: .network)
    }

    /// Connect only when needed for sending data
    public func connectIfNeeded() async throws {
        guard state != .connected else {
            SDKLogger.debug("Connection already established, reusing", category: .network)
            return
        }

        try await connect()
    }

    // MARK: - Statistics

    /// Get network statistics
    public var statistics: NetworkStats {
        return stats
    }

    // MARK: - Cleanup

    /// Close the network client
    public func close() async {
        SDKLogger.debug("Closing network client", category: .network)

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


}

// MARK: - Helper Classes

/// Thread-safe wrapper for continuation resume operations
private final class ResumeWrapper: @unchecked Sendable {
    private let continuation: CheckedContinuation<Void, any Error>
    private var hasResumed = false
    private let lock = NSLock()

    init(continuation: CheckedContinuation<Void, any Error>) {
        self.continuation = continuation
    }

    func resumeOnce() {
        lock.lock()
        defer { lock.unlock() }

        if !hasResumed {
            hasResumed = true
            continuation.resume()
        }
    }

    func resumeOnceWithError(_ error: any Error) {
        lock.lock()
        defer { lock.unlock() }

        if !hasResumed {
            hasResumed = true
            continuation.resume(throwing: error)
        }
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
