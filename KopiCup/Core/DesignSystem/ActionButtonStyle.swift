//
//  Components.swift
//  KopiCup
//
//  Created by Павел Гордиенко on 12/21/25.
//

import SwiftUI

enum ButtonVariant {
    case primary, secondary
    var backgroundColor: Color { self == .primary ? .blue : .white }
    var foregroundColor: Color { self == .primary ? .white : .blue }
    var borderColor: Color { self == .primary ? .clear : .blue }
}


struct ActionButtonStyle: ButtonStyle {
    let variant: ButtonVariant
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(variant.foregroundColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(variant.backgroundColor)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(variant.borderColor, lineWidth: 1))
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

