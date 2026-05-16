import SwiftUI
import UIKit

struct EditGoalView: View {
    @Binding var isPresented: Bool

    let goal: Goal
    var onSave: (Goal) -> Void
    var onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var desc: String = ""
    @State private var amountText: String = ""
    @State private var deadline: Date = Date()
    @State private var link: String = ""

    @State private var pickedImage: UIImage?
    @State private var showImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary

    @State private var isSaving = false
    @State private var showDeleteConfirm = false
    @State private var showValidationAlert = false
    @State private var validationMessage = ""

    var body: some View {
        VStack(spacing: 0) {
            header
            content
        }
        .background(Color(UIColor.systemGroupedBackground))
        .sheet(isPresented: $showImagePicker) {
            ImagePickerView(sourceType: sourceType, selectedImage: $pickedImage)
        }
        .alert("Удалить цель?", isPresented: $showDeleteConfirm) {
            Button("Удалить", role: .destructive) {
                onDelete()
                dismissSelf()
            }
            Button("Отмена", role: .cancel) { }
        } message: {
            Text("Действие нельзя отменить.")
        }
        .alert(isPresented: $showValidationAlert) {
            Alert(
                title: Text("Проверьте поля"),
                message: Text(validationMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear { preload() }
    }

    private var header: some View {
        ZStack {
            Color(red: 102/255, green: 190/255, blue: 0).ignoresSafeArea(edges: .top)

            VStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 120, height: 120)

                    if let img = pickedImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 110, height: 110)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    } else if let urlString = goal.imageURL, let url = URL(string: urlString) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 110, height: 110)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            case .empty:
                                ProgressView()
                                    .frame(width: 110, height: 110)
                            case .failure:
                                Image(systemName: "photo")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                            @unknown default:
                                EmptyView()
                            }
                        }
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

                Text("Редактирование цели")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.top, 6)
            }
            .padding(.top, 36)
        }
        .overlay(
            Button {
                showDeleteConfirm = true
            } label: {
                Image(systemName: "trash.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.red)
                    .padding(8)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
            }
            .padding(.top, 14)
            .padding(.leading, 14),
            alignment: .topLeading
        )
        .overlay(
            Button {
                dismissSelf()
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
                        .fill(Color(red: 78/255, green: 146/255, blue: 0))
                        .frame(height: 52)
                        .offset(y: 6)
                }

                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 102/255, green: 190/255, blue: 0))
                    .frame(height: 52)
                    .overlay(
                        Group {
                            if isSaving {
                                ProgressView().tint(.white)
                            } else {
                                Text("Сохранить")
                                    .foregroundColor(.white)
                                    .bold()
                            }
                        }
                    )
            }
        }
        .disabled(isSaving)
    }

    private func preload() {
        title = goal.title
        desc = goal.description
        amountText = formatWithGrouping(String(goal.targetAmount / 100))
        deadline = goal.deadlineDate ?? Date()
        link = goal.productLink ?? ""
    }

    private func amountMinorUnits() -> Int {
        let digits = amountText.filter { $0.isNumber }
        return (Int(digits) ?? 0) * 100
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

    private func saveValidation() -> String? {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let units = Int(amountText.filter { $0.isNumber }) ?? 0
        let today = Calendar.current.startOfDay(for: Date())

        var missing: [String] = []
        if trimmedTitle.isEmpty { missing.append("Название") }
        if units <= 0 { missing.append("Сумма") }
        if deadline < today { missing.append("Дата") }

        if missing.isEmpty { return nil }
        return "Заполните обязательные поля: " + missing.joined(separator: ", ")
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

        let updated = Goal(
            id: goal.id,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            description: desc,
            targetAmount: amountMinorUnits(),
            currentAmount: goal.currentAmount,
            currency: goal.currency,
            status: goal.status,
            deadlineDate: deadline,
            productLink: link.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : link,
            imageURL: goal.imageURL
        )

        onSave(updated)
        dismissSelf()
    }
}
