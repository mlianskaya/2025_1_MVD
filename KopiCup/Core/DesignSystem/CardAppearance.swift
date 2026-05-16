//
//  File.swift
//  KopiCup
//
//  Created by Павел Гордиенко on 12/21/25.
//

import SwiftUI

struct CardAppearance {
    let backgroundColor: Color
    let foregroundColor: Color
    let borderColor: Color
    let borderWidth: CGFloat
    
    // Динамический фон корректно работает в светлой/тёмной темах
    static let `default` = CardAppearance(
        backgroundColor: Color(UIColor.secondarySystemBackground),
        foregroundColor: .primary,
        borderColor: .clear,
        borderWidth: 0
    )
    
    func with(
        backgroundColor: Color? = nil,
        foregroundColor: Color? = nil,
        borderColor: Color? = nil,
        borderWidth: CGFloat? = nil
    ) -> CardAppearance {
        CardAppearance(
            backgroundColor: backgroundColor ?? self.backgroundColor,
            foregroundColor: foregroundColor ?? self.foregroundColor,
            borderColor: borderColor ?? self.borderColor,
            borderWidth: borderWidth ?? self.borderWidth
        )
    }
}
