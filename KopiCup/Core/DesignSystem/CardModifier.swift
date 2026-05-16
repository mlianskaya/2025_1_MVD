//
//  CardModifier.swift
//  KopiCup
//
//  Created by Павел Гордиенко on 12/21/25.
//

import SwiftUI

struct CardModifier: ViewModifier {
    let appearance: CardAppearance
    @Environment(\.colorScheme) private var colorScheme

    // Подложка/«тень» под карточкой — динамическая
    private var dropFill: Color {
        if appearance.borderWidth > 0 {
            return appearance.borderColor.opacity(colorScheme == .dark ? 0.25 : 0.35)
        } else {
            return colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.06)
        }
    }

    private var shadowColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.35) : Color.black.opacity(0.08)
    }

    func body(content: Content) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(dropFill)
                .offset(x: 0, y: 5)

            RoundedRectangle(cornerRadius: 12)
                .fill(appearance.backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(appearance.borderColor, lineWidth: appearance.borderWidth)
                )
                .shadow(color: shadowColor, radius: 10, x: 0, y: 4)

            content
                .padding(16)
                .foregroundColor(appearance.foregroundColor)
        }
    }
}

extension View {
    func cardStyle(_ appearance: CardAppearance) -> some View {
        self.modifier(CardModifier(appearance: appearance))
    }
}
