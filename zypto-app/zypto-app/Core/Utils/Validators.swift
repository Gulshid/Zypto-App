//
//  Validators.swift
//  FoodDeliveryApp
//
//  Small, dependency-free form validation helpers shared by
//  Login / Signup / Forgot Password screens.
//
//  Location in project: Core/Utils/Validators.swift
//
//  UPDATED IN PHASE 5: added mock-payment field validators for the
//  Checkout screen. These only check *shape* (digit counts, MM/YY
//  format) — there is no real payment processor behind this, per the
//  roadmap's "fake card form -> simulated success" design.
//

import Foundation

enum Validators {

    static func isValidEmail(_ email: String) -> Bool {
        let regex = #"^[\w.+-]+@[\w-]+\.[A-Za-z]{2,}$"#
        return email.range(of: regex, options: .regularExpression) != nil
    }

    /// Firebase Auth itself rejects passwords under 6 characters, so this
    /// just catches the error earlier with a friendlier inline message.
    static func isValidPassword(_ password: String) -> Bool {
        password.count >= 6
    }

    /// Non-empty after trimming — used for delivery address and the
    /// name-on-card field, where any real-looking text is acceptable.
    static func isNonEmpty(_ text: String) -> Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Accepts 13–19 digits (covers Visa/Mastercard/Amex lengths), spaces
    /// allowed between groups since the Checkout form auto-inserts them.
    static func isValidCardNumber(_ number: String) -> Bool {
        let digits = number.filter(\.isNumber)
        return digits.count >= 13 && digits.count <= 19
    }

    /// Strict MM/YY shape, and not already expired.
    static func isValidExpiry(_ expiry: String) -> Bool {
        let parts = expiry.split(separator: "/")
        guard parts.count == 2,
              let month = Int(parts[0]), (1...12).contains(month),
              let year = Int(parts[1]) else { return false }

        let calendar = Calendar.current
        let now = Date()
        let currentYear = calendar.component(.year, from: now) % 100
        let currentMonth = calendar.component(.month, from: now)

        if year > currentYear { return true }
        if year == currentYear { return month >= currentMonth }
        return false
    }

    /// 3 digits for Visa/Mastercard, 4 for Amex — this project doesn't
    /// distinguish card networks, so either length is accepted.
    static func isValidCVV(_ cvv: String) -> Bool {
        let digits = cvv.filter(\.isNumber)
        return digits.count == 3 || digits.count == 4
    }
}
