// main.swift
// Simple Event Tracking Example - New UserCanal Interface
//
// Copyright © 2024 UserCanal. All rights reserved.
//

import Foundation
import UserCanal

@main
struct SimpleEventExample {
    static func main() async {
        print("🚀 UserCanal Swift SDK - Simple Event Tracking")

        // Configure UserCanal - fire and forget
        UserCanal.shared.configureAsync(
            apiKey: "000102030405060708090a0b0c0d0e0f",
            endpoint: "localhost:50000",
            logLevel: .debug
        )

        // Track a signup event
        UserCanal.shared.track("user_signed_up", properties: [
            "signup_method": "email",
            "referral_source": "google"
        ])

        // Track a video view
        UserCanal.shared.track("video_viewed", properties: [
            "video_id": "vid_123",
            "duration": 120,
            "quality": "hd"
        ])

        // Identify user (merges with anonymous events)
        UserCanal.shared.identify("user_123", traits: [
            "email": "user@example.com",
            "plan": "free",
            "signup_date": "2024-01-15"
        ])

        // Track revenue
        UserCanal.shared.eventRevenue(
            amount: 9.99,
            currency: .usd,
            orderID: "order_456",
            properties: [
                "product": "premium_plan"
            ]
        )

        // Simple logging
        UserCanal.shared.logInfo("User completed onboarding flow")
        UserCanal.shared.logError("Payment processing failed", data: [
            "error_code": "card_declined"
        ])

        // Flush before exit
        try? await UserCanal.shared.flush()

        print("✅ Events sent to UserCanal!")
    }
}
