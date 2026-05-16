import SwiftUI

struct LabeledTextField: View {
    let title: String
    let placeholder: String
    let iconName: String?
    @Binding var text: String
    let error: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 14, design: .rounded))
                .bold()

            Label {
                TextField(
                    "",
                    text: $text,
                    prompt: Text(placeholder)
                        .foregroundColor(.gray.opacity(0.6))
                )
                .textInputAutocapitalization(.never)
            } icon: {
                if let iconName = iconName {
                    Image(systemName: iconName)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        error == nil ? Color.secondary : Color.red,
                        lineWidth: 2
                    )
            )

            if let error = error {
                Text(error)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(.red)
            }
        }
    }
}

struct LabeledSecureField: View {
    let title: String
    let placeholder: String
    let iconName: String?
    @Binding var text: String
    let error: String?

    @State private var isSecure: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 14, design: .rounded))
                .bold()

            HStack {
                if let iconName = iconName {
                    Image(systemName: iconName)
                        .foregroundColor(.secondary)
                }

                Group {
                    if isSecure {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                    }
                }
                .textInputAutocapitalization(.never)
                .textContentType(.password)

                Button {
                    isSecure.toggle()
                } label: {
                    Image(systemName: isSecure ? "eye.slash" : "eye")
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        error == nil ? Color.secondary : Color.red,
                        lineWidth: 2
                    )
            )

            if let error = error {
                Text(error)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(.red)
            }
        }
    }
}

struct GreenButton: View {
    let title: String
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .top) {
                if !isDisabled {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(red: 78/255, green: 146/255, blue: 0))
                        .frame(height: 48)
                        .offset(y: 5)
                }

                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isDisabled
                        ? Color(red: 102/255, green: 190/255, blue: 0).opacity(0.5)
                        : Color(red: 102/255, green: 190/255, blue: 0)
                    )
                    .frame(height: 48)
                    .overlay(
                        Text(title)
                            .foregroundColor(.white)
                            .bold()
                    )
            }
        }
        .disabled(isDisabled)
    }
}
