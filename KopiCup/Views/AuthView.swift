import SwiftUI
import FirebaseAuth

struct AuthView: View {
    let onAuthSuccess: () -> Void

    @StateObject private var authForm = AuthFormModel()
    @State private var isRegViewPresented = false
    @State private var showResetPassword = false

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

                    Text("С возвращением к твоей цели!")
                        .font(.system(size: 18, design: .rounded))
                        .bold()

                    Text("Подтверди твои намерения")
                        .multilineTextAlignment(.center)
                        .font(.system(size: 13, design: .rounded))
                        .bold()
                        .foregroundColor(Color.secondary)

                    formFields

                    if authForm.isLoading {
                        ProgressView()
                            .padding(.top, 20)
                    }

                    if let firebaseError = authForm.firebaseError,
                       !firebaseError.contains("email") &&
                       !firebaseError.contains("пароль") &&
                       !firebaseError.contains("пользователь") &&
                       !firebaseError.contains("password") {
                        Text(firebaseError)
                            .font(.system(size: 11, design: .rounded))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                    }
                }
                .padding()
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 36)
                .padding(.vertical, 16)
            }
            .sheet(isPresented: $showResetPassword) {
                ResetPasswordView()
            }
            .fullScreenCover(isPresented: $isRegViewPresented) {
                RegView(onRegSuccess: {
                    onAuthSuccess()
                    dismiss()
                })
                .environmentObject(userStorage)
            }
            .navigationBarBackButtonHidden(true)
        }
    }

    private var formFields: some View {
        VStack(spacing: 20) {
            LabeledTextField(
                title: "Email",
                placeholder: "email@example.com",
                iconName: "at",
                text: $authForm.email,
                error: authForm.didTapSubmit ? authForm.displayErrorForEmail : nil
            )

            LabeledSecureField(
                title: "Пароль",
                placeholder: "Введите пароль",
                iconName: "lock",
                text: $authForm.password,
                error: authForm.didTapSubmit ? authForm.displayErrorForPassword : nil
            )

            HStack {
                Checkbox(isOn: $authForm.rememberMe, label: "Запомнить меня")
                Spacer()
                Button("Забыли пароль?") {
                    showResetPassword = true
                }
                .font(.system(size: 14, design: .rounded))
                .bold()
                .foregroundColor(.blue)
            }

            GreenButton(
                title: authForm.isLoading ? "Вход..." : "Начать копить",
                isDisabled: !authForm.isFormFilled || authForm.isLoading
            ) {
                authForm.signIn {
                    if let creationDate = Auth.auth().currentUser?.metadata.creationDate {
                        userStorage.registrationDate = creationDate
                    }

                    onAuthSuccess()
                    dismiss()
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
                Text("Нет аккаунта?")
                Button("Зарегистрироваться") {
                    isRegViewPresented = true
                }
            }
            .font(.system(size: 14, design: .rounded))
            .bold()
            .padding(.top, 12)
        }
    }
}

struct Checkbox: View {
    @Binding var isOn: Bool
    var label: String

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isOn ? "checkmark.square.fill" : "square")
                    .font(.system(size: 20))
                    .foregroundColor(.secondary)

                Text(label)
                    .foregroundColor(.primary)
                    .font(.system(size: 14, design: .rounded))
                    .bold()
            }
        }
        .buttonStyle(.plain)
    }
}

struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AuthView(onAuthSuccess: {})
                .environmentObject(UserStorage())
        }
    }
}
