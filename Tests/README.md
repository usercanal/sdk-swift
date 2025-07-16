# UserCanal Swift SDK - Test Suite

This directory contains comprehensive tests for the UserCanal Swift SDK, organized by domain to match the source code structure.

## Test Structure

```
Tests/UserCanalTests/
├── Core/                    # Core client interfaces
│   ├── BasicFunctionalityTests.swift
│   ├── ClientInterfaceTests.swift
│   ├── UserCanalSDKTests.swift          # New convenience interface
│   └── UserCanalTests.swift
├── Events/                  # Event domain tests
│   ├── EventDomainTests.swift
│   └── ConstantsCompatibilityTests.swift
├── Logs/                    # Logging domain tests
│   └── LogEntryTests.swift              # User-facing log protocol
├── Networking/              # Network & serialization tests
│   └── FlatBuffersProtocolTests.swift
└── Device/                  # Device context tests
    └── DeviceContextTests.swift
```

## Test Categories

### Core Tests
- **BasicFunctionalityTests**: Fundamental SDK operations
- **ClientInterfaceTests**: Low-level UserCanalClient interface
- **UserCanalSDKTests**: High-level convenience interface (`UserCanalSDK.shared`)
- **UserCanalTests**: General SDK behavior

### Events Tests
- **EventDomainTests**: Event, Identity, GroupInfo, Revenue, Product structures
- **ConstantsCompatibilityTests**: Event names, currencies, and constants

### Logs Tests  
- **LogEntryTests**: LogEntry, LogLevel, LogEventType validation and behavior

### Networking Tests
- **FlatBuffersProtocolTests**: Binary serialization and protocol compatibility

### Device Tests
- **DeviceContextTests**: Device context collection, caching, and privacy compliance

## Running Tests

### All Tests
```bash
swift test
```

### Specific Domain
```bash
swift test --filter Core
swift test --filter Events
swift test --filter Logs
swift test --filter Networking
swift test --filter Device
```

### Specific Test Class
```bash
swift test --filter UserCanalSDKTests
swift test --filter LogEntryTests
swift test --filter DeviceContextTests
```

## Test Focus Areas

### UserCanalSDK Interface Tests
- Fire & forget interface behavior
- Session management (anonymous → identified)
- Error handling that never crashes
- High-volume and concurrent tracking
- Configuration and lifecycle

### Event Domain Tests
- Event creation and validation
- Revenue tracking with products
- User identification and group membership
- Property handling and serialization

### Logging Tests
- Log entry validation and levels
- LogLevel comparison and priority
- Convenience constructors
- Structured data handling

### Device Context Tests
- Context collection and caching
- Platform-specific information
- Privacy compliance
- Performance and concurrency safety

### Networking Tests
- FlatBuffers serialization
- Binary protocol compatibility
- Batch creation and validation

## Best Practices

- **Domain Separation**: Tests are organized by the same domains as source code
- **Focused Testing**: Each test file covers a specific component or interface
- **Real-World Scenarios**: Tests simulate actual usage patterns
- **Error Resilience**: Verify graceful handling of edge cases
- **Performance**: Include performance and concurrency tests
- **Privacy**: Ensure no sensitive data collection

## Key Test Principles

1. **Fire & Forget Verification**: UserCanalSDK methods never crash or block
2. **Session Flow Testing**: Anonymous to identified user transitions
3. **Type Safety**: Validate strongly typed events and properties
4. **Privacy Compliance**: Ensure no collection of sensitive personal data
5. **Platform Coverage**: Tests work across iOS, macOS, and other Apple platforms

The test suite ensures the SDK is reliable, performant, and ready for production use across all supported platforms.