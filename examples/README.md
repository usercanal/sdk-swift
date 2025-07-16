# UserCanal Swift SDK - Examples

Quick examples to get started with the UserCanal Swift SDK.

## Structure

```
examples/
├── event/
│   ├── simple/     # Basic event tracking
│   └── advanced/   # Revenue, groups, identification
└── log/
    ├── simple/     # Basic logging
    └── advanced/   # Structured logging patterns
```

## Quick Start

### Event Tracking

```swift
import UserCanal

// Configure once
UserCanalSDK.shared.configure(apiKey: "YOUR_API_KEY")

// Track events
UserCanalSDK.shared.track(.userSignedUp, properties: [
    "method": "email",
    "source": "google"
])

// Track revenue
UserCanalSDK.shared.eventRevenue(
    amount: 9.99,
    currency: .USD,
    orderID: "order_123"
)
```

### Logging

```swift
// Simple logging
UserCanalSDK.shared.logInfo("User completed onboarding")

UserCanalSDK.shared.logError("Payment failed", data: [
    "error_code": "card_declined",
    "user_id": "123"
])
```

## Running Examples

Each example is a standalone Swift Package:

```bash
# Simple event tracking
cd examples/event/simple
swift run

# Advanced logging
cd examples/log/advanced  
swift run
```

## What's Included

### Event Examples
- **Simple**: Basic signup, custom events, feature usage
- **Advanced**: Revenue tracking, user identification, groups, advanced configuration

### Log Examples  
- **Simple**: Info, error, debug logging
- **Advanced**: All log levels, custom entries, batch logging, structured patterns

## Key Features Shown

- ✅ Fire & forget interface (no await needed)
- ✅ Session management with automatic user merging
- ✅ Device context sent once per session (optimized)
- ✅ Revenue tracking with currency support
- ✅ Structured logging with multiple severity levels
- ✅ Error handling that never crashes your app
- ✅ Batch operations for efficiency

## Next Steps

1. Replace `"YOUR_API_KEY"` with your actual API key
2. Run the examples to see them in action
3. Copy patterns that fit your use case
4. Check the main README for complete API documentation

Happy tracking! 🚀