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
        print("🚀 UserCanal Swift SDK - Simple Event Tracking (New Interface)")
        
        // Configure UserCanal once at startup
        UserCanalSDK.shared.configure(
            apiKey: "YOUR_API_KEY",
            onError: { error in
                print("Analytics error: \(error)")
            }
        )
        
        // Wait a moment for initialization
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Fire & forget event tracking - no await needed!
        
        // Track a signup event using predefined constant
        UserCanalSDK.shared.track(.userSignedUp, properties: [
            "signup_method": "email",
            "referral_source": "google"
        ])
        
        // Track a custom event using string directly
        UserCanalSDK.shared.track("video.viewed", properties: [
            "video_id": "vid_123",
            "duration": 120,
            "quality": "hd",
            "platform": "ios"
        ])
        
        // Track another predefined event
        UserCanalSDK.shared.track(.featureUsed, properties: [
            "feature_name": "dashboard",
            "section": "analytics"
        ])
        
        // User registers - identify them (merges with anonymous events)
        UserCanalSDK.shared.identify("user_123", traits: [
            "email": "user@example.com",
            "plan": "free",
            "signup_date": Date()
        ])
        
        // Track revenue event
        UserCanalSDK.shared.eventRevenue(
            amount: 9.99,
            currency: .USD,
            orderID: "order_456",
            properties: [
                "product": "premium_plan",
                "discount": "first_month_50"
            ]
        )
        
        // Simple logging
        UserCanalSDK.shared.logInfo("User completed onboarding flow")
        
        UserCanalSDK.shared.logError("Payment processing failed", data: [
            "error_code": "card_declined",
            "retry_count": 1
        ])
        
        // Ensure events are sent before program exits
        print("Flushing events...")
        try await UserCanalSDK.shared.flush()
        
        print("✅ Events sent to UserCanal!")
        print("✨ Notice how clean and simple the new interface is!")
        print("📊 Device context was sent automatically once per session")
        print("🔄 Anonymous events were automatically merged with identified user")
    }
}