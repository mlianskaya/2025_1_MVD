//
//  ChallengeDetailsView.swift
//  KopiCup
//
//  Created by Павел Гордиенко on 12/23/25.
//

import SwiftUI

struct ChallengeDetailView: View {
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: ChallengeViewModel
    @State private var showDeclineAlert = false
    @State private var highlightTick = false

    private var challenge: Challenge? { viewModel.displayedChallenge }

    // Максимальное число "болтов" сложности
    private let maxDifficulty = 3
    private var difficultyCount: Int {
        let value = challenge?.difficulty ?? 0
        return Swift.max(0, Swift.min(value, maxDifficulty))
    }

    // Период 7 дней начиная с сегодняшнего дня в формате d.MM - d.MM
    private var periodText: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "d.MM"
        let today = Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.date(byAdding: .day, value: 6, to: today) ?? today
        return "\(fmt.string(from: today)) - \(fmt.string(from: end))"
    }

    // Индекс текущего дня.
    // Если челлендж активен — считаем относительно startDate.
    // Если челлендж ещё не принят — подсвечиваем первый день (0).
    private var currentDayIndex: Int? {
        if let uc = viewModel.activeChallenge {
            let cal = Calendar.current
            let s = cal.startOfDay(for: uc.startDate)
            let e = cal.startOfDay(for: Date())
            let diff = cal.dateComponents([.day], from: s, to: e).day ?? 0
            guard (0...6).contains(diff) else { return nil }
            return diff
        } else {
            return 0
        }
    }

    private var isTodayAlreadyMarked: Bool {
        viewModel.activeChallenge?.isTodayCompleted ?? false
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topTrailing) {
                // Синий фон на всю область всплывающего окна
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.75)]),
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 24) {
                    // Шапка на синем фоне
                    headerContent
                        .padding(.top, 30)

                    // Контентная карточка (без minHeight, чтобы не раздувать белый фон)
                    VStack(alignment: .leading, spacing: 12) {
                        // Заголовок секции периода — по центру
                        Text("Период челленджа")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.top, 10)

                        // Период в рамке с иконкой — по центру
                        HStack(spacing: 8) {
                            Image(systemName: "calendar")
                                .foregroundColor(.primary)
                            Text(periodText)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.gray.opacity(0.35), lineWidth: 1)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(Color(UIColor.systemGray6))
                                )
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)

                        // Прогресс
                        VStack(spacing: 8) {
                            Text("Прогресс")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)

                            HStack(spacing: 10) {
                                ForEach(0..<7, id: \.self) { i in
                                    ZStack {
                                        Circle()
                                            .fill(circleColor(for: i))
                                            .frame(width: 36, height: 36)
                                        Text("\(i+1)")
                                            .foregroundColor(.white)
                                            .fontWeight(.semibold)
                                    }
                                    .animation(.easeInOut(duration: 0.2), value: highlightTick)
                                }
                            }
                            .padding(.horizontal, 8)
                        }
                        .padding(.bottom, 4)

                        // Кнопка "Отметить сегодня"
                        Button(action: {
                            viewModel.markToday()
                            isPresented = false
                        }) {
                            Text(isTodayAlreadyMarked ? "Отмечено сегодня" : "Отметить сегодня")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(isTodayAlreadyMarked ? Color.gray : Color.green)
                                .cornerRadius(12)
                        }
                        .disabled(isTodayAlreadyMarked)
                        .padding(.horizontal, 16)

                        // Кнопка "Отказаться от челленджа"
                        Button(action: { showDeclineAlert = true }) {
                            Text("✗ Отказаться от челленджа")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                    }
                    .padding(.vertical, 16)
                    .background(Color(UIColor.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal, 12)

                    Spacer(minLength: 0)
                }
                // Высота окна ограничена доступной высотой экрана
                .frame(maxHeight: geo.size.height, alignment: .top)

                // Крестик закрытия
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .padding(14)
                }
                .padding(.top, 8)
                .padding(.trailing, 8)
            }
        }
        .onAppear { highlightTick.toggle() }
        .alert("Вы уверены, что хотите отказаться от челленджа?", isPresented: $showDeclineAlert) {
            Button("Отказаться", role: .destructive) {
                viewModel.declineActiveChallenge()
                isPresented = false
            }
            Button("Отмена", role: .cancel) { }
        }
    }

    private var headerContent: some View {
        VStack(spacing: 6) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 36))
                .foregroundColor(.white)

            Text(challenge?.name ?? "Челлендж")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            // Болты сложности
            HStack(spacing: 6) {
                ForEach(0..<maxDifficulty, id: \.self) { i in
                    Image(systemName: i < difficultyCount ? "bolt.fill" : "bolt")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(i < difficultyCount ? 1.0 : 0.35))
                }
            }
            .padding(.top, 2)

            Text(challenge?.description ?? "")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.85))
                .padding(.horizontal, 16)
        }
    }

    private func circleColor(for index: Int) -> Color {
        // выполненный — зеленый; текущий день — синий; иначе — серый
        if let progress = viewModel.activeChallenge?.progress,
           progress.indices.contains(index),
           progress[index] {
            return .green
        }
        if let current = currentDayIndex, current == index {
            return .blue
        }
        return Color.gray.opacity(0.35)
    }
}
