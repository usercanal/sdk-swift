// main.swift
// Advanced Logging Example
//
// Copyright © 2024 UserCanal. All rights reserved.
//

import Foundation
import UserCanal

@main
struct AdvancedLogExample {
    static func main() async {
        print("🚀 UserCanal Swift SDK - Advanced Logging")
        
        do {
            // Initialize with advanced configuration for high-volume logging
            let config = UserCanalConfig.default
                .endpoint("collect.usercanal.com:50000")
                .batchSize(100)
                .flushInterval(5.0)
                .maxRetries(3)
                .debug(true)
            
            let client = try await UserCanalClient(apiKey: "YOUR_API_KEY", config: config)
            
            // Use all log levels for different scenarios
            
            // Critical system issues
            await client.logCritical(
                service: "api-gateway",
                "API rate limit exceeded for multiple clients",
                data: Properties([
                    "blocked_ips": ["192.168.1.1", "192.168.1.2"],
                    "rate_limit": 1000,
                    "current_rate": 1500
                ])
            )
            
            // Application errors
            await client.logError(
                service: "order-service",
                "Failed to process order",
                data: Properties([
                    "order_id": "ord_123",
                    "error": "inventory_insufficient",
                    "requested_quantity": 5,
                    "available_quantity": 2
                ])
            )
            
            // Warning conditions
            await client.logWarning(
                service: "cache-service",
                "Cache hit ratio below threshold",
                data: Properties([
                    "hit_ratio": 0.65,
                    "threshold": 0.80,
                    "cache_size_mb": 512
                ])
            )
            
            // Informational messages
            await client.logInfo(
                service: "analytics-service",
                "Daily report generation completed",
                data: Properties([
                    "report_date": "2024-01-15",
                    "processing_time_ms": 2500,
                    "records_processed": 1000000
                ])
            )
            
            // Debug information
            await client.logDebug(
                service: "auth-service",
                "JWT token validation successful",
                data: Properties([
                    "user_id": "user123",
                    "token_expiry": "2024-01-15T10:30:00Z",
                    "validation_time_ms": 15
                ])
            )
            
            // Create custom log entry with full control
            let customEntry = LogEntry(
                eventType: .log,
                contextID: 12345,
                level: .info,
                timestamp: Date(),
                source: "recommendation-engine",
                service: "personalization-service",
                message: "Generated personalized recommendations",
                data: Properties([
                    "user_id": "user123",
                    "recommendations_count": 10,
                    "algorithm_version": "v2.1",
                    "processing_time_ms": 45,
                    "cache_hit": true,
                    "model_confidence": 0.87
                ])
            )
            
            await client.log(entry: customEntry)
            
            // Batch multiple related log entries
            let batchEntries = [
                LogEntry(
                    level: .info,
                    service: "api-service",
                    message: "Request received",
                    data: Properties([
                        "request_id": "req_123",
                        "endpoint": "/api/users",
                        "method": "GET"
                    ])
                ),
                LogEntry(
                    level: .debug,
                    service: "database-service",
                    message: "Database query executed",
                    data: Properties([
                        "request_id": "req_123",
                        "query_type": "SELECT",
                        "execution_time_ms": 25,
                        "rows_returned": 1
                    ])
                ),
                LogEntry(
                    level: .info,
                    service: "api-service",
                    message: "Response sent",
                    data: Properties([
                        "request_id": "req_123",
                        "status_code": 200,
                        "response_time_ms": 45
                    ])
                )
            ]
            
            await client.logBatch(entries: batchEntries)
            
            // Flush and ensure all logs are sent
            try await client.flush()
            
            // Print client stats
            let stats = await client.statistics
            print("Client Stats: Events tracked: \(stats.eventsTracked), Logs tracked: \(stats.logsTracked)")
            
            // Close the client
            try await client.close()
            
            print("✅ Advanced logs sent to UserCanal!")
            
        } catch {
            print("❌ Error: \(error)")
        }
    }
}