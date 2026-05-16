import SwiftUI

struct GoalDetailsView: View {
    let goal: Goal
    @Binding var isPresented: Bool
    var onEdit: () -> Void

    var body: some View {
        VStack {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    // Пока нет imageURL/загрузки — плейсхолдер
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.thinMaterial)
                        .frame(height: 200)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "photo")
                                    .font(.system(size: 32))
                                    .foregroundColor(.secondary)
                                Text("Изображение появится позже")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                        )

                    Text(goal.title)
                        .font(.title)
                        .fontWeight(.bold)

                    ProgressView(value: goal.progress)
                        .tint(.blue)
                        .scaleEffect(y: 2)

                    HStack {
                        Text(formatMoney(goal.currentAmount, currency: goal.currency))
                        Spacer()
                        Text(formatMoney(goal.targetAmount, currency: goal.currency))
                    }
                    .font(.headline)
                }
                .padding()
            }
        }
    }

    private var header: some View {
        ZStack {
            Text("Детали")
                .font(.title2)
                .fontWeight(.bold)
        }
        .overlay(alignment: .leading) {
            Button(action: onEdit) {
                Image(systemName: "pencil.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
        .overlay(alignment: .trailing) {
            Button(action: { isPresented = false }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.gray)
            }
        }
        .padding()
    }

    private func formatMoney(_ minorUnits: Int, currency: String) -> String {
        let value = Double(minorUnits) / 100.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
