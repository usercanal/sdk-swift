// main.swift
// Advanced Event Tracking Example - New UserCanal Interface
//
// Copyright © 2024 UserCanal. All rights reserved.
//

import Foundation
import UserCanal

@main
struct AdvancedEventExample {
    static func main() async {
        print("🚀 UserCanal Swift SDK - Advanced Event Tracking (New Interface)")

        // Configure with advanced options
        UserCanal.shared.configure(
            apiKey: "YOUR_API_KEY",
            endpoint: "collect.usercanal.com:50000",
            batchSize: 100,
            flushInterval: 5.0,
            deviceContextRefresh: 12 * 60 * 60, // 12 hours instead of default 24
            onError: { error in
                print("🚨 Analytics error: \(error)")
            }
        )

        // Wait for initialization
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

        print("📊 Starting advanced tracking scenarios...")

        // Scenario 1: Anonymous user browsing
        print("\n1️⃣ Anonymous user browsing...")

        UserCanal.shared.track(.pageViewed, properties: [
            "screen_name": "home",
            "source": "app_launch"
        ])

        UserCanal.shared.track(.featureUsed, properties: [
            "feature_name": "product_search",
            "search_query": "wireless headphones",
            "results_count": 24
        ])

        UserCanal.shared.track(.contentViewed, properties: [
            "content_type": "product",
            "product_id": "prod_123",
            "category": "electronics",
            "price": 199.99
        ])

        // Scenario 2: User signs up (anonymous → identified)
        print("2️⃣ User signs up - merging anonymous session...")

        UserCanal.shared.identify("user_12345", traits: [
            "email": "john.doe@example.com",
            "name": "John Doe",
            "age": 28,
            "signup_method": "google_oauth",
            "marketing_consent": true,
            "user_agent": "iOS/17.0",
            "referral_source": "google_ads"
        ])

        // Now all future events will be attributed to user_12345
        UserCanal.shared.track(.userSignedUp, properties: [
            "signup_method": "google_oauth",
            "time_to_signup_minutes": 3.5,
            "onboarding_completed": false
        ])

        // Scenario 3: User completes onboarding
        print("3️⃣ User completes onboarding...")

        UserCanal.shared.track("onboarding_step_completed", properties: [
            "step": "profile_setup",
            "completion_time_seconds": 45
        ])

        UserCanal.shared.track("onboarding_step_completed", properties: [
            "step": "preferences_set",
            "completion_time_seconds": 32
        ])

        UserCanal.shared.track("onboarding_completed", properties: [
            "total_time_minutes": 4.2,
            "steps_completed": 5,
            "steps_skipped": 1
        ])

        // Scenario 4: Revenue tracking
        print("4️⃣ Revenue events...")

        UserCanal.shared.eventRevenue(
            amount: 99.99,
            currency: .usd,
            orderID: "order_789",
            properties: [
                "product_name": "Premium Plan",
                "billing_cycle": "monthly",
                "discount_code": "WELCOME20",
                "discount_amount": 20.00,
                "payment_method": "apple_pay",
                "trial_converted": true,
                "customer_lifetime_value": 299.97
            ]
        )

        // One-time purchase
        UserCanal.shared.eventRevenue(
            amount: 29.99,
            currency: .usd,
            orderID: "order_790",
            properties: [
                "product_type": "add_on",
                "product_name": "Extra Storage",
                "quantity": 1,
                "upsell_success": true
            ]
        )

        // Scenario 5: Group analytics (user joins organization)
        print("5️⃣ Group analytics...")

        UserCanal.shared.group("org_acme_corp", properties: [
            "organization_name": "Acme Corporation",
            "plan": "enterprise",
            "seat_count": 150,
            "industry": "technology",
            "company_size": "medium",
            "annual_revenue": 50000000
        ])

        UserCanal.shared.track("user_added_to_organization", properties: [
            "organization_id": "org_acme_corp",
            "role": "member",
            "invited_by": "admin_456",
            "invitation_method": "email"
        ])

        // Scenario 6: Advanced feature usage
        print("6️⃣ Advanced feature usage...")

        UserCanal.shared.track(.featureUsed, properties: [
            "feature_name": "data_export",
            "export_type": "csv",
            "file_size_mb": 15.7,
            "export_duration_seconds": 23,
            "records_exported": 10000,
            "filters_applied": [
                "date_range": "last_30_days",
                "status": "active",
                "category": "premium_users"
            ]
        ])

        UserCanal.shared.track("api_key_generated", properties: [
            "key_type": "production",
            "permissions": ["read", "write"],
            "expires_in_days": 365
        ])

        // Scenario 7: User behavior tracking
        print("7️⃣ User behavior patterns...")

        UserCanal.shared.track(.buttonTapped, properties: [
            "button_name": "share_dashboard",
            "screen": "analytics_dashboard",
            "element_position": "top_right",
            "session_duration_minutes": 15.5
        ])

        UserCanal.shared.track("search_performed", properties: [
            "search_query": "revenue analytics",
            "search_type": "dashboard_search",
            "results_count": 8,
            "clicked_result_position": 2,
            "search_duration_ms": 1250
        ])

        // Scenario 8: Advanced logging with different levels
        print("8️⃣ Advanced logging scenarios...")

        UserCanal.shared.logInfo("User session started", service: "auth", data: [
            "session_id": "sess_abc123",
            "login_method": "oauth",
            "device_type": "iPhone",
            "app_version": "2.1.0"
        ])

        UserCanal.shared.logWarning("API rate limit approaching", service: "api", data: [
            "current_rate": 85,
            "limit": 100,
            "time_window": "1_minute",
            "user_id": "user_12345"
        ])

        UserCanal.shared.logError("Payment processing failed", service: "payments", data: [
            "error_code": "insufficient_funds",
            "payment_method": "card_1234",
            "amount": 99.99,
            "currency": "USD",
            "retry_attempt": 2,
            "transaction_id": "txn_xyz789"
        ])

        UserCanal.shared.log(.critical, "Database connection lost", service: "database", data: [
            "connection_pool": "primary",
            "active_connections": 0,
            "error_message": "Connection timeout after 30s",
            "affected_services": ["user_auth", "billing", "analytics"]
        ])

        // Scenario 9: Account switching
        print("9️⃣ Account switching scenario...")

        // User switches to different account
        UserCanal.shared.identify("user_67890", traits: [
            "email": "jane.smith@company.com",
            "name": "Jane Smith",
            "role": "admin",
            "previous_user": "user_12345"
        ])

        UserCanal.shared.track("account_switched", properties: [
            "from_user": "user_12345",
            "to_user": "user_67890",
            "switch_reason": "work_account"
        ])

        // Scenario 10: User logs out
        print("🔟 User logout...")

        UserCanal.shared.track(.userSignedOut, properties: [
            "session_duration_minutes": 45.3,
            "events_tracked": 25,
            "logout_method": "manual"
        ])

        // Reset session (back to anonymous)
        UserCanal.shared.reset()

        // Anonymous event after reset
        UserCanal.shared.track("app_backgrounded", properties: [
            "session_type": "anonymous",
            "app_usage_seconds": 2700
        ])

        // Final flush to ensure all events are sent
        print("\n🚀 Flushing all events...")
        try? await UserCanal.shared.flush()

        print("✅ Advanced tracking scenarios completed!")
        print("\n📊 Summary of what happened:")
        print("   • Device context sent once at session start")
        print("   • Anonymous events automatically merged with identified user")
        print("   • Revenue events tracked with detailed properties")
        print("   • Group analytics for organization membership")
        print("   • Advanced logging with multiple severity levels")
        print("   • Account switching handled seamlessly")
        print("   • Session reset demonstrated")
        print("   • All events batched and sent efficiently")
        print("\n🎉 UserCanal's new interface makes analytics simple and powerful!")
    }
}
