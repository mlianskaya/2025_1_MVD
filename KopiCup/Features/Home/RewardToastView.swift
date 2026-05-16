import SwiftUI

struct RewardToastData: Equatable {
    let title: String
    let message: String
}

struct RewardToastView: View {
    let data: RewardToastData

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 38, height: 38)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.18))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(data.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)

                Text(data.message)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.95))
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.blue.opacity(0.9))
        )
        .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 6)
        .allowsHitTesting(false)
    }
}
