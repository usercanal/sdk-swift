// Configuration.swift
// UserCanal Swift SDK
//
// Copyright © 2024 UserCanal. All rights reserved.
//

import Foundation

// MARK: - Configuration

/// Advanced configuration for the UserCanal client with runtime updates and environment support
public struct UserCanalConfig: Sendable {
    
    // MARK: - Network Configuration
    
    /// The endpoint URL for the UserCanal collector
    public let endpoint: String
    
    /// Batch size for events and logs
    public let batchSize: Int
    
    /// Maximum time interval between batch flushes
    public let flushInterval: Duration
    
    /// Maximum number of retry attempts for failed requests
    public let maxRetries: Int
    
    /// Timeout for network operations
    public let networkTimeout: Duration
    
    /// Timeout for graceful client shutdown
    public let closeTimeout: Duration
    
    // MARK: - Behavior Configuration
    
    /// Whether to enable debug logging
    public let enableDebugLogging: Bool
    
    /// Whether to collect device context automatically
    public let collectDeviceContext: Bool
    
    /// Whether to persist events locally when offline
    public let enableOfflineStorage: Bool
    
    /// Maximum number of events to store offline
    public let maxOfflineEvents: Int
    
    /// Whether to enable automatic error reporting
    public let enableErrorReporting: Bool
    
    /// Advanced network configuration
    public let networkConfig: NetworkConfiguration
    
    /// Performance optimization settings
    public let performanceConfig: PerformanceConfiguration
    
    /// Security settings
    public let securityConfig: SecurityConfiguration
    
    // MARK: - Initialization
    
    /// Create a new configuration with custom values
    public init(
        endpoint: String = Defaults.endpoint,
        batchSize: Int = Defaults.batchSize,
        flushInterval: Duration = Defaults.flushInterval,
        maxRetries: Int = Defaults.maxRetries,
        networkTimeout: Duration = Defaults.networkTimeout,
        closeTimeout: Duration = Defaults.closeTimeout,
        enableDebugLogging: Bool = Defaults.enableDebugLogging,
        collectDeviceContext: Bool = Defaults.collectDeviceContext,
        enableOfflineStorage: Bool = Defaults.enableOfflineStorage,
        maxOfflineEvents: Int = Defaults.maxOfflineEvents,
        enableErrorReporting: Bool = Defaults.enableErrorReporting,
        networkConfig: NetworkConfiguration = .default,
        performanceConfig: PerformanceConfiguration = .default,
        securityConfig: SecurityConfiguration = .standard
    ) throws {
        // Validate configuration parameters
        try Self.validate(
            endpoint: endpoint,
            batchSize: batchSize,
            flushInterval: flushInterval,
            maxRetries: maxRetries,
            networkTimeout: networkTimeout,
            closeTimeout: closeTimeout,
            maxOfflineEvents: maxOfflineEvents
        )
        
        self.endpoint = endpoint
        self.batchSize = batchSize
        self.flushInterval = flushInterval
        self.maxRetries = maxRetries
        self.networkTimeout = networkTimeout
        self.closeTimeout = closeTimeout
        self.enableDebugLogging = enableDebugLogging
        self.collectDeviceContext = collectDeviceContext
        self.enableOfflineStorage = enableOfflineStorage
        self.maxOfflineEvents = maxOfflineEvents
        self.enableErrorReporting = enableErrorReporting
        self.networkConfig = networkConfig
        self.performanceConfig = performanceConfig
        self.securityConfig = securityConfig
    }
    
    /// Create configuration with default values
    public static let `default` = try! UserCanalConfig()
    
    /// Create configuration optimized for production
    public static let production = try! UserCanalConfig(
        batchSize: 200,
        flushInterval: .seconds(30),
        enableDebugLogging: false,
        networkConfig: .production,
        performanceConfig: .optimized,
        securityConfig: .development
    )
    
    /// Create configuration optimized for development
    public static let development = try! UserCanalConfig(
        endpoint: "localhost:50000",
        batchSize: 10,
        flushInterval: .seconds(2),
        enableDebugLogging: true,
        networkConfig: .development,
        performanceConfig: .debug,
        securityConfig: .development
    )
}

// MARK: - Configuration Validation

extension UserCanalConfig {
    
    /// Validation errors for configuration
    public enum ValidationError: Error, Sendable {
        case invalidEndpoint(String)
        case invalidBatchSize(Int)
        case invalidFlushInterval(Duration)
        case invalidMaxRetries(Int)
        case invalidNetworkTimeout(Duration)
        case invalidCloseTimeout(Duration)
        case invalidMaxOfflineEvents(Int)
    }
    
    /// Validate configuration parameters
    private static func validate(
        endpoint: String,
        batchSize: Int,
        flushInterval: Duration,
        maxRetries: Int,
        networkTimeout: Duration,
        closeTimeout: Duration,
        maxOfflineEvents: Int
    ) throws {
        // Validate endpoint
        guard !endpoint.isEmpty else {
            throw ValidationError.invalidEndpoint("Endpoint cannot be empty")
        }
        
        // Validate batch size
        guard batchSize > 0 && batchSize <= 10000 else {
            throw ValidationError.invalidBatchSize(batchSize)
        }
        
        // Validate flush interval
        guard flushInterval >= .milliseconds(100) && flushInterval <= .seconds(300) else {
            throw ValidationError.invalidFlushInterval(flushInterval)
        }
        
        // Validate max retries
        guard maxRetries >= 0 && maxRetries <= 10 else {
            throw ValidationError.invalidMaxRetries(maxRetries)
        }
        
        // Validate network timeout
        guard networkTimeout >= .seconds(1) && networkTimeout <= .seconds(60) else {
            throw ValidationError.invalidNetworkTimeout(networkTimeout)
        }
        
        // Validate close timeout
        guard closeTimeout >= .seconds(1) && closeTimeout <= .seconds(30) else {
            throw ValidationError.invalidCloseTimeout(closeTimeout)
        }
        
        // Validate max offline events
        guard maxOfflineEvents >= 0 && maxOfflineEvents <= 100000 else {
            throw ValidationError.invalidMaxOfflineEvents(maxOfflineEvents)
        }
    }
}

// MARK: - Configuration Defaults

extension UserCanalConfig {
    
    /// Default configuration values
    public enum Defaults {
        /// Default production endpoint
        public static let endpoint = "collect.usercanal.com:50000"
        
        /// Default batch size
        public static let batchSize = 100
        
        /// Default flush interval
        public static let flushInterval: Duration = .seconds(10)
        
        /// Default maximum retries
        public static let maxRetries = 3
        
        /// Default network timeout
        public static let networkTimeout: Duration = .seconds(30)
        
        /// Default close timeout
        public static let closeTimeout: Duration = .seconds(5)
        
        /// Default debug logging state
        public static let enableDebugLogging = false
        
        /// Default device context collection
        public static let collectDeviceContext = true
        
        /// Default offline storage
        public static let enableOfflineStorage = true
        
        /// Default maximum offline events
        public static let maxOfflineEvents = 10000
        
        /// Default error reporting
        public static let enableErrorReporting = true
        
        /// Default network configuration
        public static let networkConfig = NetworkConfiguration.default
        
        /// Default performance configuration
        public static let performanceConfig = PerformanceConfiguration.default
        
        /// Default security configuration
        public static let securityConfig = SecurityConfiguration.standard
    }
}

// MARK: - Configuration Builder

/// Builder pattern for creating configurations
public struct UserCanalConfigBuilder: Sendable {
    private var endpoint = UserCanalConfig.Defaults.endpoint
    private var batchSize = UserCanalConfig.Defaults.batchSize
    private var flushInterval = UserCanalConfig.Defaults.flushInterval
    private var maxRetries = UserCanalConfig.Defaults.maxRetries
    private var networkTimeout = UserCanalConfig.Defaults.networkTimeout
    private var closeTimeout = UserCanalConfig.Defaults.closeTimeout
    private var enableDebugLogging = UserCanalConfig.Defaults.enableDebugLogging
    private var collectDeviceContext = UserCanalConfig.Defaults.collectDeviceContext
    private var enableOfflineStorage = UserCanalConfig.Defaults.enableOfflineStorage
    private var maxOfflineEvents = UserCanalConfig.Defaults.maxOfflineEvents
    private var enableErrorReporting = UserCanalConfig.Defaults.enableErrorReporting
    private var networkConfig = UserCanalConfig.Defaults.networkConfig
    private var performanceConfig = UserCanalConfig.Defaults.performanceConfig
    private var securityConfig = UserCanalConfig.Defaults.securityConfig
    
    public init() {}
    
    public func endpoint(_ value: String) -> Self {
        var copy = self
        copy.endpoint = value
        return copy
    }
    
    public func batchSize(_ value: Int) -> Self {
        var copy = self
        copy.batchSize = value
        return copy
    }
    
    public func flushInterval(_ value: Duration) -> Self {
        var copy = self
        copy.flushInterval = value
        return copy
    }
    
    public func maxRetries(_ value: Int) -> Self {
        var copy = self
        copy.maxRetries = value
        return copy
    }
    
    public func networkTimeout(_ value: Duration) -> Self {
        var copy = self
        copy.networkTimeout = value
        return copy
    }
    
    public func closeTimeout(_ value: Duration) -> Self {
        var copy = self
        copy.closeTimeout = value
        return copy
    }
    
    public func enableDebugLogging(_ value: Bool = true) -> Self {
        var copy = self
        copy.enableDebugLogging = value
        return copy
    }
    
    public func collectDeviceContext(_ value: Bool = true) -> Self {
        var copy = self
        copy.collectDeviceContext = value
        return copy
    }
    
    public func enableOfflineStorage(_ value: Bool = true) -> Self {
        var copy = self
        copy.enableOfflineStorage = value
        return copy
    }
    
    public func maxOfflineEvents(_ value: Int) -> Self {
        var copy = self
        copy.maxOfflineEvents = value
        return copy
    }
    
    public func enableErrorReporting(_ value: Bool = true) -> Self {
        var copy = self
        copy.enableErrorReporting = value
        return copy
    }
    
    public func networkConfig(_ value: NetworkConfiguration) -> Self {
        var copy = self
        copy.networkConfig = value
        return copy
    }
    
    public func performanceConfig(_ value: PerformanceConfiguration) -> Self {
        var copy = self
        copy.performanceConfig = value
        return copy
    }
    
    public func securityConfig(_ value: SecurityConfiguration) -> Self {
        var copy = self
        copy.securityConfig = value
        return copy
    }
    
    public func build() throws -> UserCanalConfig {
        try UserCanalConfig(
            endpoint: endpoint,
            batchSize: batchSize,
            flushInterval: flushInterval,
            maxRetries: maxRetries,
            networkTimeout: networkTimeout,
            closeTimeout: closeTimeout,
            enableDebugLogging: enableDebugLogging,
            collectDeviceContext: collectDeviceContext,
            enableOfflineStorage: enableOfflineStorage,
            maxOfflineEvents: maxOfflineEvents,
            enableErrorReporting: enableErrorReporting,
            networkConfig: networkConfig,
            performanceConfig: performanceConfig,
            securityConfig: securityConfig
        )
    }
}

// MARK: - Environment Configuration

extension UserCanalConfig {
    
    /// Create configuration from environment variables
    public static func fromEnvironment() throws -> UserCanalConfig {
        let builder = UserCanalConfigBuilder()
        
        // Read from environment variables if available
        if let endpoint = ProcessInfo.processInfo.environment["USERCANAL_ENDPOINT"] {
            return try builder.endpoint(endpoint).build()
        }
        
        if let batchSizeString = ProcessInfo.processInfo.environment["USERCANAL_BATCH_SIZE"],
           let batchSize = Int(batchSizeString) {
            return try builder.batchSize(batchSize).build()
        }
        
        if let debugString = ProcessInfo.processInfo.environment["USERCANAL_DEBUG"],
           let debug = Bool(debugString) {
            return try builder.enableDebugLogging(debug).build()
        }
        
        // Return default configuration if no environment variables
        return try builder.build()
    }
}

// MARK: - CustomStringConvertible

extension UserCanalConfig: CustomStringConvertible {
    public var description: String {
        """
        UserCanalConfig(
          endpoint: \(endpoint)
          batchSize: \(batchSize)
          flushInterval: \(flushInterval)
          maxRetries: \(maxRetries)
          networkTimeout: \(networkTimeout)
          closeTimeout: \(closeTimeout)
          enableDebugLogging: \(enableDebugLogging)
          collectDeviceContext: \(collectDeviceContext)
          enableOfflineStorage: \(enableOfflineStorage)
          maxOfflineEvents: \(maxOfflineEvents)
          enableErrorReporting: \(enableErrorReporting)
          networkConfig: \(networkConfig)
          performanceConfig: \(performanceConfig)
          securityConfig: \(securityConfig)
        )
        """
    }
}

extension UserCanalConfig.ValidationError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidEndpoint(let endpoint):
            return "Invalid endpoint: \(endpoint)"
        case .invalidBatchSize(let size):
            return "Invalid batch size: \(size). Must be between 1 and 10000"
        case .invalidFlushInterval(let interval):
            return "Invalid flush interval: \(interval). Must be between 100ms and 5 minutes"
        case .invalidMaxRetries(let retries):
            return "Invalid max retries: \(retries). Must be between 0 and 10"
        case .invalidNetworkTimeout(let timeout):
            return "Invalid network timeout: \(timeout). Must be between 1 and 60 seconds"
        case .invalidCloseTimeout(let timeout):
            return "Invalid close timeout: \(timeout). Must be between 1 and 30 seconds"
        case .invalidMaxOfflineEvents(let count):
            return "Invalid max offline events: \(count). Must be between 0 and 100000"
        }
    }
}

// MARK: - Advanced Configuration Types

/// Network-specific configuration
public struct NetworkConfiguration: Sendable {
    public let connectionPoolSize: Int
    public let keepAliveInterval: Duration
    public let dnsRefreshInterval: Duration
    public let enableCompression: Bool
    public let compressionThreshold: Int
    public let enableMultiplexing: Bool
    
    public init(
        connectionPoolSize: Int = 3,
        keepAliveInterval: Duration = .seconds(30),
        dnsRefreshInterval: Duration = .seconds(300),
        enableCompression: Bool = false,
        compressionThreshold: Int = 1024,
        enableMultiplexing: Bool = false
    ) {
        self.connectionPoolSize = connectionPoolSize
        self.keepAliveInterval = keepAliveInterval
        self.dnsRefreshInterval = dnsRefreshInterval
        self.enableCompression = enableCompression
        self.compressionThreshold = compressionThreshold
        self.enableMultiplexing = enableMultiplexing
    }
    
    public static let `default` = NetworkConfiguration()
    
    public static let production = NetworkConfiguration(
        connectionPoolSize: 5,
        enableCompression: true,
        compressionThreshold: 512
    )
    
    public static let development = NetworkConfiguration(
        connectionPoolSize: 1,
        keepAliveInterval: .seconds(10),
        enableCompression: false
    )
}

/// Performance optimization configuration
public struct PerformanceConfiguration: Sendable {
    public let enableMemoryOptimization: Bool
    public let enableBatteryOptimization: Bool
    public let maxMemoryUsage: Int // in MB
    public let backgroundProcessingMode: BackgroundMode
    public let enableMetrics: Bool
    
    public init(
        enableMemoryOptimization: Bool = true,
        enableBatteryOptimization: Bool = true,
        maxMemoryUsage: Int = 50,
        backgroundProcessingMode: BackgroundMode = .efficient,
        enableMetrics: Bool = false
    ) {
        self.enableMemoryOptimization = enableMemoryOptimization
        self.enableBatteryOptimization = enableBatteryOptimization
        self.maxMemoryUsage = maxMemoryUsage
        self.backgroundProcessingMode = backgroundProcessingMode
        self.enableMetrics = enableMetrics
    }
    
    public static let `default` = PerformanceConfiguration()
    
    public static let optimized = PerformanceConfiguration(
        enableMemoryOptimization: true,
        enableBatteryOptimization: true,
        maxMemoryUsage: 30,
        backgroundProcessingMode: .minimal,
        enableMetrics: false
    )
    
    public static let debug = PerformanceConfiguration(
        enableMemoryOptimization: false,
        enableBatteryOptimization: false,
        maxMemoryUsage: 100,
        backgroundProcessingMode: .full,
        enableMetrics: true
    )
    
    public enum BackgroundMode: String, Sendable, CaseIterable {
        case minimal = "minimal"
        case efficient = "efficient"
        case full = "full"
    }
}

/// Security configuration for client-side operations
public struct SecurityConfiguration: Sendable {
    public let secureAPIKeyStorage: Bool
    
    public init(
        secureAPIKeyStorage: Bool = true
    ) {
        self.secureAPIKeyStorage = secureAPIKeyStorage
    }
    
    public static let standard = SecurityConfiguration()
    
    public static let development = SecurityConfiguration(
        secureAPIKeyStorage: false
    )
}

// MARK: - Runtime Configuration Manager

/// Manager for runtime configuration updates
public actor ConfigurationManager {
    private var currentConfig: UserCanalConfig
    private var updateHandlers: [String: (UserCanalConfig) async -> Void] = [:]
    
    public init(config: UserCanalConfig) {
        self.currentConfig = config
    }
    
    /// Update configuration at runtime
    public func updateConfiguration(_ newConfig: UserCanalConfig) async {
        let _ = currentConfig
        currentConfig = newConfig
        
        SDKLogger.info("Configuration updated", category: .config)
        
        // Notify all handlers
        for (_, handler) in updateHandlers {
            await handler(newConfig)
        }
    }
    
    /// Register for configuration updates
    public func onConfigurationUpdate(
        id: String,
        handler: @escaping (UserCanalConfig) async -> Void
    ) {
        updateHandlers[id] = handler
    }
    
    /// Unregister from configuration updates
    public func removeConfigurationHandler(id: String) {
        updateHandlers.removeValue(forKey: id)
    }
    
    /// Get current configuration
    public var configuration: UserCanalConfig {
        return currentConfig
    }
    
    /// Load configuration from remote source
    public func loadRemoteConfiguration(from url: URL) async throws {
        // This would implement remote configuration loading
        SDKLogger.info("Loading remote configuration from: \(url)", category: .config)
        
        // For now, this is a placeholder
        throw UserCanalError.invalidConfiguration("Remote configuration not implemented")
    }
    
    /// Validate configuration compatibility
    public func validateConfiguration(_ config: UserCanalConfig) throws -> Bool {
        // Validate network settings
        guard config.networkConfig.connectionPoolSize > 0 else {
            throw UserCanalError.invalidConfiguration("Connection pool size must be positive")
        }
        
        // Validate performance settings
        guard config.performanceConfig.maxMemoryUsage > 0 else {
            throw UserCanalError.invalidConfiguration("Max memory usage must be positive")
        }
        
        // Validate security settings
        if config.securityConfig.secureAPIKeyStorage {
            SDKLogger.info("Secure API key storage enabled", category: .config)
        }
        
        return true
    }
}

// MARK: - Configuration Extensions

extension NetworkConfiguration: CustomStringConvertible {
    public var description: String {
        return "NetworkConfiguration(poolSize: \(connectionPoolSize), compression: \(enableCompression))"
    }
}

extension PerformanceConfiguration: CustomStringConvertible {
    public var description: String {
        return "PerformanceConfiguration(memory: \(maxMemoryUsage)MB, mode: \(backgroundProcessingMode))"
    }
}

extension SecurityConfiguration: CustomStringConvertible {
    public var description: String {
        return "SecurityConfiguration(secureStorage: \(secureAPIKeyStorage))"
    }
}