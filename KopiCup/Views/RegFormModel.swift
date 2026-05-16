import Foundation
import Combine
import FirebaseAuth

@MainActor
final class RegFormModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmedPassword: String = ""
    @Published var didTapSubmit: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    var emailError: String? {
        let trimmed = email.trimmingCharacters(in: .whitespaces)
        let error = "х Пожалуйста, введите корректный Email"
        guard !trimmed.contains(" ") else { return error }

        let parts = trimmed.split(separator: "@")
        guard parts.count == 2 else { return error }

        guard !parts[0].isEmpty, !parts[1].isEmpty else { return error }
        guard parts[0].first != ".", parts[1].first != "." else { return error }
        guard parts[0].last != ".", parts[1].last != "." else { return error }

        return nil
    }

    private var isEmailValid: Bool {
        emailError == nil
    }

    var passwordError: String? {
        let hasUpperCase = password.contains(where: { $0.isUppercase })
        let hasDigit = password.contains(where: { $0.isNumber })
        if password.count < 8 || !hasUpperCase || !hasDigit {
            return "х Пароль должен быть не менее 8 символов, содержать цифру и заглавную букву"
        }
        return nil
    }

    private var isPasswordValid: Bool {
        passwordError == nil
    }

    var confirmedPasswordError: String? {
        if password != confirmedPassword {
            return "х Пароли не совпадают"
        }
        return nil
    }

    private var isConfirmedPasswordValid: Bool {
        confirmedPasswordError == nil
    }

    var isFormFilled: Bool {
        !email.isEmpty && !password.isEmpty && !confirmedPassword.isEmpty
    }

    var isFormValid: Bool {
        isEmailValid && isPasswordValid && isConfirmedPasswordValid
    }
    
    func signUp(onSuccess: @escaping () -> Void) {
        didTapSubmit = true
        errorMessage = nil

        guard isFormValid else { return }

        isLoading = true
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)

        Task {
            do {
                _ = try await Auth.auth().createUser(withEmail: trimmedEmail, password: password)
                isLoading = false
                onSuccess()
            } catch {
                isLoading = false
                errorMessage = Self.humanSignUpError(error)
            }
        }
    }

    private static func humanSignUpError(_ error: Error) -> String {
        let ns = error as NSError
        let code = AuthErrorCode(_nsError: ns).code

        switch code {
        case .emailAlreadyInUse:
            return "Этот email уже зарегистрирован."
        case .invalidEmail:
            return "Некорректный email."
        case .weakPassword:
            return "Слишком простой пароль."
        case .networkError:
            return "Проблемы с интернетом. Попробуйте позже"
        default:
            return ns.localizedDescription
        }
    }
}
