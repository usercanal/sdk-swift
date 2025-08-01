# UserCanal Swift SDK

<p align="center">
  <a href="https://swift.org/package-manager/"><img src="https://img.shields.io/badge/SPM-compatible-brightgreen.svg" alt="Swift Package Manager"></a>
  <a href="https://developer.apple.com/swift/"><img src="https://img.shields.io/badge/Swift-6.0+-orange.svg" alt="Swift 6.0+"></a>
  <a href="https://developer.apple.com/ios/"><img src="https://img.shields.io/badge/iOS-16.0+-blue.svg" alt="iOS 16.0+"></a>
  <a href="https://developer.apple.com/macos/"><img src="https://img.shields.io/badge/macOS-13.0+-blue.svg" alt="macOS 13.0+"></a>
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License: MIT"></a>
</p>

A high-performance, type-safe Swift SDK for analytics events and structured logging.

## Features

- **Fire & Forget Interface**: Simple tracking with automatic batching
- **Rich Analytics**: Events, revenue tracking, user identification, and groups
- **Structured Logging**: High-performance binary logging with multiple severity levels
- **Session Management**: Automatic user session handling with device context
- **Optimized Performance**: Actor-based architecture with efficient batching
- **Type Safety**: Strongly typed events and properties
- **Configurable**: Flexible configuration for different environments

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/usercanal/sdk-swift.git", from: "1.0.0")
]
```

Or add it through Xcode:
1. File → Add Package Dependencies
2. Enter: `https://github.com/usercanal/sdk-swift.git`
3. Select version and add to your target

## Quick Start

### Configuration

Configure the SDK once at app startup:

```swift
import UserCanal

// In your App.swift or AppDelegate
UserCanal.shared.configure(
    apiKey: "YOUR_API_KEY",
    onError: { error in
        print("Analytics error: \(error)")
    }
)
```

### Event Tracking

Track user actions with the fire & forget interface:

```swift
// Track predefined events
UserCanal.shared.track(.userSignedUp, properties: [
    "signup_method": "email",
    "referral_source": "google"
])

// Track custom events
UserCanal.shared.track("video_watched", properties: [
    "video_id": "123",
    "duration": 120,
    "quality": "hd"
])

// User identification
UserCanal.shared.identify("user_123", traits: [
    "email": "user@example.com",
    "plan": "premium",
    "signup_date": Date()
])
```

### Revenue Tracking

Track purchases and subscriptions:

```swift
UserCanal.shared.eventRevenue(
    amount: 9.99,
    currency: .usd,
    orderID: "order_456",
    properties: [
        "product_id": "premium_plan",
        "billing_cycle": "monthly"
    ]
)
```

### Structured Logging

Application logging with multiple severity levels:

```swift
// Simple logging
UserCanal.shared.logInfo("User completed onboarding")

UserCanal.shared.logError("Payment failed", data: [
    "error_code": "card_declined",
    "user_id": "123",
    "amount": 9.99
])

// Custom service logging
UserCanal.shared.log(.warning, "Cache miss rate high", service: "cache", data: [
    "hit_ratio": 0.65,
    "threshold": 0.80
])
```

### Privacy Controls

User privacy controls with `optOut()`, `optIn()`, and `isOptedOut()` methods - events are dropped locally without server round-trips, and you can configure `defaultOptOut: true` for privacy-first setups.

### Event IDs

Client-side unique event IDs are disabled by default to save ~50 bytes per event. Enable with `generateEventIds: true` if you need individual event deduplication or tracking.

## Advanced Usage

### Configuration Options

```swift
UserCanal.shared.configure(
    apiKey: "YOUR_API_KEY",
    endpoint: "collect.usercanal.com:50000",  // Custom endpoint
    batchSize: 100,                           // Events per batch
    flushInterval: 30.0,                      // Seconds between flushes
    generateEventIds: true,                   // Enable client-side event IDs
    deviceContextRefresh: 24 * 60 * 60,      // Device context refresh interval
    onError: { error in
        // Handle errors
    }
)
```

### Group Analytics

Associate users with organizations or teams:

```swift
UserCanal.shared.group("org_123", properties: [
    "organization_name": "Acme Corp",
    "plan": "enterprise",
    "seat_count": 50
])
```

### Session Management

The SDK automatically manages user sessions:

```swift
// Anonymous tracking (automatic)
UserCanal.shared.track(.pageViewed, properties: ["screen": "home"])

// User registers - automatic session merging
UserCanal.shared.identify("user_123", traits: ["email": "user@example.com"])

// User logout - reset to anonymous
UserCanal.shared.reset()
```

### Manual Control

For critical moments, you can manually flush events:

```swift
// Ensure events are sent before app termination
await UserCanal.shared.flush()
```

## SwiftUI Integration

The SDK works seamlessly with SwiftUI patterns:

```swift
struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack {
                Button("Purchase Premium") {
                    handlePurchase()
                }

                NavigationLink("Settings") {
                    SettingsView()
                }
            }
        }
        .task {
            // Track screen view
            UserCanal.shared.track(.pageViewed, properties: [
                "screen_name": "home"
            ])
        }
    }

    private func handlePurchase() {
        // Track button tap
        UserCanal.shared.track(.buttonTapped, properties: [
            "button": "purchase_premium",
            "screen": "home"
        ])

        // Process purchase...
        // Track revenue
        UserCanal.shared.eventRevenue(
            amount: 9.99,
            currency: .usd,
            orderID: UUID().uuidString
        )
    }
}
```

## API Reference

### Core Methods

```swift
// Configuration
UserCanal.shared.configure(apiKey:onError:)

// Event Tracking
UserCanal.shared.track(_:properties:)
UserCanal.shared.eventRevenue(amount:currency:orderID:properties:)

// User Management
UserCanal.shared.identify(_:traits:)
UserCanal.shared.group(_:properties:)
UserCanal.shared.reset()

// Logging
UserCanal.shared.log(_:_:service:data:)
UserCanal.shared.logInfo(_:service:data:)
UserCanal.shared.logError(_:service:data:)

// Lifecycle
await UserCanal.shared.flush()
```

### Predefined Events

The SDK includes comprehensive event constants organized by category:

**Authentication & User Management**
```swift
.userSignedUp, .userSignedIn, .userSignedOut, .userInvited, .userOnboarded
.authenticationFailed, .passwordReset, .twoFactorEnabled, .twoFactorDisabled
```

**Revenue & Billing**
```swift
.orderCompleted, .orderRefunded, .orderCanceled, .paymentFailed
.paymentMethodAdded, .paymentMethodUpdated, .paymentMethodRemoved
```

**Subscription Management**
```swift
.subscriptionStarted, .subscriptionRenewed, .subscriptionPaused
.subscriptionResumed, .subscriptionChanged, .subscriptionCanceled
```

**Product Engagement**
```swift
.pageViewed, .featureUsed, .searchPerformed, .fileUploaded
.notificationSent, .notificationClicked, .buttonTapped
```

**Session & Error Events**
```swift
.sessionStarted, .sessionEnded, .appLaunched, .appBackgrounded
.errorOccurred, .crashDetected, .performanceIssue
```

### Log Levels

Following RFC 5424 standard with additional trace level:

```swift
.emergency  // System is unusable
.alert      // Action must be taken immediately
.critical   // Critical conditions
.error      // Error conditions
.warning    // Warning conditions
.notice     // Normal but significant condition
.info       // Informational messages
.debug      // Debug-level messages
.trace      // Detailed trace information
```

### Properties

All events and logs accept structured properties:

```swift
UserCanal.shared.track(.featureUsed, properties: [
    "feature_name": "data_export",
    "export_format": "csv",
    "file_size_mb": 15.7,
    "processing_time_ms": 2300,
    "success": true
])
```

## Examples

The `examples/` directory contains complete sample applications:

- **`examples/event/simple/`** - Basic event tracking
- **`examples/event/advanced/`** - Revenue, identification, groups
- **`examples/log/simple/`** - Basic application logging
- **`examples/log/advanced/`** - Structured logging patterns
- **`examples/privacy-controls/`** - Opt-out/opt-in functionality


## Requirements

- iOS 16.0+ / macOS 13.0+ / visionOS 1.0+
- Swift 6.0+
- Xcode 16.0+

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- **Documentation**: [https://docs.usercanal.com](https://docs.usercanal.com)
- **Issues**: [GitHub Issues](https://github.com/usercanal/sdk-swift/issues)
- **Email**: support@usercanal.com

---

Made with ❤️ by the UserCanal team
