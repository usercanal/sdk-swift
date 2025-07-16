// Currency.swift
// UserCanal Swift SDK
//
// Copyright © 2024 UserCanal. All rights reserved.
//

import Foundation

// MARK: - Currency

/// Represents currency codes for revenue tracking
public struct Currency: Sendable, Hashable, Codable {
    
    // MARK: - Storage
    
    private let code: String
    
    // MARK: - Initialization
    
    /// Create a currency from a string code
    public init(_ code: String) {
        self.code = code.uppercased()
    }
    
    /// Create a currency from a string literal
    public init(stringLiteral value: String) {
        self.code = value.uppercased()
    }
    
    // MARK: - Properties
    
    /// The ISO 4217 currency code
    public var currencyCode: String {
        return code
    }
    
    /// Check if this is a supported major currency
    public var isMajorCurrency: Bool {
        return Self.majorCurrencies.contains(self)
    }
    
    /// Check if this is a cryptocurrency
    public var isCryptocurrency: Bool {
        return Self.cryptocurrencies.contains(self)
    }
}

// MARK: - Major Global Currencies

extension Currency {
    
    /// US Dollar
    public static let usd = Currency("USD")
    
    /// Euro
    public static let eur = Currency("EUR")
    
    /// British Pound Sterling
    public static let gbp = Currency("GBP")
    
    /// Japanese Yen
    public static let jpy = Currency("JPY")
    
    /// Canadian Dollar
    public static let cad = Currency("CAD")
    
    /// Australian Dollar
    public static let aud = Currency("AUD")
    
    /// New Zealand Dollar
    public static let nzd = Currency("NZD")
    
    /// South Korean Won
    public static let krw = Currency("KRW")
    
    /// Chinese Yuan
    public static let cny = Currency("CNY")
    
    /// Hong Kong Dollar
    public static let hkd = Currency("HKD")
    
    /// Singapore Dollar
    public static let sgd = Currency("SGD")
    
    /// Mexican Peso
    public static let mxn = Currency("MXN")
    
    /// Indian Rupee
    public static let inr = Currency("INR")
    
    /// Polish Zloty
    public static let pln = Currency("PLN")
    
    /// Brazilian Real
    public static let brl = Currency("BRL")
    
    /// Russian Ruble
    public static let rub = Currency("RUB")
    
    /// Danish Krone
    public static let dkk = Currency("DKK")
    
    /// Norwegian Krone
    public static let nok = Currency("NOK")
    
    /// Swedish Krona
    public static let sek = Currency("SEK")
    
    /// Swiss Franc
    public static let chf = Currency("CHF")
    
    /// Turkish Lira
    public static let try_ = Currency("TRY")
    
    /// Israeli Shekel
    public static let ils = Currency("ILS")
    
    /// Thai Baht
    public static let thb = Currency("THB")
    
    /// Malaysian Ringgit
    public static let myr = Currency("MYR")
    
    /// Indonesian Rupiah
    public static let idr = Currency("IDR")
    
    /// Vietnamese Dong
    public static let vnd = Currency("VND")
    
    /// Philippine Peso
    public static let php = Currency("PHP")
    
    /// Czech Koruna
    public static let czk = Currency("CZK")
    
    /// Hungarian Forint
    public static let huf = Currency("HUF")
    
    /// South African Rand
    public static let zar = Currency("ZAR")
}

// MARK: - Latin American Currencies

extension Currency {
    
    /// Argentine Peso
    public static let ars = Currency("ARS")
    
    /// Chilean Peso
    public static let clp = Currency("CLP")
    
    /// Colombian Peso
    public static let cop = Currency("COP")
    
    /// Peruvian Sol
    public static let pen = Currency("PEN")
    
    /// Uruguayan Peso
    public static let uyu = Currency("UYU")
}

// MARK: - Middle Eastern Currencies

extension Currency {
    
    /// Egyptian Pound
    public static let egp = Currency("EGP")
    
    /// UAE Dirham
    public static let aed = Currency("AED")
    
    /// Saudi Riyal
    public static let sar = Currency("SAR")
    
    /// Qatari Riyal
    public static let qar = Currency("QAR")
    
    /// Bahraini Dinar
    public static let bhd = Currency("BHD")
    
    /// Kuwaiti Dinar
    public static let kwd = Currency("KWD")
    
    /// Omani Rial
    public static let omr = Currency("OMR")
    
    /// Jordanian Dinar
    public static let jod = Currency("JOD")
    
    /// Lebanese Pound
    public static let lbp = Currency("LBP")
}

// MARK: - Eastern European Currencies

extension Currency {
    
    /// Romanian Leu
    public static let ron = Currency("RON")
    
    /// Bulgarian Lev
    public static let bgn = Currency("BGN")
    
    /// Croatian Kuna
    public static let hrk = Currency("HRK")
    
    /// Serbian Dinar
    public static let rsd = Currency("RSD")
    
    /// Bosnia and Herzegovina Mark
    public static let bam = Currency("BAM")
    
    /// Macedonian Denar
    public static let mkd = Currency("MKD")
    
    /// Albanian Lek
    public static let all = Currency("ALL")
    
    /// Ukrainian Hryvnia
    public static let uah = Currency("UAH")
    
    /// Belarusian Ruble
    public static let byn = Currency("BYN")
    
    /// Moldovan Leu
    public static let mdl = Currency("MDL")
}

// MARK: - Caucasus & Central Asian Currencies

extension Currency {
    
    /// Georgian Lari
    public static let gel = Currency("GEL")
    
    /// Armenian Dram
    public static let amd = Currency("AMD")
    
    /// Azerbaijani Manat
    public static let azn = Currency("AZN")
    
    /// Kazakhstani Tenge
    public static let kzt = Currency("KZT")
    
    /// Uzbekistani Som
    public static let uzs = Currency("UZS")
    
    /// Kyrgyzstani Som
    public static let kgs = Currency("KGS")
    
    /// Tajikistani Somoni
    public static let tjs = Currency("TJS")
    
    /// Turkmenistani Manat
    public static let tmt = Currency("TMT")
    
    /// Mongolian Tugrik
    public static let mnt = Currency("MNT")
}

// MARK: - Cryptocurrencies

extension Currency {
    
    /// Bitcoin
    public static let btc = Currency("BTC")
    
    /// Ethereum
    public static let eth = Currency("ETH")
    
    /// USD Coin
    public static let usdc = Currency("USDC")
    
    /// Tether
    public static let usdt = Currency("USDT")
}

// MARK: - Currency Collections

extension Currency {
    
    /// Major global currencies
    public static let majorCurrencies: Set<Currency> = [
        .usd, .eur, .gbp, .jpy, .cad, .aud, .nzd, .krw, .cny, .hkd,
        .sgd, .mxn, .inr, .pln, .brl, .rub, .dkk, .nok, .sek, .chf
    ]
    
    /// Cryptocurrencies
    public static let cryptocurrencies: Set<Currency> = [
        .btc, .eth, .usdc, .usdt
    ]
    
    /// All supported currencies
    public static let allSupportedCurrencies: Set<Currency> = [
        // Major Global
        .usd, .eur, .gbp, .jpy, .cad, .aud, .nzd, .krw, .cny, .hkd,
        .sgd, .mxn, .inr, .pln, .brl, .rub, .dkk, .nok, .sek, .chf,
        .try_, .ils, .thb, .myr, .idr, .vnd, .php, .czk, .huf, .zar,
        
        // Latin American
        .ars, .clp, .cop, .pen, .uyu,
        
        // Middle Eastern
        .egp, .aed, .sar, .qar, .bhd, .kwd, .omr, .jod, .lbp,
        
        // Eastern European
        .ron, .bgn, .hrk, .rsd, .bam, .mkd, .all, .uah, .byn, .mdl,
        
        // Caucasus & Central Asian
        .gel, .amd, .azn, .kzt, .uzs, .kgs, .tjs, .tmt, .mnt,
        
        // Cryptocurrencies
        .btc, .eth, .usdc, .usdt
    ]
}

// MARK: - Currency Information

extension Currency {
    
    /// Information about a currency
    public struct Info: Sendable {
        public let name: String
        public let symbol: String
        public let decimalPlaces: Int
        public let region: String
        
        public init(name: String, symbol: String, decimalPlaces: Int = 2, region: String) {
            self.name = name
            self.symbol = symbol
            self.decimalPlaces = decimalPlaces
            self.region = region
        }
    }
    
    /// Get detailed information about this currency
    public var info: Info? {
        return Self.currencyInfo[self]
    }
    
    /// Currency symbol (e.g., "$", "€", "£")
    public var symbol: String {
        return info?.symbol ?? code
    }
    
    /// Currency name (e.g., "US Dollar", "Euro")
    public var name: String {
        return info?.name ?? code
    }
    
    /// Number of decimal places typically used
    public var decimalPlaces: Int {
        return info?.decimalPlaces ?? 2
    }
    
    /// Geographic region
    public var region: String {
        return info?.region ?? "Unknown"
    }
    
    /// Static currency information database
    private static let currencyInfo: [Currency: Info] = [
        // Major Global Currencies
        .usd: Info(name: "US Dollar", symbol: "$", region: "United States"),
        .eur: Info(name: "Euro", symbol: "€", region: "European Union"),
        .gbp: Info(name: "British Pound Sterling", symbol: "£", region: "United Kingdom"),
        .jpy: Info(name: "Japanese Yen", symbol: "¥", decimalPlaces: 0, region: "Japan"),
        .cad: Info(name: "Canadian Dollar", symbol: "C$", region: "Canada"),
        .aud: Info(name: "Australian Dollar", symbol: "A$", region: "Australia"),
        .nzd: Info(name: "New Zealand Dollar", symbol: "NZ$", region: "New Zealand"),
        .krw: Info(name: "South Korean Won", symbol: "₩", decimalPlaces: 0, region: "South Korea"),
        .cny: Info(name: "Chinese Yuan", symbol: "¥", region: "China"),
        .hkd: Info(name: "Hong Kong Dollar", symbol: "HK$", region: "Hong Kong"),
        .sgd: Info(name: "Singapore Dollar", symbol: "S$", region: "Singapore"),
        .mxn: Info(name: "Mexican Peso", symbol: "$", region: "Mexico"),
        .inr: Info(name: "Indian Rupee", symbol: "₹", region: "India"),
        .pln: Info(name: "Polish Zloty", symbol: "zł", region: "Poland"),
        .brl: Info(name: "Brazilian Real", symbol: "R$", region: "Brazil"),
        .rub: Info(name: "Russian Ruble", symbol: "₽", region: "Russia"),
        .dkk: Info(name: "Danish Krone", symbol: "kr", region: "Denmark"),
        .nok: Info(name: "Norwegian Krone", symbol: "kr", region: "Norway"),
        .sek: Info(name: "Swedish Krona", symbol: "kr", region: "Sweden"),
        .chf: Info(name: "Swiss Franc", symbol: "CHF", region: "Switzerland"),
        .try_: Info(name: "Turkish Lira", symbol: "₺", region: "Turkey"),
        .ils: Info(name: "Israeli Shekel", symbol: "₪", region: "Israel"),
        .thb: Info(name: "Thai Baht", symbol: "฿", region: "Thailand"),
        .myr: Info(name: "Malaysian Ringgit", symbol: "RM", region: "Malaysia"),
        .idr: Info(name: "Indonesian Rupiah", symbol: "Rp", decimalPlaces: 0, region: "Indonesia"),
        .vnd: Info(name: "Vietnamese Dong", symbol: "₫", decimalPlaces: 0, region: "Vietnam"),
        .php: Info(name: "Philippine Peso", symbol: "₱", region: "Philippines"),
        .czk: Info(name: "Czech Koruna", symbol: "Kč", region: "Czech Republic"),
        .huf: Info(name: "Hungarian Forint", symbol: "Ft", decimalPlaces: 0, region: "Hungary"),
        .zar: Info(name: "South African Rand", symbol: "R", region: "South Africa"),
        
        // Cryptocurrencies
        .btc: Info(name: "Bitcoin", symbol: "₿", decimalPlaces: 8, region: "Global"),
        .eth: Info(name: "Ethereum", symbol: "Ξ", decimalPlaces: 18, region: "Global"),
        .usdc: Info(name: "USD Coin", symbol: "USDC", decimalPlaces: 6, region: "Global"),
        .usdt: Info(name: "Tether", symbol: "₮", decimalPlaces: 6, region: "Global")
    ]
}

// MARK: - Protocol Conformances

extension Currency: ExpressibleByStringLiteral {
    public typealias StringLiteralType = String
}

extension Currency: CustomStringConvertible {
    public var description: String {
        return code
    }
}

extension Currency: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "Currency(\"\(code)\")"
    }
}

extension Currency: Comparable {
    public static func < (lhs: Currency, rhs: Currency) -> Bool {
        return lhs.code < rhs.code
    }
}

// MARK: - Codable Implementation

extension Currency {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let code = try container.decode(String.self)
        self.init(code)
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(code)
    }
}

// MARK: - Validation

extension Currency {
    
    /// Validate that this is a supported currency
    public func validate() throws {
        guard !code.isEmpty else {
            throw UserCanalError.validationError(field: "currency", reason: "Currency code cannot be empty")
        }
        
        guard code.count == 3 || code.count == 4 else {
            throw UserCanalError.validationError(field: "currency", reason: "Currency code must be 3 or 4 characters")
        }
        
        guard code.allSatisfy({ $0.isLetter || $0.isNumber }) else {
            throw UserCanalError.validationError(field: "currency", reason: "Currency code must contain only letters and numbers")
        }
    }
}

// MARK: - Convenience Methods

extension Currency {
    
    /// Format an amount with this currency
    public func format(amount: Double, locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.locale = locale
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = decimalPlaces
        
        return formatter.string(from: NSNumber(value: amount)) ?? "\(symbol)\(amount)"
    }
    
    /// Create a formatted currency string
    public func formattedAmount(_ amount: Double) -> String {
        return format(amount: amount)
    }
}