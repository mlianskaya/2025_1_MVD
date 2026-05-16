import SwiftUI
import FirebaseAuth

struct RegView: View {
    let onRegSuccess: () -> Void

    @StateObject private var form = RegFormModel()
    @State private var showFirebaseError = false

    @EnvironmentObject private var userStorage: UserStorage
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Image("background")
                    .resizable()
                    .scaledToFill()
                    .opacity(0.2)
                    .overlay(
                        LinearGradient(
                            colors: [
                                Color(red: 102/255, green: 190/255, blue: 0).opacity(0.3),
                                Color(red: 78/255, green: 146/255, blue: 0).opacity(0.3)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .ignoresSafeArea()

                VStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(red: 112/255, green: 154/255, blue: 69/255))
                            .frame(width: 89, height: 89)
                            .offset(y: 5)

                        Image("logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 89, height: 89)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    Text("Создайте свою копилку мечты!")
                        .font(.system(size: 18, design: .rounded))
                        .bold()

                    Text("Ваша цель ждет - начните копить уже сегодня")
                        .multilineTextAlignment(.center)
                        .font(.system(size: 13, design: .rounded))
                        .bold()
                        .foregroundColor(Color.secondary)

                    formFields

                    if form.isLoading {
                        ProgressView()
                            .padding(.top, 20)
                    }
                }
                .padding()
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 36)
                .padding(.vertical, 16)
            }
            .alert("Ошибка регистрации", isPresented: $showFirebaseError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(form.errorMessage ?? "Неизвестная ошибка")
            }
        }
    }

    private var formFields: some View {
        VStack(spacing: 16) {
            LabeledTextField(
                title: "Email",
                placeholder: "email@example.com",
                iconName: "at",
                text: $form.email,
                error: form.didTapSubmit ? form.emailError : nil
            )

            LabeledSecureField(
                title: "Придумайте пароль",
                placeholder: "Создайте надежный пароль",
                iconName: "lock",
                text: $form.password,
                error: form.didTapSubmit ? form.passwordError : nil
            )

            LabeledSecureField(
                title: "Подтверждение пароля",
                placeholder: "Повторите пароль",
                iconName: "checkmark.circle",
                text: $form.confirmedPassword,
                error: form.didTapSubmit ? form.confirmedPasswordError : nil
            )

            GreenButton(
                title: form.isLoading ? "Регистрация..." : "Старт к мечте!",
                isDisabled: !form.isFormFilled || form.isLoading
            ) {
                form.didTapSubmit = true
                if form.isFormValid {
                    registerWithFirebase()
                }
            }
            .padding(.top, 8)

            socialLoginSection
                .padding(.top, 4)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var socialLoginSection: some View {
        VStack(spacing: 12) {
            HStack {
                Rectangle().frame(height: 1).foregroundColor(.gray.opacity(0.3))

                Text("или войдите через")
                    .font(.system(size: 11, design: .rounded))
                    .bold()
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .layoutPriority(1)

                Rectangle().frame(height: 1).foregroundColor(.gray.opacity(0.3))
            }

            HStack(spacing: 12) {
                Button(action: {
                    // TODO: Google
                }) {
                    HStack(spacing: 8) {
                        Image("Google")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                        Text("Google")
                    }
                    .foregroundColor(.black)
                    .font(.system(size: 14, design: .rounded))
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.secondary, lineWidth: 2)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Button(action: {
                    // TODO: VK ID
                }) {
                    HStack(spacing: 8) {
                        Image("VK")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                        Text("VK ID")
                    }
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.black)
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.secondary, lineWidth: 2)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Button(action: {
                    // TODO: Apple
                }) {
                    HStack(spacing: 8) {
                        Image("Apple")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                        Text("Apple")
                    }
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.black)
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.secondary, lineWidth: 2)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }

            HStack {
                Text("Уже есть аккаунт?")
                Button("Войти") {
                    dismiss()
                }
            }
            .font(.system(size: 14, design: .rounded))
            .bold()
            .padding(.top, 12)
        }
    }

    private func registerWithFirebase() {
        guard form.password == form.confirmedPassword else {
            form.errorMessage = "Пароли не совпадают"
            showFirebaseError = true
            return
        }

        form.isLoading = true

        Auth.auth().createUser(
            withEmail: form.email.trimmingCharacters(in: .whitespaces),
            password: form.password
        ) { _, error in
            form.isLoading = false

            if let error = error {
                form.errorMessage = convertFirebaseError(error)
                showFirebaseError = true
            } else {
                if let creationDate = Auth.auth().currentUser?.metadata.creationDate {
                    userStorage.registrationDate = creationDate
                }

                onRegSuccess()
                dismiss()
            }
        }
    }

    private func convertFirebaseError(_ error: Error) -> String {
        let nsError = error as NSError
        switch nsError.code {
        case AuthErrorCode.emailAlreadyInUse.rawValue:
            return "Этот email уже используется"
        case AuthErrorCode.invalidEmail.rawValue:
            return "Неверный формат email"
        case AuthErrorCode.weakPassword.rawValue:
            return "Слишком слабый пароль. Используйте минимум 8 символов с цифрами и заглавными буквами"
        case AuthErrorCode.networkError.rawValue:
            return "Проблемы с сетью. Проверьте подключение к интернету"
        default:
            return error.localizedDescription
        }
    }
}

struct RegView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            RegView(onRegSuccess: {})
                .environmentObject(UserStorage())
        }
    }
}
