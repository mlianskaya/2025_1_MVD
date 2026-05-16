import SwiftUI

struct AboutGoalView: View {
    let goal: Goal
    let onClose: () -> Void
    @ObservedObject var seriesVM: SeriesViewModel
    let onAddMoney: () -> Void
    let onEdit: () -> Void

    @AppStorage("settings.currency.code") private var currencyCode: String = "RUB"

    var body: some View {
        VStack(spacing: 0) {
            header
            content
            footerButtons
        }
        .background(Color(UIColor.systemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var header: some View {
        ZStack {
            Color(red: 102/255, green: 190/255, blue: 0)
                .ignoresSafeArea(edges: .top)

            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 80, height: 80)

                    if let urlString = goal.imageURL, let url = URL(string: urlString) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 72, height: 72)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            case .empty:
                                ProgressView()
                                    .frame(width: 72, height: 72)
                            case .failure:
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 36, height: 36)
                                    .foregroundColor(.white)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else {
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 36, height: 36)
                            .foregroundColor(.white)
                    }
                }

                Text(goal.title)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                if !goal.description.isEmpty {
                    Text(goal.description)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.bottom, 12)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 32)
            .padding(.bottom, 12)
        }
        
        .overlay(
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
            }
            .padding(.top, 14)
            .padding(.leading, 14),
            alignment: .topLeading
        )
        
        .overlay(
            Button(action: onClose) {
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
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Прогресс")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    Spacer()
                    Text(progressPercentText)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(red: 102/255, green: 190/255, blue: 0))
                }
                ProgressView(value: goal.progress)
                    .tint(Color(red: 102/255, green: 190/255, blue: 0))

                HStack {
                    Text(formatMoney(goal.currentAmount))
                    Spacer()
                    Text(formatMoney(goal.targetAmount))
                }
                .font(.footnote)
                .foregroundColor(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
            )

            HStack(spacing: 12) {
                infoPill(
                    title: "Осталось",
                    value: formatMoney(max(goal.targetAmount - goal.currentAmount, 0))
                )
                infoPill(
                    title: "Дата цели",
                    value: deadlineText
                )
            }

            Button(action: openProductLink) {
                HStack(spacing: 8) {
                    Image(systemName: "link")
                    Text("Посмотреть товар")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(UIColor.systemBackground))
                        )
                )
            }
            .disabled(productURL == nil)
            .opacity(productURL == nil ? 0.5 : 1.0)
        }
        .padding(16)
    }

    private var footerButtons: some View {
        VStack(spacing: 12) {
            Button(action: onAddMoney) {
                ZStack(alignment: .top) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(red: 78/255, green: 146/255, blue: 0))
                        .frame(height: 52)
                        .offset(y: 5)

                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(red: 102/255, green: 190/255, blue: 0))
                        .frame(height: 52)
                        .overlay(
                            Text("Пополнить копилку")
                                .foregroundColor(.white)
                                .bold()
                        )
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    private var productURL: URL? {
        if let link = goal.productLink, !link.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            if link.lowercased().hasPrefix("http://") || link.lowercased().hasPrefix("https://") {
                return URL(string: link)
            } else {
                return URL(string: "https://" + link)
            }
        }
        return nil
    }

    private func openProductLink() {
        guard let url = productURL else { return }
        UIApplication.shared.open(url)
    }

    private func infoPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(UIColor.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.03), radius: 2, x: 0, y: 1)
        )
    }

    private var progressPercentText: String {
        let p = Int(round(goal.progress * 100))
        return "\(p)%"
    }

    private var deadlineText: String {
        guard let date = goal.deadlineDate else { return "—" }
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "ru_RU")
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: date)
    }

    private func formatMoney(_ minorUnits: Int) -> String {
        let value = Double(minorUnits) / 100.0
        return CurrencyFormatter.format(value, code: currencyCode)
    }
}
