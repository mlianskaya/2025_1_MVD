// DifficultyBoltsView.swift
import SwiftUI

struct DifficultyBoltsView: View {
    let difficulty: Int
    var max: Int = 3
    var color: Color = .primary
    var spacing: CGFloat = 6
    var size: CGFloat = 14

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<max, id: \.self) { i in
                Image(systemName: i < clamped ? "bolt.fill" : "bolt")
                    .font(.system(size: size, weight: .semibold))
                    .foregroundColor(color.opacity(i < clamped ? 1.0 : 0.35))
                    .accessibilityHidden(true)
            }
        }
        .accessibilityLabel("Сложность: \(clamped) из \(max)")
    }

    private var clamped: Int { Swift.max(0, Swift.min(difficulty, max)) }
}
