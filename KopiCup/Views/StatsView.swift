//
//  StatsView.swift
//  KopiCup
//

import SwiftUI
import DGCharts

private let kopiGreen = Color(red: 102/255, green: 190/255, blue: 0)

struct StatsView: View {
    @State private var selectedChartPage: Int = 0
    @State private var radarValues: [Double] = [0, 0, 50, 0, 0]
    @State private var savingsSnapshot = SavingsStatsSnapshot.empty()

    @AppStorage("settings.currency.code") private var currencyCode: String = "RUB"

    private let statsService = StatsService()
    private let chartsCarouselHeight: CGFloat = 300

    private var cardAppearance: CardAppearance {
        CardAppearance.default
            .with(
                foregroundColor: .primary,
                borderColor: kopiGreen,
                borderWidth: 5
            )
    }

    var body: some View {
        VStack(spacing: 0) {
            // Sticky green header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Статистика")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text("Отслеживайте свои накопления")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.85))
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                kopiGreen.ignoresSafeArea(edges: .top)
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    summaryCardsSection
                    chartsCarouselSection
                    summaryCharacteristics
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
            .background(Color(UIColor.systemGroupedBackground))
        }
        .task {
            await loadStats()
        }
        .onReceive(NotificationCenter.default.publisher(for: .didDeposit)) { _ in
            Task { await loadStats() }
        }
    }

    private func loadStats() async {
        guard let uid = LocalUserStore.shared.activeUID else { return }

        let result = await statsService.loadDashboard(uid: uid)
        radarValues = result.metrics.radarValues
        savingsSnapshot = result.savings
    }

    private var summaryCardsSection: some View {
        HStack(spacing: 12) {
            SummaryCard(title: "Эта неделя", value: savingsSnapshot.weekTotal, currencyCode: currencyCode)
            SummaryCard(title: "Этот месяц", value: savingsSnapshot.monthTotal, currencyCode: currencyCode)
            SummaryCard(title: "Ср. / день", value: savingsSnapshot.avgPerDayThisMonth, currencyCode: currencyCode)
        }
    }

    private var chartsCarouselSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            TabView(selection: $selectedChartPage) {
                chartPage(
                    title: "Накопления за неделю",
                    content: WeeklySavingsBarChart(values: savingsSnapshot.weekDailyTotals)
                )
                .tag(0)

                chartPage(
                    title: "Динамика по месяцам",
                    content: MonthlyDynamicsLineChart(
                        values: savingsSnapshot.monthDynamicsValues,
                        monthLabels: savingsSnapshot.monthDynamicsLabels
                    )
                )
                .tag(1)

                chartPage(
                    title: "Сильные и слабые стороны",
                    content: StatsRadarChart(values: radarValues)
                )
                .tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: chartsCarouselHeight)

            pageIndicator
                .padding(.top, 12)
                .padding(.bottom, 4)
        }
        .cardStyle(cardAppearance)
    }

    private var summaryCharacteristics: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Сильные стороны")
                .fontWeight(.bold)

            StrengthsSummary(values: radarValues)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("Нужно подтянуть")
                .fontWeight(.bold)

            WeaknessesSummary(values: radarValues)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(cardAppearance)
    }

    private func chartPage<Content: View>(title: String, content: Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(index == selectedChartPage ? Color.primary : Color.primary.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
    }
}

private struct SummaryCard: View {
    let title: String
    let value: Int
    let currencyCode: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(CurrencyFormatter.format(Double(value), code: currencyCode))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(
            CardAppearance.default
                .with(
                    foregroundColor: .primary,
                    borderColor: kopiGreen,
                    borderWidth: 5
                )
        )
    }
}

struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        StatsView()
    }
}
