import Foundation

enum L10n {
    enum Auth {
        enum Password {
            static let tooWeak = String(localized: "auth.password.error.too_weak")
            static func tooShort(_ min: Int) -> String {
                // Localize a format string like: "Password must be at least %d characters."
                let format = NSLocalizedString("auth.password.error.too_short",
                                               comment: "Password too short format")
                return String(format: format, locale: .current, min)
            }
        }
        enum Email {
            static let invalid = String(localized: "auth.email.error.invalid")
        }
        enum ConfirmPassword {
            static let mismatch = String(localized: "auth.password.error.mismatch")
        }
    }
}
