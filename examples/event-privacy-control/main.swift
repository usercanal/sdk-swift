// main.swift
// Privacy Controls Example - Simple opt-out/opt-in
//
// Copyright © 2024 UserCanal. All rights reserved.
//

import Foundation
import UserCanal

@main
struct PrivacyControlsExample {
    static func main() async {
        print("🔒 UserCanal Privacy Controls - Simple Example\n")

        // Configure SDK
        do {
            try await UserCanal.shared.configure(
                apiKey: "000102030405060708090a0b0c0d0e0f",
                endpoint: "localhost:50000"
            )
        } catch {
            print("❌ Configuration failed: \(error)")
            return
        }

        try? await Task.sleep(nanoseconds: 1_000_000_000)

        // Check initial status
        print("Initial status: \(UserCanal.shared.isOptedOut())")

        // Track an event (will be sent)
        UserCanal.shared.track("button_clicked")
        print("Event tracked while opted in")

        // Opt out
        UserCanal.shared.optOut()
        print("User opted out: \(UserCanal.shared.isOptedOut())")

        // This event will be dropped
        UserCanal.shared.track("page_viewed")
        print("Event dropped while opted out")

        // Opt back in
        UserCanal.shared.optIn()
        print("User opted in: \(UserCanal.shared.isOptedOut())")

        // This event will be sent
        UserCanal.shared.track("feature_used")
        print("Event tracked after opting back in")

        // Privacy-first configuration
        print("\nFor privacy-first apps, use: defaultOptOut: true")

        try? await Task.sleep(nanoseconds: 1_000_000_000)

        do {
            try await UserCanal.shared.flush()
            print("✅ Flush completed!")
        } catch {
            print("❌ Flush failed: \(error)")
        }
    }
}
