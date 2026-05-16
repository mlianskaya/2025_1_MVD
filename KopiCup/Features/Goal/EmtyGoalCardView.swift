//
//  EmtyGoalCardView.swift
//  KopiCup
//
//  Created by Павел Гордиенко on 12/21/25.
//

import SwiftUI

struct EmptyGoalCardView: View {
    let onAdd: () -> Void
    // Убираем жёсткий светло‑серый: используем динамический фон карточки
    var appearance = CardAppearance.default.with(foregroundColor: .primary)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("У вас пока нет цели").font(.headline).fontWeight(.semibold)
                Text("Самое время ее добавить").font(.subheadline).opacity(0.8)
            }
            HStack {
                Spacer()
                Button(action: onAdd) {
                    Circle().fill(Color.green).frame(width: 60, height: 60)
                        .overlay(Image(systemName: "plus").font(.title).fontWeight(.bold).foregroundColor(.white))
                        .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                Spacer()
            }
        }
        .cardStyle(appearance)
    }
}
