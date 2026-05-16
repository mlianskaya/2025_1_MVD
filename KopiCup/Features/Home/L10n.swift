import Foundation
import SwiftUI
import Combine

enum AppLanguage: String, CaseIterable {
    case ru, en
}

final class L10n: ObservableObject {
    static let shared = L10n()
    @Published var language: AppLanguage

    private var cancellable: AnyCancellable?

    private init() {
        let code = UserDefaults.standard.string(forKey: "settings.language.code") ?? "ru"
        language = AppLanguage(rawValue: code) ?? .ru

        // Listen for UserDefaults changes for language
        cancellable = UserDefaults.standard.publisher(for: \.settingsLanguageCode)
            .sink { [weak self] newValue in
                guard let self else { return }
                self.language = AppLanguage(rawValue: newValue ?? "ru") ?? .ru
            }
    }

    func t(_ key: Key, _ args: CVarArg...) -> String {
        let format = translations[language]?[key.rawValue] ?? key.rawValue
        if args.isEmpty { return format }
        else { return String(format: format, arguments: args) }
    }

    enum Key: String {
        case weeklySaved = "home.weekly.saved"
        case keepGoing = "home.keep.going"
        case noGoal = "home.alert.no_goal_title"
        case ok
        case profileAchievements = "profile.achievements"
        case profileSettings = "profile.settings"
        case darkTheme = "profile.dark_theme"
        case currency = "profile.currency"
        case language = "profile.language"
        case logout = "profile.logout"
        case logoutConfirm = "profile.logout.confirm"
        case logoutReturn = "profile.logout.return"
        // Weekday short names
        case mon = "weekday.mon"
        case tue = "weekday.tue"
        case wed = "weekday.wed"
        case thu = "weekday.thu"
        case fri = "weekday.fri"
        case sat = "weekday.sat"
        case sun = "weekday.sun"
        // ... добавьте остальные ключи по необходимости
    }

    private let translations: [AppLanguage: [String: String]] = [
        .ru: [
            "home.weekly.saved": "На этой неделе накоплено:\n%@",
            "home.keep.going": "Так держать!",
            "home.alert.no_goal_title": "Сначала добавьте цель!",
            "ok": "Ок",
            "profile.achievements": "Достижения",
            "profile.settings": "Настройки",
            "profile.dark_theme": "Темная тема",
            "profile.currency": "Валюта",
            "profile.language": "Язык",
            "profile.logout": "Выйти из аккаунта",
            "profile.logout.confirm": "Вы действительно хотите выйти?",
            "profile.logout.return": "Вы вернётесь на экран входа.",
            // Weekday short names (ru)
            "weekday.mon": "Пн",
            "weekday.tue": "Вт",
            "weekday.wed": "Ср",
            "weekday.thu": "Чт",
            "weekday.fri": "Пт",
            "weekday.sat": "Сб",
            "weekday.sun": "Вс"
        ],
        .en: [
            "home.weekly.saved": "Saved this week:\n%@",
            "home.keep.going": "Keep it up!",
            "home.alert.no_goal_title": "Add a goal first!",
            "ok": "OK",
            "profile.achievements": "Achievements",
            "profile.settings": "Settings",
            "profile.dark_theme": "Dark theme",
            "profile.currency": "Currency",
            "profile.language": "Language",
            "profile.logout": "Sign out",
            "profile.logout.confirm": "Are you sure you want to log out?",
            "profile.logout.return": "You will return to the login screen.",
            // Weekday short names (en)
            "weekday.mon": "Mon",
            "weekday.tue": "Tue",
            "weekday.wed": "Wed",
            "weekday.thu": "Thu",
            "weekday.fri": "Fri",
            "weekday.sat": "Sat",
            "weekday.sun": "Sun"
        ]
    ]
}

extension UserDefaults {
    @objc dynamic var settingsLanguageCode: String? {
        string(forKey: "settings.language.code")
    }
}
