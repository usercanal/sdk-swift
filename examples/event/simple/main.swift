// main.swift
// Simple Event Tracking Example - New UserCanal Interface
//
// Copyright © 2024 UserCanal. All rights reserved.
//

import Foundation
import UserCanal

// Add debug logging to see what's actually being sent
func debugLog(_ message: String) {
    print("🔍 DEBUG: \(message)")
}

@main
struct SimpleEventExample {
    static func main() async {
        print("🚀 UserCanal Swift SDK - Simple Event Tracking (New Interface)")
        debugLog("Starting with API key: 000102030405060708090a0b0c0d0e0f")
        debugLog("Endpoint: localhost:50000")

        // Configure UserCanal once at startup
        UserCanal.shared.configure(
            apiKey: "000102030405060708090a0b0c0d0e0f",
            endpoint: "localhost:50000",
            batchSize: 1, // Force immediate sending for debug
            flushInterval: 1.0, // Short interval for debug
            onError: { error in
                print("🚨 Analytics error: \(error)")
                debugLog("Error details: \(String(describing: error))")
            }
        )
debugLog("Configuration complete, SDK initialized")

// Wait longer for initialization to ensure connection
try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
debugLog("Initialization wait complete")

// Fire & forget event tracking - no await needed!

// Track a signup event using predefined constant
debugLog("About to track userSignedUp event...")
UserCanal.shared.track(.userSignedUp, properties: [
    "signup_method": "email",
    "referral_source": "google",
    "debug_test": true,
    "timestamp": Date().timeIntervalSince1970
])
debugLog("userSignedUp event queued")

// Wait to see if batch sends
try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

        // Track a custom event using string directly
        debugLog("About to track video.viewed event...")
        UserCanal.shared.track("video.viewed", properties: [
            "video_id": "vid_123",
            "duration": 120,
            "quality": "hd",
            "platform": "ios",
            "debug_test": true
        ])
        debugLog("video.viewed event queued")

        // Wait to see if batch sends
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

        // Track another predefined event
        debugLog("About to track featureUsed event...")
        UserCanal.shared.track(.featureUsed, properties: [
            "feature_name": "dashboard",
            "section": "analytics",
            "debug_test": true
        ])
        debugLog("featureUsed event queued")

        // Wait to see if batch sends
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

        // User registers - identify them (merges with anonymous events)
        debugLog("About to identify user...")
        UserCanal.shared.identify("user_123", traits: [
            "email": "user@example.com",
            "plan": "free",
            "signup_date": Date(),
            "debug_test": true
        ])
        debugLog("User identification queued")

        // Wait to see if batch sends
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

        // Track revenue event
        debugLog("About to track revenue event...")
        UserCanal.shared.eventRevenue(
            amount: 9.99,
            currency: .usd,
            orderID: "order_456",
            properties: [
                "product": "premium_plan",
                "discount": "first_month_50",
                "debug_test": true
            ]
        )
        debugLog("Revenue event queued")

        // Wait to see if batch sends
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

        // Simple logging
        debugLog("About to send log messages...")
        UserCanal.shared.logInfo("User completed onboarding flow", data: [
            "debug_test": true
        ])

        UserCanal.shared.logError("Payment processing failed", data: [
            "error_code": "card_declined",
            "retry_count": 1,
            "debug_test": true
        ])
        debugLog("Log messages queued")

        // Wait to see if logs send
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

        // Ensure events are sent before program exits
        debugLog("Starting manual flush...")
        print("🚀 Flushing events to localhost:50000...")
        do {
            try await UserCanal.shared.flush()
            debugLog("Manual flush completed successfully")
            print("✅ Manual flush completed!")
        } catch {
            print("❌ Manual flush failed: \(error)")
            debugLog("Flush error: \(String(describing: error))")
        }

        // Wait extra time to ensure TCP transmission completes
        debugLog("Waiting 3 seconds for TCP transmission to complete...")
        try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds

        print("✅ Events sent to UserCanal!")
        print("✨ Notice how clean and simple the new interface is!")
        print("📊 Device context was sent automatically once per session")
        print("🔄 Anonymous events were automatically merged with identified user")
        debugLog("Program completed - check collector logs for data!")
    }
}
