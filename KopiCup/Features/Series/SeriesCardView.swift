import SwiftUI

struct DayItem: Identifiable {
    let id: Int
    let name: String
}

struct SeriesCardView: View {
    @ObservedObject var viewModel: SeriesViewModel
    @State private var showNoGoalAlert = false

    private let weekDays = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]

    private var orderedDays: [DayItem] {
        let today = viewModel.currentDayIndex
        return (0..<7).map { offset in
            let idx = (today + offset) % 7
            return DayItem(id: idx, name: weekDays[idx])
        }
    }

    private var isPresentedBinding: Binding<Bool> {
        Binding(
            get: { viewModel.showAddMoneyModal },
            set: { viewModel.showAddMoneyModal = $0 }
        )
    }

    private let cardColor: Color = Color(red: 102/255, green: 190/255, blue: 0)
    private var todayIndex: Int { viewModel.currentDayIndex }

    private func dayTextColor(_ id: Int) -> Color {
        id == todayIndex ? cardColor : .secondary
    }

    private func dayTextWeight(_ id: Int) -> Font.Weight {
        id == todayIndex ? .bold : .regular
    }

    private func dayFillColor(_ id: Int) -> Color {
        viewModel.isDayCompleted(id) ? cardColor : Color.gray.opacity(0.3)
    }

    private func dayRingColor(_ id: Int) -> Color {
        id == todayIndex ? cardColor : .clear
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("За неделю накоплено \(viewModel.formatWithCurrentCurrency(viewModel.totalSavedThisWeek))")
                Text("Продолжай в том же духе!")
            }
            .font(.headline)
            .foregroundColor(cardColor)
            .padding(.bottom, 2)

            HStack(alignment: .center, spacing: 12) {
                VStack(spacing: 4) {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(cardColor)
                        .font(.system(size: 18, weight: .semibold))
                    Text("\(viewModel.savedDaysCount)")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(cardColor)
                }
                .frame(width: 36)

                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(orderedDays) { item in
                                VStack(spacing: 4) {
                                    Text(item.name)
                                        .font(.caption2)
                                        .fontWeight(dayTextWeight(item.id))
                                        .foregroundColor(dayTextColor(item.id))

                                    Circle()
                                        .fill(dayFillColor(item.id))
                                        .frame(width: 28, height: 28)
                                        .overlay(
                                            Circle()
                                                .stroke(dayRingColor(item.id), lineWidth: 2)
                                        )
                                        .onTapGesture {
                                            if viewModel.goal == nil {
                                                showNoGoalAlert = true
                                            } else {
                                                viewModel.selectedDayIndex = nil
                                                viewModel.showAddMoneyModal = true
                                            }
                                        }
                                }
                                .id(item.id)
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            proxy.scrollTo(todayIndex, anchor: .leading)
                        }
                    }
                }
            }
            .padding(.vertical, 2)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 14)
        .cardStyle(
            CardAppearance.default
                .with(
                    foregroundColor: cardColor,
                    borderColor: cardColor,
                    borderWidth: 5
                )
        )
        .sheet(isPresented: isPresentedBinding) {
            AddMoneyView(
                isPresented: isPresentedBinding,
                viewModel: viewModel
            )
        }
        .alert("Сначала создай цель", isPresented: $showNoGoalAlert) {
            Button("Ок", role: .cancel) { }
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        (startIndex..<endIndex).contains(index) ? self[index] : nil
    }
}
