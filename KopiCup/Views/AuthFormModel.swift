import Foundation
import Combine
import FirebaseAuth

@MainActor
final class AuthFormModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var rememberMe: Bool = false
    @Published var didTapSubmit: Bool = false
    @Published var isLoading: Bool = false
    @Published var firebaseError: String? = nil
    
    private func validateEmailError() -> String? {
        let trimmed = email.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            return "х Пожалуйста, введите Email"
        }

        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)

        guard predicate.evaluate(with: trimmed) else {
            return "х Пожалуйста, введите корректный Email"
        }

        return nil
    }

    private func validatePasswordError() -> String? {
        guard !password.isEmpty else {
            return "х Пожалуйста, введите пароль"
        }
        return nil
    }
    
    var hasLocalValidationErrors: Bool {
        validateEmailError() != nil || validatePasswordError() != nil
    }
    
    var isFormFilled: Bool {
        !email.isEmpty && !password.isEmpty
    }
    
    var displayErrorForEmail: String? {
        validateEmailError()
    }

    var displayErrorForPassword: String? {
        validatePasswordError()
    }
    
    func signIn(onSuccess: @escaping () -> Void) {
        didTapSubmit = true
        firebaseError = nil

        if hasLocalValidationErrors { return }

        isLoading = true
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)

        Task {
            do {
                _ = try await Auth.auth().signIn(withEmail: trimmedEmail, password: password)
                isLoading = false
                onSuccess()
            } catch {
                isLoading = false
                firebaseError = Self.humanAuthError(error)
            }
        }
    }
    
    private static func humanAuthError(_ error: Error) -> String {
        let ns = error as NSError
        let code = AuthErrorCode(_nsError: ns).code

        switch code {
        case .invalidEmail:
            return "Некорректный email."
        case .invalidCredential:
            return "Неверный email или пароль."
        case .userNotFound:
            return "Пользователь не найден."
        case .wrongPassword:
            return "Неверный пароль."
        case .userDisabled:
            return "Аккаунт отключён."
        case .operationNotAllowed:
            return "Вход по email/паролю не включён в Firebase."
        case .networkError:
            return "Проблемы с интернетом."
        case .tooManyRequests:
            return "Слишком много попыток. Попробуйте позже."
        default:
            return "Не удалось войти. Проверьте данные и попробуйте ещё раз."
        }
    }

}
