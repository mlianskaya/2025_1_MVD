//
//  Number+CurrencyFormatter.swift
//  KopiCup
//
//  Created by Павел Гордиенко on 12/23/25.
//

import SwiftUI
import Combine

struct CurrencyFormatter {
    // Старый форматтер оставим для обратной совместимости,
    // но использовать будем новые методы с кодом валюты.
    static let shared: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    // Новый универсальный форматтер с явным кодом валюты
    static func format(_ amount: Double, code: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.currencyCode = code
        formatter.maximumFractionDigits = 0
        if let str = formatter.string(from: NSNumber(value: amount)) {
            return str
        } else {
            return "\(Int(amount)) \(currencySymbol(for: code) ?? code)"
        }
    }

    // Для старых вызовов — читаем текущую валюту из UserDefaults
    static func format(_ amount: Double) -> String {
        let code = UserDefaults.standard.string(forKey: "settings.currency.code") ?? "RUB"
        return format(amount, code: code)
    }

    private static func currencySymbol(for code: String) -> String? {
        Locale.availableIdentifiers
            .map(Locale.init(identifier:))
            .first { $0.currencyCode == code }?
            .currencySymbol
    }
}
