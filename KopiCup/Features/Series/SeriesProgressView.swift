//
//  SeriesProgressView.swift
//  KopiCup
//
//  Created by Павел Гордиенко on 12/23/25.
//

import SwiftUI

struct SeriesProgressView: View {
    let progress: [Bool]

    var body: some View {
        HStack {
            ForEach(progress.indices, id: \.self) { index in
                Circle()
                    .fill(progress[index] ? .green : .gray.opacity(0.3))
                    .frame(width: 24, height: 24)
            }
        }
    }
}

