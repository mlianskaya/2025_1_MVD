import SwiftUI
import UIKit

struct GoalFormView: View {
    @Binding var isPresented: Bool
    var onSave: (Goal) -> Void

    @Environment(\.dismiss) private var dismiss
    @AppStorage("settings.currency.code") private var currencyCode: String = "RUB"

    @State private var title = ""
    @State private var desc = ""
    @State private var amountText = ""
    @State private var deadline = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
    @State private var link = ""

    @State private var image: UIImage?
    @State private var showImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary

    @State private var isSaving = false
    @State private var showValidationAlert = false
    @State private var validationMessage = ""

    var body: some View {
        VStack(spacing: 0) {
            header
            content
        }
        .background(Color(UIColor.systemGroupedBackground))
        .sheet(isPresented: $showImagePicker) {
            ImagePickerView(sourceType: sourceType, selectedImage: $image)
        }
        .alert(isPresented: $showValidationAlert) {
            Alert(
                title: Text("Проверьте поля"),
                message: Text(validationMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private var header: some View {
        ZStack {
            Color(red: 102/255, green: 190/255, blue: 0).ignoresSafeArea(edges: .top)

            VStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 120, height: 120)

                    if let img = image {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 110, height: 110)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    } else {
                        Image(systemName: "photo")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .overlay(alignment: .bottom) {
                    Button {
                        sourceType = .photoLibrary
                        showImagePicker = true
                    } label: {
                        Image(systemName: "camera.fill")
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.blue.opacity(0.9))
                            .clipShape(Circle())
                            .shadow(radius: 3)
                    }
                }

                Text("Новая цель")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.top, 6)
            }
            .padding(.top, 36)
        }
        .overlay(
            Button {
                isPresented = false
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
            }
            .padding(.top, 14)
            .padding(.trailing, 14),
            alignment: .topTrailing
        )
        .frame(height: 230)
    }

    private var content: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                field(text: $title, placeholder: "Название цели")

                field(text: $desc, placeholder: "Описание")

                amountField

                dateField

                field(text: $link, placeholder: "Ссылка на товар")

                saveButton
                    .padding(.top, 12)
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
            )
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 20)
        }
        .environment(\.locale, Locale(identifier: "ru_RU"))
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 20)
        }
    }

    private func field(text: Binding<String>, placeholder: String) -> some View {
        TextField(placeholder, text: text)
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(red: 102/255, green: 190/255, blue: 0), lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
            )
    }

    private var amountField: some View {
        TextField("Сумма", text: $amountText)
            .keyboardType(.numberPad)
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(red: 102/255, green: 190/255, blue: 0), lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
            )
            .onChange(of: amountText) { newValue in
                let digits = newValue.filter { $0.isNumber }
                let formatted = formatWithGrouping(digits)
                if formatted != newValue {
                    amountText = formatted
                }
            }
    }

    private var dateField: some View {
        HStack {
            DatePicker("Срок", selection: $deadline, displayedComponents: .date)
                .labelsHidden()
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(red: 102/255, green: 190/255, blue: 0), lineWidth: 2)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.secondarySystemBackground))
                )
        )
    }

    private var saveButton: some View {
        Button(action: { Task { await save() } }) {
            ZStack(alignment: .top) {
                if !isSaving {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(red: 0, green: 0.4, blue: 0.8)) 
                        .frame(height: 52)
                        .offset(y: 6)
                }

                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue)
                    .frame(height: 52)
                    .overlay(
                        Group {
                            if isSaving {
                                ProgressView().tint(.white)
                            } else {
                                Text("Создать")
                                    .foregroundColor(.white)
                                    .bold()
                            }
                        }
                    )
            }
        }
        .disabled(isSaving)
    }

    private func saveValidation() -> String? {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let digits = amountDigits
        let units = Int(digits) ?? 0
        let today = Calendar.current.startOfDay(for: Date())

        var missing: [String] = []
        if trimmedTitle.isEmpty { missing.append("Название") }
        if units <= 0 { missing.append("Сумма") }
        if deadline < today { missing.append("Дата") }

        if missing.isEmpty { return nil }
        return "Заполните обязательные поля: " + missing.joined(separator: ", ")
    }

    private func amountMinorUnits() -> Int {
        let units = Int(amountDigits) ?? 0
        return units * 100
    }

    private var amountDigits: String {
        amountText.filter { $0.isNumber }
    }

    private func formatWithGrouping(_ digits: String) -> String {
        guard !digits.isEmpty else { return "" }
        let number = Int(digits) ?? 0
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: number)) ?? digits
    }

    private func buildGoal(imageURL: String?) -> Goal {
        Goal(
            id: nil,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            description: desc,
            targetAmount: amountMinorUnits(),
            currentAmount: 0,
            currency: currencyCode,
            status: "active",
            deadlineDate: deadline,
            productLink: link.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : link,
            imageURL: imageURL
        )
    }

    private func dismissSelf() {
        dismiss()
        isPresented = false
    }

    private func save() async {
        if let message = saveValidation() {
            validationMessage = message
            showValidationAlert = true
            return
        }

        isSaving = true
        defer { isSaving = false }

        let goal = buildGoal(imageURL: nil)
        onSave(goal)
        dismissSelf()
    }
}
