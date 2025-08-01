// main.swift
// Simple Logging Example - New UserCanal Interface
//
// Copyright © 2024 UserCanal. All rights reserved.
//

import Foundation
import UserCanal

@main
struct SimpleLogExample {
    static func main() async {
        print("🚀 UserCanal Swift SDK - Simple Logging (New Interface)")

        // Configure UserCanal once at startup - fire and forget
        UserCanal.shared.configureAsync(
            apiKey: "YOUR_API_KEY",
            logLevel: .debug
        )

        // Wait a moment for initialization
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        // Fire & forget logging - no await needed!

        // Super simple logging
        UserCanal.shared.logInfo("Application started")

        UserCanal.shared.logError("Login failed", data: [
            "user_id": "123",
            "reason": "invalid_password",
            "attempt_count": 3
        ])

        UserCanal.shared.logDebug("Processing request", data: [
            "request_id": "req_456",
            "duration": "45ms",
            "endpoint": "/api/users"
        ])

        // Logging with custom service names
        UserCanal.shared.logInfo("User authenticated successfully", service: "auth", data: [
            "user_id": "user_789",
            "login_method": "oauth",
            "session_id": "sess_abc123"
        ])

        UserCanal.shared.logWarning("Cache hit ratio low", service: "cache", data: [
            "hit_ratio": 0.65,
            "threshold": 0.80,
            "cache_size_mb": 256
        ])

        // Different log levels
        UserCanal.shared.log(.info, "Order processed", service: "orders", data: [
            "order_id": "order_999",
            "amount": 49.99,
            "processing_time_ms": 150
        ])

        UserCanal.shared.log(.error, "Payment gateway timeout", service: "payments", data: [
            "gateway": "stripe",
            "timeout_seconds": 30,
            "retry_count": 2
        ])

        // Ensure logs are sent before program exits
        print("Flushing logs...")
        try? await UserCanal.shared.flush()

        print("✅ Logs sent to UserCanal!")
        print("✨ Notice how clean and simple the logging interface is!")
        print("📊 Device context was sent automatically once per session")
    }
}
