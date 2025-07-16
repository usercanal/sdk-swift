// ConstantsCompatibilityTests.swift
// UserCanal Swift SDK Tests
//
// Copyright © 2024 UserCanal. All rights reserved.
//

import XCTest
@testable import UserCanal

final class ConstantsCompatibilityTests: XCTestCase {
    
    // MARK: - Event Name Constants Tests
    
    func testUserLifecycleEventNames() {
        // Verify Swift event names match Go SDK constants exactly
        
        XCTAssertEqual(EventName.userSignedUp.stringValue, "user_signed_up")
        XCTAssertEqual(EventName.userSignedIn.stringValue, "user_signed_in")
        XCTAssertEqual(EventName.userSignedOut.stringValue, "user_signed_out")
        XCTAssertEqual(EventName.userInvited.stringValue, "user_invited")
        XCTAssertEqual(EventName.userOnboarded.stringValue, "user_onboarded")
    }
    
    func testAuthenticationEventNames() {
        XCTAssertEqual(EventName.authenticationFailed.stringValue, "authentication_failed")
        XCTAssertEqual(EventName.passwordReset.stringValue, "password_reset")
        XCTAssertEqual(EventName.twoFactorEnabled.stringValue, "two_factor_enabled")
        XCTAssertEqual(EventName.twoFactorDisabled.stringValue, "two_factor_disabled")
    }
    
    func testCommerceEventNames() {
        XCTAssertEqual(EventName.orderCompleted.stringValue, "order_completed")
        XCTAssertEqual(EventName.orderRefunded.stringValue, "order_refunded")
        XCTAssertEqual(EventName.orderCanceled.stringValue, "order_canceled")
        XCTAssertEqual(EventName.paymentFailed.stringValue, "payment_failed")
        XCTAssertEqual(EventName.paymentMethodAdded.stringValue, "payment_method_added")
        XCTAssertEqual(EventName.paymentMethodUpdated.stringValue, "payment_method_updated")
        XCTAssertEqual(EventName.paymentMethodRemoved.stringValue, "payment_method_removed")
    }
    
    func testSubscriptionEventNames() {
        XCTAssertEqual(EventName.subscriptionStarted.stringValue, "subscription_started")
        XCTAssertEqual(EventName.subscriptionRenewed.stringValue, "subscription_renewed")
        XCTAssertEqual(EventName.subscriptionPaused.stringValue, "subscription_paused")
        XCTAssertEqual(EventName.subscriptionResumed.stringValue, "subscription_resumed")
        XCTAssertEqual(EventName.subscriptionChanged.stringValue, "subscription_changed")
        XCTAssertEqual(EventName.subscriptionCanceled.stringValue, "subscription_canceled")
    }
    
    func testTrialEventNames() {
        XCTAssertEqual(EventName.trialStarted.stringValue, "trial_started")
        XCTAssertEqual(EventName.trialEndingSoon.stringValue, "trial_ending_soon")
        XCTAssertEqual(EventName.trialEnded.stringValue, "trial_ended")
        XCTAssertEqual(EventName.trialConverted.stringValue, "trial_converted")
    }
    
    func testShoppingEventNames() {
        XCTAssertEqual(EventName.cartViewed.stringValue, "cart_viewed")
        XCTAssertEqual(EventName.cartUpdated.stringValue, "cart_updated")
        XCTAssertEqual(EventName.cartAbandoned.stringValue, "cart_abandoned")
        XCTAssertEqual(EventName.checkoutStarted.stringValue, "checkout_started")
        XCTAssertEqual(EventName.checkoutCompleted.stringValue, "checkout_completed")
    }
    
    func testProductEventNames() {
        XCTAssertEqual(EventName.pageViewed.stringValue, "page_viewed")
        XCTAssertEqual(EventName.featureUsed.stringValue, "feature_used")
        XCTAssertEqual(EventName.searchPerformed.stringValue, "search_performed")
        XCTAssertEqual(EventName.fileUploaded.stringValue, "file_uploaded")
        XCTAssertEqual(EventName.notificationSent.stringValue, "notification_sent")
        XCTAssertEqual(EventName.notificationClicked.stringValue, "notification_clicked")
    }
    
    func testEmailEventNames() {
        XCTAssertEqual(EventName.emailSent.stringValue, "email_sent")
        XCTAssertEqual(EventName.emailOpened.stringValue, "email_opened")
        XCTAssertEqual(EventName.emailClicked.stringValue, "email_clicked")
        XCTAssertEqual(EventName.emailBounced.stringValue, "email_bounced")
        XCTAssertEqual(EventName.emailUnsubscribed.stringValue, "email_unsubscribed")
    }
    
    func testSupportEventNames() {
        XCTAssertEqual(EventName.supportTicketCreated.stringValue, "support_ticket_created")
        XCTAssertEqual(EventName.supportTicketResolved.stringValue, "support_ticket_resolved")
    }
    
    // MARK: - Currency Constants Tests
    
    func testMajorCurrencies() {
        // Major Global Currencies (matching Go SDK order)
        XCTAssertEqual(Currency.USD.rawValue, "USD")
        XCTAssertEqual(Currency.EUR.rawValue, "EUR")
        XCTAssertEqual(Currency.GBP.rawValue, "GBP")
        XCTAssertEqual(Currency.JPY.rawValue, "JPY")
        XCTAssertEqual(Currency.CAD.rawValue, "CAD")
        XCTAssertEqual(Currency.AUD.rawValue, "AUD")
        XCTAssertEqual(Currency.NZD.rawValue, "NZD")
        XCTAssertEqual(Currency.KRW.rawValue, "KRW")
        XCTAssertEqual(Currency.CNY.rawValue, "CNY")
        XCTAssertEqual(Currency.HKD.rawValue, "HKD")
        XCTAssertEqual(Currency.SGD.rawValue, "SGD")
        XCTAssertEqual(Currency.MXN.rawValue, "MXN")
        XCTAssertEqual(Currency.INR.rawValue, "INR")
        XCTAssertEqual(Currency.PLN.rawValue, "PLN")
        XCTAssertEqual(Currency.BRL.rawValue, "BRL")
        XCTAssertEqual(Currency.RUB.rawValue, "RUB")
    }
    
    func testEuropeanCurrencies() {
        XCTAssertEqual(Currency.DKK.rawValue, "DKK")
        XCTAssertEqual(Currency.NOK.rawValue, "NOK")
        XCTAssertEqual(Currency.SEK.rawValue, "SEK")
        XCTAssertEqual(Currency.CHF.rawValue, "CHF")
        XCTAssertEqual(Currency.CZK.rawValue, "CZK")
        XCTAssertEqual(Currency.HUF.rawValue, "HUF")
        XCTAssertEqual(Currency.RON.rawValue, "RON")
        XCTAssertEqual(Currency.BGN.rawValue, "BGN")
        XCTAssertEqual(Currency.HRK.rawValue, "HRK")
    }
    
    func testMiddleEasternCurrencies() {
        XCTAssertEqual(Currency.AED.rawValue, "AED")
        XCTAssertEqual(Currency.SAR.rawValue, "SAR")
        XCTAssertEqual(Currency.QAR.rawValue, "QAR")
        XCTAssertEqual(Currency.BHD.rawValue, "BHD")
        XCTAssertEqual(Currency.KWD.rawValue, "KWD")
        XCTAssertEqual(Currency.OMR.rawValue, "OMR")
        XCTAssertEqual(Currency.JOD.rawValue, "JOD")
        XCTAssertEqual(Currency.LBP.rawValue, "LBP")
        XCTAssertEqual(Currency.ILS.rawValue, "ILS")
    }
    
    func testAsianCurrencies() {
        XCTAssertEqual(Currency.THB.rawValue, "THB")
        XCTAssertEqual(Currency.MYR.rawValue, "MYR")
        XCTAssertEqual(Currency.IDR.rawValue, "IDR")
        XCTAssertEqual(Currency.VND.rawValue, "VND")
        XCTAssertEqual(Currency.PHP.rawValue, "PHP")
        XCTAssertEqual(Currency.MNT.rawValue, "MNT")
    }
    
    func testAfricanCurrencies() {
        XCTAssertEqual(Currency.ZAR.rawValue, "ZAR")
        XCTAssertEqual(Currency.EGP.rawValue, "EGP")
    }
    
    func testLatinAmericanCurrencies() {
        XCTAssertEqual(Currency.ARS.rawValue, "ARS")
        XCTAssertEqual(Currency.CLP.rawValue, "CLP")
        XCTAssertEqual(Currency.COP.rawValue, "COP")
        XCTAssertEqual(Currency.PEN.rawValue, "PEN")
        XCTAssertEqual(Currency.UYU.rawValue, "UYU")
    }
    
    func testEasternEuropeanCurrencies() {
        XCTAssertEqual(Currency.RSD.rawValue, "RSD")
        XCTAssertEqual(Currency.BAM.rawValue, "BAM")
        XCTAssertEqual(Currency.MKD.rawValue, "MKD")
        XCTAssertEqual(Currency.ALL.rawValue, "ALL")
        XCTAssertEqual(Currency.UAH.rawValue, "UAH")
        XCTAssertEqual(Currency.BYN.rawValue, "BYN")
        XCTAssertEqual(Currency.MDL.rawValue, "MDL")
    }
    
    func testCaucasianCurrencies() {
        XCTAssertEqual(Currency.GEL.rawValue, "GEL")
        XCTAssertEqual(Currency.AMD.rawValue, "AMD")
        XCTAssertEqual(Currency.AZN.rawValue, "AZN")
    }
    
    func testCentralAsianCurrencies() {
        XCTAssertEqual(Currency.KZT.rawValue, "KZT")
        XCTAssertEqual(Currency.UZS.rawValue, "UZS")
        XCTAssertEqual(Currency.KGS.rawValue, "KGS")
        XCTAssertEqual(Currency.TJS.rawValue, "TJS")
        XCTAssertEqual(Currency.TMT.rawValue, "TMT")
    }
    
    func testOtherCurrencies() {
        XCTAssertEqual(Currency.TRY.rawValue, "TRY")
    }
    
    func testCryptocurrencies() {
        XCTAssertEqual(Currency.BTC.rawValue, "BTC")
        XCTAssertEqual(Currency.ETH.rawValue, "ETH")
        XCTAssertEqual(Currency.USDC.rawValue, "USDC")
        XCTAssertEqual(Currency.USDT.rawValue, "USDT")
    }
    
    // MARK: - Revenue Type Constants Tests
    
    func testRevenueTypes() {
        XCTAssertEqual(RevenueType.oneTime.rawValue, "one_time")
        XCTAssertEqual(RevenueType.subscription.rawValue, "subscription")
        XCTAssertEqual(RevenueType.inApp.rawValue, "in_app")
    }
    
    // MARK: - Authentication Method Constants Tests
    
    func testAuthMethods() {
        XCTAssertEqual(AuthMethod.password.rawValue, "password")
        XCTAssertEqual(AuthMethod.google.rawValue, "google")
        XCTAssertEqual(AuthMethod.github.rawValue, "github")
        XCTAssertEqual(AuthMethod.sso.rawValue, "sso")
        XCTAssertEqual(AuthMethod.email.rawValue, "email")
    }
    
    // MARK: - Payment Method Constants Tests
    
    func testPaymentMethods() {
        XCTAssertEqual(PaymentMethod.card.rawValue, "card")
        XCTAssertEqual(PaymentMethod.paypal.rawValue, "paypal")
        XCTAssertEqual(PaymentMethod.wire.rawValue, "wire")
        XCTAssertEqual(PaymentMethod.applePay.rawValue, "apple_pay")
        XCTAssertEqual(PaymentMethod.googlePay.rawValue, "google_pay")
        XCTAssertEqual(PaymentMethod.stripe.rawValue, "stripe")
        XCTAssertEqual(PaymentMethod.square.rawValue, "square")
        XCTAssertEqual(PaymentMethod.venmo.rawValue, "venmo")
        XCTAssertEqual(PaymentMethod.zelle.rawValue, "zelle")
        XCTAssertEqual(PaymentMethod.ach.rawValue, "ach")
        XCTAssertEqual(PaymentMethod.check.rawValue, "check")
        XCTAssertEqual(PaymentMethod.cash.rawValue, "cash")
        XCTAssertEqual(PaymentMethod.crypto.rawValue, "crypto")
        XCTAssertEqual(PaymentMethod.bankTransfer.rawValue, "bank_transfer")
        XCTAssertEqual(PaymentMethod.giftCard.rawValue, "gift_card")
        XCTAssertEqual(PaymentMethod.storeCredit.rawValue, "store_credit")
    }
    
    // MARK: - Channel Constants Tests
    
    func testChannels() {
        XCTAssertEqual(Channel.direct.rawValue, "direct")
        XCTAssertEqual(Channel.organic.rawValue, "organic")
        XCTAssertEqual(Channel.paid.rawValue, "paid")
        XCTAssertEqual(Channel.social.rawValue, "social")
        XCTAssertEqual(Channel.email.rawValue, "email")
        XCTAssertEqual(Channel.sms.rawValue, "sms")
        XCTAssertEqual(Channel.push.rawValue, "push")
        XCTAssertEqual(Channel.referral.rawValue, "referral")
        XCTAssertEqual(Channel.affiliate.rawValue, "affiliate")
        XCTAssertEqual(Channel.display.rawValue, "display")
        XCTAssertEqual(Channel.video.rawValue, "video")
        XCTAssertEqual(Channel.audio.rawValue, "audio")
        XCTAssertEqual(Channel.print.rawValue, "print")
        XCTAssertEqual(Channel.event.rawValue, "event")
        XCTAssertEqual(Channel.webinar.rawValue, "webinar")
        XCTAssertEqual(Channel.podcast.rawValue, "podcast")
    }
    
    // MARK: - Source Constants Tests
    
    func testSources() {
        XCTAssertEqual(Source.google.rawValue, "google")
        XCTAssertEqual(Source.facebook.rawValue, "facebook")
        XCTAssertEqual(Source.twitter.rawValue, "twitter")
        XCTAssertEqual(Source.linkedin.rawValue, "linkedin")
        XCTAssertEqual(Source.instagram.rawValue, "instagram")
        XCTAssertEqual(Source.youtube.rawValue, "youtube")
        XCTAssertEqual(Source.tiktok.rawValue, "tiktok")
        XCTAssertEqual(Source.snapchat.rawValue, "snapchat")
        XCTAssertEqual(Source.pinterest.rawValue, "pinterest")
        XCTAssertEqual(Source.reddit.rawValue, "reddit")
        XCTAssertEqual(Source.bing.rawValue, "bing")
        XCTAssertEqual(Source.yahoo.rawValue, "yahoo")
        XCTAssertEqual(Source.duckduckgo.rawValue, "duckduckgo")
        XCTAssertEqual(Source.newsletter.rawValue, "newsletter")
        XCTAssertEqual(Source.email.rawValue, "email")
        XCTAssertEqual(Source.blog.rawValue, "blog")
        XCTAssertEqual(Source.podcast.rawValue, "podcast")
        XCTAssertEqual(Source.webinar.rawValue, "webinar")
        XCTAssertEqual(Source.partner.rawValue, "partner")
        XCTAssertEqual(Source.affiliate.rawValue, "affiliate")
        XCTAssertEqual(Source.direct.rawValue, "direct")
        XCTAssertEqual(Source.organic.rawValue, "organic")
        XCTAssertEqual(Source.unknown.rawValue, "unknown")
    }
    
    // MARK: - Device Constants Tests
    
    func testDeviceTypes() {
        XCTAssertEqual(DeviceType.desktop.rawValue, "desktop")
        XCTAssertEqual(DeviceType.mobile.rawValue, "mobile")
        XCTAssertEqual(DeviceType.tablet.rawValue, "tablet")
        XCTAssertEqual(DeviceType.tv.rawValue, "tv")
        XCTAssertEqual(DeviceType.watch.rawValue, "watch")
        XCTAssertEqual(DeviceType.vr.rawValue, "vr")
        XCTAssertEqual(DeviceType.iot.rawValue, "iot")
        XCTAssertEqual(DeviceType.bot.rawValue, "bot")
        XCTAssertEqual(DeviceType.unknown.rawValue, "unknown")
    }
    
    // MARK: - Operating System Constants Tests
    
    func testOperatingSystems() {
        XCTAssertEqual(OperatingSystem.windows.rawValue, "windows")
        XCTAssertEqual(OperatingSystem.macOS.rawValue, "macos")
        XCTAssertEqual(OperatingSystem.linux.rawValue, "linux")
        XCTAssertEqual(OperatingSystem.iOS.rawValue, "ios")
        XCTAssertEqual(OperatingSystem.android.rawValue, "android")
        XCTAssertEqual(OperatingSystem.chromeOS.rawValue, "chromeos")
        XCTAssertEqual(OperatingSystem.fireOS.rawValue, "fireos")
        XCTAssertEqual(OperatingSystem.webOS.rawValue, "webos")
        XCTAssertEqual(OperatingSystem.tizen.rawValue, "tizen")
        XCTAssertEqual(OperatingSystem.watchOS.rawValue, "watchos")
        XCTAssertEqual(OperatingSystem.tvOS.rawValue, "tvos")
        XCTAssertEqual(OperatingSystem.playStation.rawValue, "playstation")
        XCTAssertEqual(OperatingSystem.xbox.rawValue, "xbox")
        XCTAssertEqual(OperatingSystem.unknown.rawValue, "unknown")
    }
    
    // MARK: - Browser Constants Tests
    
    func testBrowsers() {
        XCTAssertEqual(Browser.chrome.rawValue, "chrome")
        XCTAssertEqual(Browser.safari.rawValue, "safari")
        XCTAssertEqual(Browser.firefox.rawValue, "firefox")
        XCTAssertEqual(Browser.edge.rawValue, "edge")
        XCTAssertEqual(Browser.opera.rawValue, "opera")
        XCTAssertEqual(Browser.ie.rawValue, "ie")
        XCTAssertEqual(Browser.samsung.rawValue, "samsung")
        XCTAssertEqual(Browser.uc.rawValue, "uc")
        XCTAssertEqual(Browser.other.rawValue, "other")
        XCTAssertEqual(Browser.unknown.rawValue, "unknown")
    }
    
    // MARK: - Subscription Interval Constants Tests
    
    func testSubscriptionIntervals() {
        XCTAssertEqual(SubscriptionInterval.daily.rawValue, "daily")
        XCTAssertEqual(SubscriptionInterval.weekly.rawValue, "weekly")
        XCTAssertEqual(SubscriptionInterval.monthly.rawValue, "monthly")
        XCTAssertEqual(SubscriptionInterval.quarterly.rawValue, "quarterly")
        XCTAssertEqual(SubscriptionInterval.yearly.rawValue, "yearly")
        XCTAssertEqual(SubscriptionInterval.annual.rawValue, "annual")
        XCTAssertEqual(SubscriptionInterval.lifetime.rawValue, "lifetime")
        XCTAssertEqual(SubscriptionInterval.custom.rawValue, "custom")
    }
    
    // MARK: - Plan Constants Tests
    
    func testPlanTypes() {
        XCTAssertEqual(PlanType.free.rawValue, "free")
        XCTAssertEqual(PlanType.freemium.rawValue, "freemium")
        XCTAssertEqual(PlanType.basic.rawValue, "basic")
        XCTAssertEqual(PlanType.standard.rawValue, "standard")
        XCTAssertEqual(PlanType.professional.rawValue, "professional")
        XCTAssertEqual(PlanType.premium.rawValue, "premium")
        XCTAssertEqual(PlanType.enterprise.rawValue, "enterprise")
        XCTAssertEqual(PlanType.custom.rawValue, "custom")
        XCTAssertEqual(PlanType.trial.rawValue, "trial")
        XCTAssertEqual(PlanType.beta.rawValue, "beta")
    }
    
    // MARK: - Role Constants Tests
    
    func testUserRoles() {
        XCTAssertEqual(UserRole.owner.rawValue, "owner")
        XCTAssertEqual(UserRole.admin.rawValue, "admin")
        XCTAssertEqual(UserRole.manager.rawValue, "manager")
        XCTAssertEqual(UserRole.user.rawValue, "user")
        XCTAssertEqual(UserRole.guest.rawValue, "guest")
        XCTAssertEqual(UserRole.viewer.rawValue, "viewer")
        XCTAssertEqual(UserRole.editor.rawValue, "editor")
        XCTAssertEqual(UserRole.moderator.rawValue, "moderator")
        XCTAssertEqual(UserRole.support.rawValue, "support")
        XCTAssertEqual(UserRole.developer.rawValue, "developer")
        XCTAssertEqual(UserRole.analyst.rawValue, "analyst")
        XCTAssertEqual(UserRole.billing.rawValue, "billing")
    }
    
    // MARK: - Company Size Constants Tests
    
    func testCompanySizes() {
        XCTAssertEqual(CompanySize.solopreneur.rawValue, "solopreneur")
        XCTAssertEqual(CompanySize.small.rawValue, "small")
        XCTAssertEqual(CompanySize.medium.rawValue, "medium")
        XCTAssertEqual(CompanySize.large.rawValue, "large")
        XCTAssertEqual(CompanySize.enterprise.rawValue, "enterprise")
        XCTAssertEqual(CompanySize.megaCorp.rawValue, "megacorp")
        XCTAssertEqual(CompanySize.unknown.rawValue, "unknown")
    }
    
    // MARK: - Industry Constants Tests
    
    func testIndustries() {
        XCTAssertEqual(Industry.technology.rawValue, "technology")
        XCTAssertEqual(Industry.finance.rawValue, "finance")
        XCTAssertEqual(Industry.healthcare.rawValue, "healthcare")
        XCTAssertEqual(Industry.education.rawValue, "education")
        XCTAssertEqual(Industry.ecommerce.rawValue, "ecommerce")
        XCTAssertEqual(Industry.retail.rawValue, "retail")
        XCTAssertEqual(Industry.manufacturing.rawValue, "manufacturing")
        XCTAssertEqual(Industry.realEstate.rawValue, "real_estate")
        XCTAssertEqual(Industry.media.rawValue, "media")
        XCTAssertEqual(Industry.nonProfit.rawValue, "non_profit")
        XCTAssertEqual(Industry.government.rawValue, "government")
        XCTAssertEqual(Industry.consulting.rawValue, "consulting")
        XCTAssertEqual(Industry.legal.rawValue, "legal")
        XCTAssertEqual(Industry.marketing.rawValue, "marketing")
        XCTAssertEqual(Industry.other.rawValue, "other")
        XCTAssertEqual(Industry.unknown.rawValue, "unknown")
    }
    
    // MARK: - Log Level Constants Tests
    
    func testLogLevels() {
        XCTAssertEqual(LogLevel.emergency.rawValue, "emergency")
        XCTAssertEqual(LogLevel.alert.rawValue, "alert")
        XCTAssertEqual(LogLevel.critical.rawValue, "critical")
        XCTAssertEqual(LogLevel.error.rawValue, "error")
        XCTAssertEqual(LogLevel.warning.rawValue, "warning")
        XCTAssertEqual(LogLevel.notice.rawValue, "notice")
        XCTAssertEqual(LogLevel.info.rawValue, "info")
        XCTAssertEqual(LogLevel.debug.rawValue, "debug")
        XCTAssertEqual(LogLevel.trace.rawValue, "trace")
    }
    
    // MARK: - Log Event Type Constants Tests
    
    func testLogEventTypes() {
        XCTAssertEqual(LogEventType.unknown.rawValue, 0)
        XCTAssertEqual(LogEventType.log.rawValue, 1)
        XCTAssertEqual(LogEventType.enrich.rawValue, 2)
        
        // Test alias
        XCTAssertEqual(LogEventType.collect, LogEventType.log)
    }
    
    // MARK: - Enum CaseIterable Tests
    
    func testEnumCaseIterableCompliance() {
        // Verify all enums have reasonable case counts
        XCTAssertGreaterThan(Currency.allCases.count, 50) // Many currencies
        XCTAssertEqual(RevenueType.allCases.count, 3) // one_time, subscription, in_app
        XCTAssertEqual(AuthMethod.allCases.count, 5) // password, google, github, sso, email
        XCTAssertGreaterThan(PaymentMethod.allCases.count, 10) // Many payment methods
        XCTAssertGreaterThan(Channel.allCases.count, 15) // Many channels
        XCTAssertGreaterThan(Source.allCases.count, 20) // Many sources
        XCTAssertEqual(DeviceType.allCases.count, 9) // desktop, mobile, tablet, etc.
        XCTAssertEqual(OperatingSystem.allCases.count, 14) // windows, macos, linux, etc.
        XCTAssertEqual(Browser.allCases.count, 10) // chrome, safari, firefox, etc.
        XCTAssertEqual(SubscriptionInterval.allCases.count, 8) // daily, weekly, monthly, etc.
        XCTAssertEqual(PlanType.allCases.count, 10) // free, basic, premium, etc.
        XCTAssertEqual(UserRole.allCases.count, 12) // owner, admin, user, etc.
        XCTAssertEqual(CompanySize.allCases.count, 7) // solopreneur, small, medium, etc.
        XCTAssertEqual(Industry.allCases.count, 16) // technology, finance, healthcare, etc.
        XCTAssertEqual(LogLevel.allCases.count, 9) // emergency through trace
    }
    
    // MARK: - CustomStringConvertible Tests
    
    func testCustomStringDescriptions() {
        // Test that enum descriptions match their raw values
        XCTAssertEqual(RevenueType.oneTime.description, "one_time")
        XCTAssertEqual(Currency.USD.description, "USD")
        XCTAssertEqual(AuthMethod.password.description, "password")
        XCTAssertEqual(PaymentMethod.card.description, "card")
        XCTAssertEqual(Channel.direct.description, "direct")
        XCTAssertEqual(Source.google.description, "google")
        XCTAssertEqual(DeviceType.mobile.description, "mobile")
        XCTAssertEqual(OperatingSystem.iOS.description, "ios")
        XCTAssertEqual(Browser.safari.description, "safari")
        XCTAssertEqual(SubscriptionInterval.monthly.description, "monthly")
        XCTAssertEqual(PlanType.premium.description, "premium")
        XCTAssertEqual(UserRole.admin.description, "admin")
        XCTAssertEqual(CompanySize.enterprise.description, "enterprise")
        XCTAssertEqual(Industry.technology.description, "technology")
        XCTAssertEqual(LogLevel.info.description, "info")
    }
    
    // MARK: - Codable Compliance Tests
    
    func testConstantsCodableCompliance() throws {
        // Test that all constant enums can be encoded and decoded
        
        let revenueType = RevenueType.subscription
        let revenueData = try JSONEncoder().encode(revenueType)
        let decodedRevenue = try JSONDecoder().decode(RevenueType.self, from: revenueData)
        XCTAssertEqual(revenueType, decodedRevenue)
        
        let currency = Currency.EUR
        let currencyData = try JSONEncoder().encode(currency)
        let decodedCurrency = try JSONDecoder().decode(Currency.self, from: currencyData)
        XCTAssertEqual(currency, decodedCurrency)
        
        let authMethod = AuthMethod.google
        let authData = try JSONEncoder().encode(authMethod)
        let decodedAuth = try JSONDecoder().decode(AuthMethod.self, from: authData)
        XCTAssertEqual(authMethod, decodedAuth)
        
        let logLevel = LogLevel.warning
        let logData = try JSONEncoder().encode(logLevel)
        let decodedLog = try JSONDecoder().decode(LogLevel.self, from: logData)
        XCTAssertEqual(logLevel, decodedLog)
    }
    
    // MARK: - Constants Coverage Tests
    
    func testConstantsCoverage() {
        // Ensure we have comprehensive coverage of all major constant categories
        
        // Event names should cover all major user journey points
        let eventNames = EventName.allCases
        let eventNameStrings = eventNames.map { $0.stringValue }
        
        XCTAssertTrue(eventNameStrings.contains("user_signed_up"))
        XCTAssertTrue(eventNameStrings.contains("order_completed"))
        XCTAssertTrue(eventNameStrings.contains("subscription_started"))
        XCTAssertTrue(eventNameStrings.contains("page_viewed"))
        XCTAssertTrue(eventNameStrings.contains("feature_used"))
        XCTAssertTrue(eventNameStrings.contains("trial_started"))
        XCTAssertTrue(eventNameStrings.contains("support_ticket_created"))
        
        // Currencies should include major global currencies and crypto
        let currencies = Currency.allCases
        let currencyStrings = currencies.map { $0.rawValue }
        
        XCTAssertTrue(currencyStrings.contains("USD"))
        XCTAssertTrue(currencyStrings.contains("EUR"))
        XCTAssertTrue(currencyStrings.contains("BTC"))
        XCTAssertTrue(currencyStrings.contains("ETH"))
        
        // Payment methods should cover common payment options
        let paymentMethods = PaymentMethod.allCases
        let paymentStrings = paymentMethods.map { $0.rawValue }
        
        XCTAssertTrue(paymentStrings.contains("card"))
        XCTAssertTrue(paymentStrings.contains("paypal"))
        XCTAssertTrue(paymentStrings.contains("apple_pay"))
        XCTAssertTrue(paymentStrings.contains("crypto"))
    }
}