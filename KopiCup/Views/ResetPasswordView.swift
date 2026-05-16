//
//  ResetPasswordView.swift
//  KopiCup
//
//  Created by Павел Гордиенко on 16.12.2025.
//

import SwiftUI
import FirebaseAuth

struct ResetPasswordView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var email: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var successMessage: String? = nil
    @State private var showAlert: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                    
                    Text("Восстановление пароля")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Введите email, указанный при регистрации. Мы отправим вам ссылку для сброса пароля.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .font(.headline)
                    
                    TextField("email@example.com", text: $email)
                        .textInputAutocapitalization(.never)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
                .padding(.horizontal, 24)
                
                Button(action: resetPassword) {
                    HStack {
                        Spacer()
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Отправить ссылку")
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .disabled(email.isEmpty || isLoading)
                
                Spacer()
                
                if let successMessage = successMessage {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.green)
                        
                        Text(successMessage)
                            .font(.subheadline)
                            .foregroundColor(.green)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                }
            }
            .alert("Восстановление пароля", isPresented: $showAlert) {
                Button("OK", role: .cancel) {
                    if successMessage != nil {
                        dismiss()
                    }
                }
            } message: {
                Text(successMessage ?? errorMessage ?? "")
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Закрыть") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func resetPassword() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        
        guard !trimmedEmail.isEmpty else {
            errorMessage = "Введите email"
            showAlert = true
            return
        }
        
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        Auth.auth().sendPasswordReset(withEmail: trimmedEmail) { error in
            isLoading = false
            
            if let error = error {
                let russianError = convertFirebaseError(error)
                errorMessage = russianError
                successMessage = nil
            } else {
                successMessage = "Ссылка для восстановления пароля отправлена на \(trimmedEmail)"
                errorMessage = nil
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    dismiss()
                }
            }
            showAlert = true
        }
    }
    
    private func convertFirebaseError(_ error: Error) -> String {
        let nsError = error as NSError
        switch nsError.code {
        case AuthErrorCode.invalidEmail.rawValue:
            return "Неверный формат email"
        case AuthErrorCode.userNotFound.rawValue:
            return "Пользователь с таким email не найден"
        case AuthErrorCode.networkError.rawValue:
            return "Проблемы с сетью. Проверьте подключение к интернету"
        default:
            return "Ошибка: \(error.localizedDescription)"
        }
    }
}

struct ResetPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        #if DEBUG
        ResetPasswordView()
        #endif
    }
}
