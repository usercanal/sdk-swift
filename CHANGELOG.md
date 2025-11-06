# Changelog

## [1.1.5] - August 20, 2025
Xcode 26 / Swift 6 Compatibility

- fix: Upgraded FlatBuffers dependency to 25.9.23 for Swift 6 compatibility
- fix: Regenerated FlatBuffers code with proper module imports
- fix: Fixed concurrency safety warnings in SDKLogger using `nonisolated(unsafe)` with NSLock

## August 14, 2025
CONTEXT Events Optimization

- fix: Removed excessive CONTEXT events for app active/inactive transitions
- docs: Added CONTEXT events documentation in FEATURES.md

## August 13, 2025
Schema Optimisations, Session Management & Context Events

**Major Update**: Implemented comprehensive session management and context event system for iOS. All events now automatically include device_id + session_id with rich device context (battery, memory, screen info, etc.).

- feat: Added EventAdvanced struct with optional device_id, session_id, timestamp overrides
- feat: Added `client.eventAdvanced(event)` method for manual ID overrides
- feat: Added SessionManager with iOS app lifecycle integration
- feat: Added automatic device ID persistence in keychain
- feat: Added session timeout management with configurable intervals
- feat: Added context events for app state changes (background/foreground/active)
- feat: Added event_name and session_id fields to Event FlatBuffers schema
- feat: Added CONTEXT EventType for session/device context routing
- feat: Added protocol version support (PROTOCOL_VERSION_CURRENT = 100)
- feat: Added comprehensive EventAdvanced example with iOS-specific scenarios
- feat: Added sessionTimeout configuration parameter
- refactor: Updated FlatBuffers serialization to include event_name field
- refactor: Updated batch creation to include protocol version
- refactor: Event payload simplified - properties directly in payload (no event_name duplication)
- refactor: iOS events use device ID from keychain and session ID from SessionManager by default
- refactor: EventAdvanced allows explicit device/session ID overrides for proxy scenarios
- fix: Updated Event schema field ordering for optimal collector performance
- **BREAKING**: Event schema updated with new fields, iOS behavior changed for session management

## [Unreleased]

### Added
- Fire & forget interface with `UserCanalSDK.shared`
- Automatic session management with device context optimization
- Session-based user identification with anonymous ID merging
- Structured logging with multiple severity levels
- Revenue tracking with currency support
- Group analytics for organization membership
- SwiftUI integration patterns
- Comprehensive examples and documentation

### Changed
- Reorganized codebase into domain-based structure
- Improved developer experience with simplified API
- Enhanced error handling with optional callbacks
- Optimized device context collection (sent once per session)

## [1.0.0] - TBD

### Added
- Initial release of UserCanal Swift SDK
- Event tracking with type-safe event names
- User identification and traits
- Revenue and subscription tracking
- Structured binary logging
- Device context collection
- Batch processing with intelligent retry logic
- Swift 6 concurrency support
- iOS 16.0+ and macOS 13.0+ support
