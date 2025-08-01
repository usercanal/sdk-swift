// main.swift
// Advanced Logging Example - Demonstrating Log Severities
//
// Copyright © 2024 UserCanal. All rights reserved.

import Foundation
import UserCanal

@main
struct AdvancedLogExample {
    static func main() async {
        print("🚀 UserCanal Swift SDK - Advanced Logging (Log Severities)")

        // Configure UserCanal with debug logging enabled - fire and forget
        UserCanal.shared.configureAsync(
            apiKey: "YOUR_API_KEY",
            endpoint: "collect.usercanal.com:50000",
            batchSize: 50,
            flushInterval: 10,
            logLevel: .debug
        )

        print("📊 Demonstrating different log severities...")

        // CRITICAL - System is unusable
        UserCanal.shared.log(.critical, "Database cluster down - all services affected", service: "infrastructure", data: [
            "affected_services": ["api", "web", "mobile"],
            "estimated_downtime": "30min",
            "incident_id": "INC-001"
        ])

        // ERROR - Error conditions that need immediate attention
        UserCanal.shared.logError("Payment processing failed", service: "payments", data: [
            "error_code": "CARD_DECLINED",
            "transaction_id": "txn_123456",
            "user_id": "user_789",
            "amount": 99.99,
            "retry_count": 3
        ])

        // WARNING - Warning conditions that should be monitored
        UserCanal.shared.logWarning("High memory usage detected", service: "api-server", data: [
            "memory_usage_percent": 85,
            "threshold": 80,
            "server_id": "api-01",
            "uptime_hours": 72
        ])

        // INFO - Informational messages for general system state
        UserCanal.shared.logInfo("User session started", service: "auth", data: [
            "user_id": "user_456",
            "session_id": "sess_abc123",
            "login_method": "oauth_google",
            "ip_address": "192.168.1.100"
        ])

        // DEBUG - Detailed information for debugging
        UserCanal.shared.logDebug("Cache miss - fetching from database", service: "cache", data: [
            "cache_key": "user_profile_456",
            "ttl_remaining": 0,
            "db_query_time_ms": 45,
            "cache_hit_ratio": 0.78
        ])

        // Demonstrate different service categories
        print("\n🔧 Logging from different services...")

        // Database service logs
        UserCanal.shared.logInfo("Query executed successfully", service: "database", data: [
            "query_type": "SELECT",
            "execution_time_ms": 12,
            "rows_returned": 150,
            "table": "user_profiles"
        ])

        // API service logs
        UserCanal.shared.logInfo("API request processed", service: "api", data: [
            "endpoint": "/api/v1/users",
            "method": "GET",
            "status_code": 200,
            "response_time_ms": 85,
            "user_agent": "iOS/15.0"
        ])

        // Background job logs
        UserCanal.shared.logInfo("Background job completed", service: "jobs", data: [
            "job_type": "email_newsletter",
            "recipients_count": 10000,
            "success_count": 9987,
            "failed_count": 13,
            "duration_seconds": 45
        ])

        // Security service logs
        UserCanal.shared.logWarning("Multiple failed login attempts", service: "security", data: [
            "ip_address": "203.0.113.42",
            "attempt_count": 5,
            "time_window_minutes": 10,
            "blocked": true
        ])

        // Performance monitoring
        UserCanal.shared.logInfo("Performance metrics", service: "monitoring", data: [
            "avg_response_time_ms": 120,
            "requests_per_minute": 1500,
            "error_rate_percent": 0.02,
            "active_connections": 245
        ])

        print("\n📈 Logging business metrics...")

        // Business analytics logs
        UserCanal.shared.logInfo("Daily metrics calculated", service: "analytics", data: [
            "date": "2024-07-29",
            "daily_active_users": 15000,
            "new_signups": 250,
            "revenue_usd": 12500.75,
            "conversion_rate": 0.035
        ])

        // Feature usage tracking
        UserCanal.shared.logDebug("Feature flag evaluated", service: "features", data: [
            "flag_name": "new_dashboard",
            "user_id": "user_789",
            "result": true,
            "experiment_group": "treatment_a"
        ])

        print("\n🔄 Sending all logs to UserCanal...")

        // Flush all logs before exit
        try? await UserCanal.shared.flush()

        print("✅ Advanced logging complete!")
        print("📋 Demonstrated log severities:")
        print("   🔴 CRITICAL - System unusable")
        print("   🟠 ERROR - Immediate attention needed")
        print("   🟡 WARNING - Should be monitored")
        print("   🔵 INFO - General system state")
        print("   🟣 DEBUG - Detailed debugging info")
        print("\n🏷️  Organized by service categories for better filtering")
    }
}
