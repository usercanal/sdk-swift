// Constants.swift
// UserCanal Swift SDK
//
// Copyright © 2024 UserCanal. All rights reserved.
//

import Foundation

// MARK: - Revenue Types

/// Type of revenue transaction
public enum RevenueType: String, Sendable, CaseIterable, Codable {
    /// One-time purchase
    case oneTime = "one_time"
    
    /// Recurring subscription
    case subscription = "subscription"
    
    /// In-app purchase
    case inApp = "in_app"
    
    /// Freemium upgrade
    case upgrade = "upgrade"
    
    /// Refund (negative revenue)
    case refund = "refund"
}

// MARK: - Authentication Methods

/// Authentication method used by user
public enum AuthMethod: String, Sendable, CaseIterable, Codable {
    /// Email and password
    case password = "password"
    
    /// Google OAuth
    case google = "google"
    
    /// Apple Sign In
    case apple = "apple"
    
    /// GitHub OAuth
    case github = "github"
    
    /// Facebook OAuth
    case facebook = "facebook"
    
    /// Twitter OAuth
    case twitter = "twitter"
    
    /// LinkedIn OAuth
    case linkedin = "linkedin"
    
    /// Microsoft OAuth
    case microsoft = "microsoft"
    
    /// Single Sign-On
    case sso = "sso"
    
    /// Email magic link
    case email = "email"
    
    /// SMS verification
    case sms = "sms"
    
    /// Biometric authentication
    case biometric = "biometric"
    
    /// Two-factor authentication
    case twoFactor = "two_factor"
}

// MARK: - Device Types

/// Type of device used (for enrichment context only)
public enum DeviceType: String, Sendable, CaseIterable, Codable {
    /// Mobile phone
    case mobile = "mobile"
    
    /// Tablet device
    case tablet = "tablet"
    
    /// Desktop computer
    case desktop = "desktop"
    
    /// Smart TV
    case tv = "tv"
    
    /// Smartwatch
    case watch = "watch"
    
    /// VR/AR headset
    case vr = "vr"
    
    /// Unknown device type
    case unknown = "unknown"
}

// MARK: - Operating Systems

/// Operating system type (for enrichment context only)
public enum OSType: String, Sendable, CaseIterable, Codable {
    /// iOS
    case iOS = "ios"
    
    /// macOS
    case macOS = "macos"
    
    /// visionOS
    case visionOS = "visionos"
    
    /// watchOS
    case watchOS = "watchos"
    
    /// tvOS
    case tvOS = "tvos"
    
    /// Unknown OS
    case unknown = "unknown"
}



// MARK: - Payment Methods

/// Payment method used for transactions
public enum PaymentMethod: String, Sendable, CaseIterable, Codable {
    /// Credit/debit card
    case card = "card"
    
    /// Apple Pay
    case applePay = "apple_pay"
    
    /// Google Pay
    case googlePay = "google_pay"
    
    /// PayPal
    case paypal = "paypal"
    
    /// Stripe
    case stripe = "stripe"
    
    /// Square
    case square = "square"
    
    /// Bank transfer
    case bankTransfer = "bank_transfer"
    
    /// Wire transfer
    case wire = "wire"
    
    /// ACH transfer
    case ach = "ach"
    
    /// Venmo
    case venmo = "venmo"
    
    /// Zelle
    case zelle = "zelle"
    
    /// Cash
    case cash = "cash"
    
    /// Check
    case check = "check"
    
    /// Cryptocurrency
    case crypto = "crypto"
    
    /// Gift card
    case giftCard = "gift_card"
    
    /// Store credit
    case storeCredit = "store_credit"
    
    /// Buy now, pay later
    case bnpl = "bnpl"
    
    /// Other payment method
    case other = "other"
}

// MARK: - Traffic Channels

/// Marketing channel type
public enum Channel: String, Sendable, CaseIterable, Codable {
    /// Direct traffic
    case direct = "direct"
    
    /// Organic search
    case organic = "organic"
    
    /// Paid advertising
    case paid = "paid"
    
    /// Social media
    case social = "social"
    
    /// Email marketing
    case email = "email"
    
    /// SMS marketing
    case sms = "sms"
    
    /// Push notifications
    case push = "push"
    
    /// Referral program
    case referral = "referral"
    
    /// Affiliate marketing
    case affiliate = "affiliate"
    
    /// Display advertising
    case display = "display"
    
    /// Video advertising
    case video = "video"
    
    /// Audio advertising
    case audio = "audio"
    
    /// Print media
    case print = "print"
    
    /// Event marketing
    case event = "event"
    
    /// Webinar
    case webinar = "webinar"
    
    /// Podcast
    case podcast = "podcast"
    
    /// Content marketing
    case content = "content"
    
    /// Influencer marketing
    case influencer = "influencer"
    
    /// Partnership
    case partnership = "partnership"
}

// MARK: - Traffic Sources

/// Traffic source attribution
public enum Source: String, Sendable, CaseIterable, Codable {
    /// Google
    case google = "google"
    
    /// Facebook
    case facebook = "facebook"
    
    /// Instagram
    case instagram = "instagram"
    
    /// Twitter/X
    case twitter = "twitter"
    
    /// LinkedIn
    case linkedin = "linkedin"
    
    /// YouTube
    case youtube = "youtube"
    
    /// TikTok
    case tiktok = "tiktok"
    
    /// Snapchat
    case snapchat = "snapchat"
    
    /// Pinterest
    case pinterest = "pinterest"
    
    /// Reddit
    case reddit = "reddit"
    
    /// WhatsApp
    case whatsapp = "whatsapp"
    
    /// Telegram
    case telegram = "telegram"
    
    /// Discord
    case discord = "discord"
    
    /// Bing
    case bing = "bing"
    
    /// Yahoo
    case yahoo = "yahoo"
    
    /// DuckDuckGo
    case duckduckgo = "duckduckgo"
    
    /// Newsletter
    case newsletter = "newsletter"
    
    /// Email campaign
    case email = "email"
    
    /// Blog
    case blog = "blog"
    
    /// Podcast
    case podcast = "podcast"
    
    /// Webinar
    case webinar = "webinar"
    
    /// Partner site
    case partner = "partner"
    
    /// Affiliate
    case affiliate = "affiliate"
    
    /// Direct traffic
    case direct = "direct"
    
    /// Organic search
    case organic = "organic"
    
    /// Unknown source
    case unknown = "unknown"
}

// MARK: - Subscription Intervals

/// Subscription billing interval
public enum SubscriptionInterval: String, Sendable, CaseIterable, Codable {
    /// Daily billing
    case daily = "daily"
    
    /// Weekly billing
    case weekly = "weekly"
    
    /// Monthly billing
    case monthly = "monthly"
    
    /// Quarterly billing
    case quarterly = "quarterly"
    
    /// Semi-annual billing
    case semiAnnual = "semi_annual"
    
    /// Annual billing
    case annual = "annual"
    
    /// Yearly billing (alias for annual)
    case yearly = "yearly"
    
    /// Lifetime access
    case lifetime = "lifetime"
    
    /// Custom interval
    case custom = "custom"
}

// MARK: - Plan Types

/// Subscription plan type
public enum PlanType: String, Sendable, CaseIterable, Codable {
    /// Free plan
    case free = "free"
    
    /// Freemium plan
    case freemium = "freemium"
    
    /// Starter plan
    case starter = "starter"
    
    /// Basic plan
    case basic = "basic"
    
    /// Standard plan
    case standard = "standard"
    
    /// Professional plan
    case professional = "professional"
    
    /// Premium plan
    case premium = "premium"
    
    /// Business plan
    case business = "business"
    
    /// Enterprise plan
    case enterprise = "enterprise"
    
    /// Custom plan
    case custom = "custom"
    
    /// Trial plan
    case trial = "trial"
    
    /// Beta plan
    case beta = "beta"
}

// MARK: - User Roles

/// User role in organization
public enum UserRole: String, Sendable, CaseIterable, Codable {
    /// Owner/Founder
    case owner = "owner"
    
    /// Administrator
    case admin = "admin"
    
    /// Manager
    case manager = "manager"
    
    /// Team lead
    case teamLead = "team_lead"
    
    /// User/Member
    case user = "user"
    
    /// Guest user
    case guest = "guest"
    
    /// Viewer (read-only)
    case viewer = "viewer"
    
    /// Editor
    case editor = "editor"
    
    /// Contributor
    case contributor = "contributor"
    
    /// Moderator
    case moderator = "moderator"
    
    /// Support agent
    case support = "support"
    
    /// Developer
    case developer = "developer"
    
    /// Analyst
    case analyst = "analyst"
    
    /// Billing contact
    case billing = "billing"
    
    /// Sales representative
    case sales = "sales"
    
    /// Marketing
    case marketing = "marketing"
}

// MARK: - Company Sizes

/// Organization size categories
public enum CompanySize: String, Sendable, CaseIterable, Codable {
    /// Individual/Solopreneur
    case solopreneur = "solopreneur"
    
    /// Startup (1-10 employees)
    case startup = "startup"
    
    /// Small business (11-50 employees)
    case small = "small"
    
    /// Medium business (51-200 employees)
    case medium = "medium"
    
    /// Large business (201-1000 employees)
    case large = "large"
    
    /// Enterprise (1001-5000 employees)
    case enterprise = "enterprise"
    
    /// Mega corporation (5000+ employees)
    case megaCorp = "mega_corp"
    
    /// Unknown size
    case unknown = "unknown"
}

// MARK: - Industries

/// Industry categories
public enum Industry: String, Sendable, CaseIterable, Codable {
    /// Technology/Software
    case technology = "technology"
    
    /// Financial services
    case finance = "finance"
    
    /// Healthcare/Medical
    case healthcare = "healthcare"
    
    /// Education
    case education = "education"
    
    /// E-commerce/Retail
    case ecommerce = "ecommerce"
    
    /// Retail (physical)
    case retail = "retail"
    
    /// Manufacturing
    case manufacturing = "manufacturing"
    
    /// Real estate
    case realEstate = "real_estate"
    
    /// Media/Entertainment
    case media = "media"
    
    /// Travel/Hospitality
    case travel = "travel"
    
    /// Food/Beverage
    case food = "food"
    
    /// Automotive
    case automotive = "automotive"
    
    /// Energy/Utilities
    case energy = "energy"
    
    /// Agriculture
    case agriculture = "agriculture"
    
    /// Construction
    case construction = "construction"
    
    /// Transportation/Logistics
    case transportation = "transportation"
    
    /// Telecommunications
    case telecommunications = "telecommunications"
    
    /// Insurance
    case insurance = "insurance"
    
    /// Banking
    case banking = "banking"
    
    /// Non-profit
    case nonProfit = "non_profit"
    
    /// Government
    case government = "government"
    
    /// Consulting
    case consulting = "consulting"
    
    /// Legal services
    case legal = "legal"
    
    /// Marketing/Advertising
    case marketing = "marketing"
    
    /// Human resources
    case humanResources = "human_resources"
    
    /// Other industry
    case other = "other"
    
    /// Unknown industry
    case unknown = "unknown"
}

// MARK: - Log Event Types



// MARK: - Network Connection Types

/// Type of network connection
public enum NetworkConnectionType: String, Sendable, CaseIterable, Codable {
    /// WiFi connection
    case wifi = "wifi"
    
    /// Cellular connection
    case cellular = "cellular"
    
    /// Ethernet connection
    case ethernet = "ethernet"
    
    /// Bluetooth connection
    case bluetooth = "bluetooth"
    
    /// VPN connection
    case vpn = "vpn"
    
    /// Offline/no connection
    case offline = "offline"
    
    /// Unknown connection type
    case unknown = "unknown"
}

// MARK: - App States

/// Application state
public enum AppState: String, Sendable, CaseIterable, Codable {
    /// App is active and in foreground
    case active = "active"
    
    /// App is inactive but still in foreground
    case inactive = "inactive"
    
    /// App is in background
    case background = "background"
    
    /// App is suspended
    case suspended = "suspended"
    
    /// App is not running
    case notRunning = "not_running"
    
    /// Unknown state
    case unknown = "unknown"
}

// MARK: - Performance Metrics

/// Performance metric types
public enum PerformanceMetric: String, Sendable, CaseIterable, Codable {
    /// App launch time
    case launchTime = "launch_time"
    
    /// Screen load time
    case screenLoadTime = "screen_load_time"
    
    /// API response time
    case apiResponseTime = "api_response_time"
    
    /// Memory usage
    case memoryUsage = "memory_usage"
    
    /// CPU usage
    case cpuUsage = "cpu_usage"
    
    /// Battery usage
    case batteryUsage = "battery_usage"
    
    /// Network latency
    case networkLatency = "network_latency"
    
    /// Frame rate
    case frameRate = "frame_rate"
    
    /// Crash rate
    case crashRate = "crash_rate"
    
    /// Error rate
    case errorRate = "error_rate"
}

// MARK: - Protocol Conformances

extension RevenueType: CustomStringConvertible {
    public var description: String { rawValue }
}

extension AuthMethod: CustomStringConvertible {
    public var description: String { rawValue }
}

extension DeviceType: CustomStringConvertible {
    public var description: String { rawValue }
}

extension OSType: CustomStringConvertible {
    public var description: String { rawValue }
}



extension PaymentMethod: CustomStringConvertible {
    public var description: String { rawValue }
}

extension Channel: CustomStringConvertible {
    public var description: String { rawValue }
}

extension Source: CustomStringConvertible {
    public var description: String { rawValue }
}

extension SubscriptionInterval: CustomStringConvertible {
    public var description: String { rawValue }
}

extension PlanType: CustomStringConvertible {
    public var description: String { rawValue }
}

extension UserRole: CustomStringConvertible {
    public var description: String { rawValue }
}

extension CompanySize: CustomStringConvertible {
    public var description: String { rawValue }
}

extension Industry: CustomStringConvertible {
    public var description: String { rawValue }
}



extension NetworkConnectionType: CustomStringConvertible {
    public var description: String { rawValue }
}

extension AppState: CustomStringConvertible {
    public var description: String { rawValue }
}

extension PerformanceMetric: CustomStringConvertible {
    public var description: String { rawValue }
}