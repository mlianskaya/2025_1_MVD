import SwiftUI
import UIKit

struct ProfileView: View {
    @EnvironmentObject private var appUserStorage: UserStorage
    private let userService = LocalUserService()
    private let localUser = LocalUserService()
    
    @AppStorage("settings.theme.darkMode") private var isDarkMode: Bool = false
    @AppStorage("settings.currency.code") private var currencyCode: String = "RUB"
    @AppStorage("settings.language.code") private var languageCode: String = "ru"
    
    @AppStorage("profile.name") private var storedName: String = "Гость"
    @AppStorage("profile.avatar.data") private var avatarData: Data = Data()
    @State private var avatarImage: UIImage? = nil
    
    @State private var achievements: [AchievementItem] = [
        .init(id: "first_topup", title: "Первое пополнение", systemImage: "star.fill", achieved: true),
        .init(id: "seven_days", title: "7 дней подряд", systemImage: "flame.fill", achieved: true),
        .init(id: "goal_reached", title: "Цель достигнута", systemImage: "scope", achieved: false),
        .init(id: "savings_master", title: "Мастер накоплений", systemImage: "crown.fill", achieved: false),
        .init(id: "thirty_days", title: "30 дней подряд", systemImage: "medal.fill", achieved: false),
        .init(id: "lightning_start", title: "Молниеносный старт", systemImage: "bolt.fill", achieved: false),
    ]
    
    @State private var showEditSheet = false
    
    enum PickerSource { case photoLibrary, camera }
    @State private var showImagePicker = false
    @State private var pickerSource: PickerSource = .photoLibrary
    
    @State private var showLogoutConfirm = false
    
    private var achievedCount: Int { achievements.filter { $0.achieved }.count }
    private var displayName: String {
        let nameFromStore = appUserStorage.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !nameFromStore.isEmpty { return nameFromStore }
        let fromAppStorage = storedName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !fromAppStorage.isEmpty { return fromAppStorage }
        return "Гость"
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color(red: 102/255, green: 190/255, blue: 0)
                    .frame(height: 72)
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        headerCard
                        achievementsCard
                        settingsHeader
                        settingsCard
                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 16)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
        }
        .onAppear {
            let profile = localUser.fetchProfile()

            if let data = profile.avatarData, !data.isEmpty, let img = UIImage(data: data) {
                avatarImage = img
                avatarData = data
            } else {
                avatarImage = nil
                avatarData = Data()
            }

            if appUserStorage.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                appUserStorage.name = profile.name
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .sheet(isPresented: $showEditSheet) {
            EditNameSheet(
                currentName: displayName,
                onCancel: { showEditSheet = false },
                onSave: { newName in
                    localUser.updateName(newName)
                    appUserStorage.name = localUser.fetchProfile().name
                    showEditSheet = false
                }
            )
            .presentationDetents([.height(220)])
        }
        .confirmationDialog(
            "Вы действительно хотите выйти?",
            isPresented: $showLogoutConfirm,
            titleVisibility: .visible
        ) {
            Button("Выйти", role: .destructive) {
                performLogout()
            }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Вы вернётесь на экран входа.")
        }
        .sheet(isPresented: $showImagePicker) {
            SystemImagePicker(
                source: pickerSource == .camera ? .camera : .photoLibrary
            ) { image in
                if let image {
                    applyNewAvatar(image)
                }
                showImagePicker = false
            }
        }
    }
    
    private var headerCard: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(red: 250/255, green: 237/255, blue: 210/255))
                    .frame(width: 56, height: 56)
                
                if let avatarImage {
                    Image(uiImage: avatarImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 56, height: 56)
                        .clipShape(Circle())
                } else {
                    Text(initials(from: displayName))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                }
            }
            .contentShape(Circle())
            .contextMenu {
                Button("Выбрать из галереи", systemImage: "photo.on.rectangle") {
                    pickerSource = .photoLibrary
                    showImagePicker = true
                }
                Button("Сделать фото", systemImage: "camera") {
                    pickerSource = .camera
                    showImagePicker = true
                }
                if avatarImage != nil {
                    Button(role: .destructive) {
                        removeAvatar()
                    } label: {
                        Label("Удалить фото", systemImage: "trash")
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(displayName.isEmpty ? "Анна Дегтярева" : displayName)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                Text("Копит с \(sinceText)")
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary)
            }
            Spacer()
            
            HStack(spacing: 8) {
                Button {
                    pickerSource = .photoLibrary
                    showImagePicker = true
                } label: {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .foregroundColor(.blue)
                        .font(.system(size: 16, weight: .semibold))
                        .padding(10)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Circle())
                        .accessibilityLabel("Изменить фото")
                }
                .buttonStyle(.plain)
                
                Button {
                    showEditSheet = true
                } label: {
                    Image(systemName: "pencil")
                        .foregroundColor(.blue)
                        .font(.system(size: 16, weight: .semibold))
                        .padding(10)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
        )
    }
    
    private var sinceText: String {
        guard let date = appUserStorage.registrationDate else {
            return ""
        }

        let formatter = Foundation.DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: date)
    }

    private var achievementsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.orange)
                    Text("Достижения")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                }
                Spacer()
                Text("\(achievedCount)/\(achievements.count)")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 2)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(achievements) { item in
                    AchievementCell(item: item)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
        )
    }
    
    private var settingsHeader: some View {
        Text("Настройки")
            .font(.system(size: 20, weight: .semibold, design: .rounded))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
            .foregroundColor(.primary)
    }
    
    private var settingsCard: some View {
        VStack(spacing: 12) {
            SettingsToggleRow(
                icon: "sun.max.fill",
                iconColor: Color.yellow,
                title: "Темная тема",
                subtitle: nil,
                isOn: $isDarkMode
            )
            
            SettingsPickerRow(
                icon: "banknote.fill",
                iconColor: Color.green,
                title: "Валюта",
                valueText: currencyDisplayName(currencyCode)
            ) {
                Button("₽ RUB") { currencyCode = "RUB" }
                Button("$ USD") { currencyCode = "USD" }
                Button("€ EUR") { currencyCode = "EUR" }
                Button("¥ CNY") { currencyCode = "CNY" }
            }
            
            SettingsPickerRow(
                icon: "globe",
                iconColor: Color.blue,
                title: "Язык",
                valueText: languageDisplayName(languageCode)
            ) {
                Button("Русский") { languageCode = "ru" }
                Button("English") { languageCode = "en" }
            }
            
            Button(role: .destructive) {
                showLogoutConfirm = true
            } label: {
                HStack {
                    Spacer()
                    Text("Выйти из аккаунта")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                    Spacer()
                }
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
            .padding(.top, 4)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
        )
    }
    
    private func initials(from name: String) -> String {
        let parts = name.split(separator: " ")
        let initials = parts.prefix(2).compactMap { $0.first }.map { String($0) }.joined()
        return initials.isEmpty ? "🐷" : initials.uppercased()
    }
    
    private func currencyDisplayName(_ code: String) -> String {
        switch code {
        case "RUB": return "₽ RUB"
        case "USD": return "$ USD"
        case "EUR": return "€ EUR"
        case "CNY": return "¥ CNY"
        default:    return code
        }
    }
    
    private func languageDisplayName(_ code: String) -> String {
        switch code {
        case "ru": return "Русский"
        case "en": return "English"
        default:   return code
        }
    }
    
    private func applyNewAvatar(_ image: UIImage) {
        let maxSide: CGFloat = 512
        let scaled = image.scaledTo(maxSide: maxSide)
        if let data = scaled.jpegData(compressionQuality: 0.85) {
            self.avatarData = data
            self.avatarImage = UIImage(data: data)
        } else if let data = scaled.pngData() {
            self.avatarData = data
            self.avatarImage = UIImage(data: data)
        } else {
            self.avatarImage = image
        }
        localUser.updateAvatarData(self.avatarData)
    }
    
    private func removeAvatar() {
        self.avatarData = Data()
        self.avatarImage = nil
        localUser.updateAvatarData(nil)
    }
    
    private func performLogout() {
        appUserStorage.logout()
    }
}

private struct AchievementItem: Identifiable {
    let id: String
    let title: String
    let systemImage: String
    let achieved: Bool
}

private struct AchievementCell: View {
    let item: AchievementItem
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(item.achieved ? Color.yellow.opacity(0.16) : Color.gray.opacity(0.12))
                    .frame(height: 64)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(item.achieved ? Color.yellow.opacity(0.6) : Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.03), radius: 2, x: 0, y: 1)
                
                Image(systemName: item.systemImage)
                    .font(.system(size: 22))
                    .foregroundColor(item.achieved ? .orange : .gray.opacity(0.6))
            }
            
            Text(item.title)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundColor(item.achieved ? .primary : .secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
        }
    }
}

private struct SettingsToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            iconView
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
    
    @ViewBuilder
    private var iconView: some View {
        ZStack {
            Circle()
                .fill(iconColor.opacity(0.15))
                .frame(width: 36, height: 36)
            Image(systemName: icon)
                .foregroundColor(iconColor)
        }
    }
}

private struct SettingsPickerRow<MenuContent: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    let valueText: String
    @ViewBuilder var menuContent: () -> MenuContent
    
    var body: some View {
        HStack(spacing: 12) {
            iconView
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                Text(valueText)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Menu {
                menuContent()
            } label: {
                HStack(spacing: 6) {
                    Text(valueText)
                        .foregroundColor(.primary)
                    Image(systemName: "chevron.down")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(UIColor.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
    
    @ViewBuilder
    private var iconView: some View {
        ZStack {
            Circle()
                .fill(iconColor.opacity(0.15))
                .frame(width: 36, height: 36)
            Image(systemName: icon)
                .foregroundColor(iconColor)
        }
    }
}

private struct EditNameSheet: View {
    @State private var name: String
    let onCancel: () -> Void
    let onSave: (String) -> Void
    
    init(currentName: String, onCancel: @escaping () -> Void, onSave: @escaping (String) -> Void) {
        _name = State(initialValue: currentName)
        self.onCancel = onCancel
        self.onSave = onSave
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Изменить имя")
                .font(.headline)
            TextField("Ваше имя", text: $name)
                .textInputAutocapitalization(.words)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            HStack {
                Button("Отмена", action: onCancel)
                Spacer()
                Button("Сохранить") {
                    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty { onSave(trimmed) }
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(16)
        .modifier(PresentationBackgroundCompat())
    }
}

private struct PresentationBackgroundCompat: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.4, *) {
            content.presentationBackground(.regularMaterial)
        } else {
            content
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ProfileView()
                .previewDisplayName("Light")
                .environmentObject(UserStorage())
            ProfileView()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark")
                .environmentObject(UserStorage())
        }
    }
}

private struct SystemImagePicker: UIViewControllerRepresentable {
    enum Source {
        case photoLibrary
        case camera
        
        var uiKitSourceType: UIImagePickerController.SourceType {
            switch self {
            case .photoLibrary: return .photoLibrary
            case .camera: return .camera
            }
        }
    }
    
    let source: Source
    var onImagePicked: (UIImage?) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onImagePicked: onImagePicked)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let vc = UIImagePickerController()
        let desiredSource = source.uiKitSourceType
        if UIImagePickerController.isSourceTypeAvailable(desiredSource) {
            vc.sourceType = desiredSource
        } else {
            vc.sourceType = .photoLibrary
        }
        vc.delegate = context.coordinator
        vc.allowsEditing = true
        return vc
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let onImagePicked: (UIImage?) -> Void
        init(onImagePicked: @escaping (UIImage?) -> Void) { self.onImagePicked = onImagePicked }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage
            onImagePicked(image)
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onImagePicked(nil)
            picker.dismiss(animated: true)
        }
    }
}

private extension UIImage {
    func scaledTo(maxSide: CGFloat) -> UIImage {
        let maxCurrent = max(size.width, size.height)
        guard maxCurrent > maxSide else { return self }
        let scale = maxSide / maxCurrent
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
