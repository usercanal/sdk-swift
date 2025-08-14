# Features

A high performance lighweight data collection sdk using binary data, zero copy and raw tcp with batching for communication.

- Structured Logging (app errors etc) with severity levels
- Events (product analytics) with

### Opt out of data capture
- optOut()`, `optIn()`, `isOptedOut()

## EVENT

Performance notes: this SDK only sends device context when needed.

## CONTEXT Events

CONTEXT events contain device/session information and are sent sparingly to minimize data usage:

### When CONTEXT Events Are Sent:
- ✅ **Session Start** - Once per session when app launches
- ✅ **App Background** - When user puts app in background  
- ✅ **App Foreground** - When user returns from background **after session timeout**
- ✅ **App Terminate** - When app shuts down
- ✅ **Session Timeout** - When starting new session after timeout period

### Session Timeout:
- Default: **30 minutes** of background time
- Configurable via `SessionManager.Configuration`
- Only triggers new session (and CONTEXT event) if app was backgrounded longer than timeout

### What's NOT Sent:
- ❌ **App Active/Inactive** - UI focus changes (too frequent during development)
- ❌ **Every app switch** - Only when session actually expires

### Example Flow:
```
App Launch     → CONTEXT: "Session Started"
User Activity  → TRACK events (no context)
App Background → CONTEXT: "App Background" 
[< 30min later]
App Foreground → No CONTEXT (same session continues)
[> 30min later]  
App Foreground → CONTEXT: "Session Started" (new session)
```

This design ensures CONTEXT events provide meaningful session boundaries without overwhelming your analytics pipeline.

### Feature list
- Flush
- Batching
- Device context
- Opt-out of data capture
- Anonymous users / Identified users
- Reset (distinct id)

## LOGGING
