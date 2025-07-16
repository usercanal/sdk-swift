// EventName.swift
// UserCanal Swift SDK
//
// Copyright © 2024 UserCanal. All rights reserved.
//

import Foundation

// MARK: - EventName

/// Represents a strongly typed event name that also allows custom strings
public struct EventName: Sendable, Hashable, Codable {
    
    // MARK: - Storage
    
    private let value: String
    
    // MARK: - Initialization
    
    /// Create an event name from a string
    public init(_ value: String) {
        self.value = value
    }
    
    /// Create an event name from a string literal
    public init(stringLiteral value: String) {
        self.value = value
    }
    
    // MARK: - Properties
    
    /// The string representation of the event name
    public var stringValue: String {
        return value
    }
    
    /// Check if this is a predefined standard event
    public var isStandardEvent: Bool {
        return Self.standardEvents.contains(self)
    }
}

// MARK: - Standard Events

extension EventName {
    
    // MARK: - Authentication & User Management Events
    
    /// User signed up for an account
    public static let userSignedUp = EventName("User Signed Up")
    
    /// User signed into their account
    public static let userSignedIn = EventName("User Signed In")
    
    /// User signed out of their account
    public static let userSignedOut = EventName("User Signed Out")
    
    /// User was invited to join
    public static let userInvited = EventName("User Invited")
    
    /// User completed onboarding process
    public static let userOnboarded = EventName("User Onboarded")
    
    /// Authentication attempt failed
    public static let authenticationFailed = EventName("Authentication Failed")
    
    /// User reset their password
    public static let passwordReset = EventName("Password Reset")
    
    /// User enabled two-factor authentication
    public static let twoFactorEnabled = EventName("Two Factor Enabled")
    
    /// User disabled two-factor authentication
    public static let twoFactorDisabled = EventName("Two Factor Disabled")
    
    // MARK: - Revenue & Billing Events
    
    /// Order was completed successfully
    public static let orderCompleted = EventName("Order Completed")
    
    /// Order was refunded
    public static let orderRefunded = EventName("Order Refunded")
    
    /// Order was canceled
    public static let orderCanceled = EventName("Order Canceled")
    
    /// Payment attempt failed
    public static let paymentFailed = EventName("Payment Failed")
    
    /// Payment method was added
    public static let paymentMethodAdded = EventName("Payment Method Added")
    
    /// Payment method was updated
    public static let paymentMethodUpdated = EventName("Payment Method Updated")
    
    /// Payment method was removed
    public static let paymentMethodRemoved = EventName("Payment Method Removed")
    
    // MARK: - Subscription Management Events
    
    /// Subscription was started
    public static let subscriptionStarted = EventName("Subscription Started")
    
    /// Subscription was renewed
    public static let subscriptionRenewed = EventName("Subscription Renewed")
    
    /// Subscription was paused
    public static let subscriptionPaused = EventName("Subscription Paused")
    
    /// Subscription was resumed from pause
    public static let subscriptionResumed = EventName("Subscription Resumed")
    
    /// Subscription plan was changed
    public static let subscriptionChanged = EventName("Subscription Changed")
    
    /// Subscription was canceled
    public static let subscriptionCanceled = EventName("Subscription Canceled")
    
    // MARK: - Trial & Conversion Events
    
    /// Trial period was started
    public static let trialStarted = EventName("Trial Started")
    
    /// Trial is ending soon
    public static let trialEndingSoon = EventName("Trial Ending Soon")
    
    /// Trial period ended
    public static let trialEnded = EventName("Trial Ended")
    
    /// Trial was converted to paid subscription
    public static let trialConverted = EventName("Trial Converted")
    
    // MARK: - Shopping Experience Events
    
    /// Shopping cart was viewed
    public static let cartViewed = EventName("Cart Viewed")
    
    /// Shopping cart was updated
    public static let cartUpdated = EventName("Cart Updated")
    
    /// Shopping cart was abandoned
    public static let cartAbandoned = EventName("Cart Abandoned")
    
    /// Checkout process was started
    public static let checkoutStarted = EventName("Checkout Started")
    
    /// Checkout process was completed
    public static let checkoutCompleted = EventName("Checkout Completed")
    
    // MARK: - Product Engagement Events
    
    /// Page or screen was viewed
    public static let pageViewed = EventName("Page Viewed")
    
    /// Feature was used
    public static let featureUsed = EventName("Feature Used")
    
    /// Search was performed
    public static let searchPerformed = EventName("Search Performed")
    
    /// File was uploaded
    public static let fileUploaded = EventName("File Uploaded")
    
    /// Notification was sent
    public static let notificationSent = EventName("Notification Sent")
    
    /// Notification was clicked
    public static let notificationClicked = EventName("Notification Clicked")
    
    // MARK: - Communication Events
    
    /// Email was sent
    public static let emailSent = EventName("Email Sent")
    
    /// Email was opened
    public static let emailOpened = EventName("Email Opened")
    
    /// Email link was clicked
    public static let emailClicked = EventName("Email Clicked")
    
    /// Email bounced
    public static let emailBounced = EventName("Email Bounced")
    
    /// User unsubscribed from emails
    public static let emailUnsubscribed = EventName("Email Unsubscribed")
    
    /// Support ticket was created
    public static let supportTicketCreated = EventName("Support Ticket Created")
    
    /// Support ticket was resolved
    public static let supportTicketResolved = EventName("Support Ticket Resolved")
    
    // MARK: - Session Events
    
    /// User session started
    public static let sessionStarted = EventName("Session Started")
    
    /// User session ended
    public static let sessionEnded = EventName("Session Ended")
    
    /// App was launched
    public static let appLaunched = EventName("App Launched")
    
    /// App entered background
    public static let appBackgrounded = EventName("App Backgrounded")
    
    /// App entered foreground
    public static let appForegrounded = EventName("App Foregrounded")
    
    // MARK: - Error Events
    
    /// Application error occurred
    public static let errorOccurred = EventName("Error Occurred")
    
    /// Crash was detected
    public static let crashDetected = EventName("Crash Detected")
    
    /// Performance issue detected
    public static let performanceIssue = EventName("Performance Issue")
}

// MARK: - Standard Events Collection

extension EventName {
    /// All predefined standard events
    public static let standardEvents: Set<EventName> = [
        // Authentication & User Management
        .userSignedUp, .userSignedIn, .userSignedOut, .userInvited, .userOnboarded,
        .authenticationFailed, .passwordReset, .twoFactorEnabled, .twoFactorDisabled,
        
        // Revenue & Billing
        .orderCompleted, .orderRefunded, .orderCanceled, .paymentFailed,
        .paymentMethodAdded, .paymentMethodUpdated, .paymentMethodRemoved,
        
        // Subscription Management
        .subscriptionStarted, .subscriptionRenewed, .subscriptionPaused,
        .subscriptionResumed, .subscriptionChanged, .subscriptionCanceled,
        
        // Trial & Conversion
        .trialStarted, .trialEndingSoon, .trialEnded, .trialConverted,
        
        // Shopping Experience
        .cartViewed, .cartUpdated, .cartAbandoned, .checkoutStarted, .checkoutCompleted,
        
        // Product Engagement
        .pageViewed, .featureUsed, .searchPerformed, .fileUploaded,
        .notificationSent, .notificationClicked,
        
        // Communication
        .emailSent, .emailOpened, .emailClicked, .emailBounced, .emailUnsubscribed,
        .supportTicketCreated, .supportTicketResolved,
        
        // Session Events
        .sessionStarted, .sessionEnded, .appLaunched, .appBackgrounded, .appForegrounded,
        
        // Error Events
        .errorOccurred, .crashDetected, .performanceIssue
    ]
}

// MARK: - Protocol Conformances

extension EventName: ExpressibleByStringLiteral {
    public typealias StringLiteralType = String
}

extension EventName: CustomStringConvertible {
    public var description: String {
        return value
    }
}

extension EventName: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "EventName(\"\(value)\")"
    }
}

extension EventName: Comparable {
    public static func < (lhs: EventName, rhs: EventName) -> Bool {
        return lhs.value < rhs.value
    }
}

// MARK: - Codable Implementation

extension EventName {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.value = try container.decode(String.self)
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

// MARK: - Event Categories

extension EventName {
    
    /// Category of the event for grouping and analytics
    public enum Category: String, Sendable, CaseIterable {
        case authentication = "authentication"
        case revenue = "revenue"
        case subscription = "subscription"
        case trial = "trial"
        case shopping = "shopping"
        case engagement = "engagement"
        case communication = "communication"
        case session = "session"
        case error = "error"
        case custom = "custom"
    }
    
    /// Get the category for this event
    public var category: Category {
        switch self {
        // Authentication & User Management
        case .userSignedUp, .userSignedIn, .userSignedOut, .userInvited, .userOnboarded,
             .authenticationFailed, .passwordReset, .twoFactorEnabled, .twoFactorDisabled:
            return .authentication
            
        // Revenue & Billing
        case .orderCompleted, .orderRefunded, .orderCanceled, .paymentFailed,
             .paymentMethodAdded, .paymentMethodUpdated, .paymentMethodRemoved:
            return .revenue
            
        // Subscription Management
        case .subscriptionStarted, .subscriptionRenewed, .subscriptionPaused,
             .subscriptionResumed, .subscriptionChanged, .subscriptionCanceled:
            return .subscription
            
        // Trial & Conversion
        case .trialStarted, .trialEndingSoon, .trialEnded, .trialConverted:
            return .trial
            
        // Shopping Experience
        case .cartViewed, .cartUpdated, .cartAbandoned, .checkoutStarted, .checkoutCompleted:
            return .shopping
            
        // Product Engagement
        case .pageViewed, .featureUsed, .searchPerformed, .fileUploaded,
             .notificationSent, .notificationClicked:
            return .engagement
            
        // Communication
        case .emailSent, .emailOpened, .emailClicked, .emailBounced, .emailUnsubscribed,
             .supportTicketCreated, .supportTicketResolved:
            return .communication
            
        // Session Events
        case .sessionStarted, .sessionEnded, .appLaunched, .appBackgrounded, .appForegrounded:
            return .session
            
        // Error Events
        case .errorOccurred, .crashDetected, .performanceIssue:
            return .error
            
        default:
            return .custom
        }
    }
}