
import SwiftUI
import DGCharts

struct WeeklySavingsBarChart: UIViewRepresentable {
    var values: [Double]

    func makeUIView(context: Context) -> BarChartView {
        let chart = BarChartView()
        chart.legend.enabled = false
        chart.rightAxis.enabled = false
        chart.xAxis.labelPosition = .bottom
        chart.xAxis.drawGridLinesEnabled = false
        chart.xAxis.granularity = 1
        chart.leftAxis.axisMinimum = 0
        chart.leftAxis.drawGridLinesEnabled = true
        chart.leftAxis.gridColor = UIColor.systemGray5
        chart.extraTopOffset = 8
        chart.extraBottomOffset = 4

        // Динамичные цвета под тёмную/светлую темы
        chart.backgroundColor = .clear
        chart.xAxis.labelTextColor = .secondaryLabel
        chart.leftAxis.labelTextColor = .secondaryLabel
        chart.xAxis.axisLineColor = .separator
        chart.leftAxis.axisLineColor = .separator

        return chart
    }

    func updateUIView(_ chart: BarChartView, context: Context) {
        let entries = values.enumerated().map { BarChartDataEntry(x: Double($0.offset), y: $0.element) }
        let set = BarChartDataSet(entries: entries)
        set.colors = [NSUIColor.systemBlue]
        set.drawValuesEnabled = false
        let data = BarChartData(dataSet: set)
        data.barWidth = 0.5
        chart.data = data
        chart.xAxis.valueFormatter = WeekDayAxisFormatter()

        // На случай смены темы — переустановим динамичные цвета
        chart.xAxis.labelTextColor = .secondaryLabel
        chart.leftAxis.labelTextColor = .secondaryLabel
        chart.xAxis.axisLineColor = .separator
        chart.leftAxis.axisLineColor = .separator

        chart.animate(yAxisDuration: 0.3)
    }
}

private final class WeekDayAxisFormatter: NSObject, AxisValueFormatter {
    private let labels = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
    func stringForValue(_ value: Double, axis: DGCharts.AxisBase?) -> String {
        let i = Int(value)
        guard i >= 0, i < labels.count else { return "" }
        return labels[i]
    }
}



struct MonthlyDynamicsLineChart: UIViewRepresentable {
    var values: [Double]
    var monthLabels: [String]

    func makeUIView(context: Context) -> LineChartView {
        let chart = LineChartView()
        chart.legend.enabled = false
        chart.rightAxis.enabled = false
        chart.xAxis.labelPosition = .bottom
        chart.xAxis.drawGridLinesEnabled = false
        chart.xAxis.granularity = 1
        chart.leftAxis.axisMinimum = 0
        chart.leftAxis.drawGridLinesEnabled = true
        chart.leftAxis.gridColor = UIColor.systemGray5
        chart.extraTopOffset = 8
        chart.extraBottomOffset = 4

        // Динамичные цвета
        chart.backgroundColor = .clear
        chart.xAxis.labelTextColor = .secondaryLabel
        chart.leftAxis.labelTextColor = .secondaryLabel
        chart.xAxis.axisLineColor = .separator
        chart.leftAxis.axisLineColor = .separator

        return chart
    }

    func updateUIView(_ chart: LineChartView, context: Context) {
        let entries = values.enumerated().map { ChartDataEntry(x: Double($0.offset), y: $0.element) }
        let set = LineChartDataSet(entries: entries)
        set.colors = [NSUIColor.systemBlue]
        set.setCircleColor(NSUIColor.systemBlue)
        set.lineWidth = 2
        set.circleRadius = 4
        set.drawValuesEnabled = false
        set.mode = .linear
        chart.data = LineChartData(dataSet: set)
        chart.xAxis.valueFormatter = MonthAxisFormatter(labels: monthLabels)

        // На случай смены темы — переустановим динамичные цвета
        chart.xAxis.labelTextColor = .secondaryLabel
        chart.leftAxis.labelTextColor = .secondaryLabel
        chart.xAxis.axisLineColor = .separator
        chart.leftAxis.axisLineColor = .separator

        chart.animate(yAxisDuration: 0.3)
    }
}

private final class MonthAxisFormatter: NSObject, AxisValueFormatter {
    let labels: [String]
    init(labels: [String]) { self.labels = labels }
    func stringForValue(_ value: Double, axis: DGCharts.AxisBase?) -> String {
        let i = Int(value)
        guard i >= 0, i < labels.count else { return "" }
        return labels[i]
    }
}

// MARK: - Сильные и слабые стороны (Radar Chart)

struct StatsRadarChart: UIViewRepresentable {
    
    var values: [Double]

    static let axisLabels = ["Дисциплина", "Планирование", "Дружба", "Активность", "Мотивация"]

    func makeUIView(context: Context) -> RadarChartView {
        let chart = RadarChartView()
        chart.legend.enabled = false
        chart.yAxis.axisMinimum = 0
        chart.yAxis.axisMaximum = 100
        chart.yAxis.drawLabelsEnabled = false
        chart.webLineWidth = 0.5
        chart.innerWebLineWidth = 0.5
        chart.extraTopOffset = 10
        chart.extraBottomOffset = 10

        // Динамичные цвета
        chart.backgroundColor = .clear
        chart.xAxis.labelTextColor = .secondaryLabel
        chart.webColor = .separator
        chart.innerWebColor = .separator

        return chart
    }

    func updateUIView(_ chart: RadarChartView, context: Context) {
        let entries = values.enumerated().map { RadarChartDataEntry(value: $0.element) }
        let set = RadarChartDataSet(entries: entries)
        set.colors = [NSUIColor.systemBlue]
        set.fillColor = NSUIColor.systemBlue.withAlphaComponent(0.3)
        set.drawFilledEnabled = true
        set.lineWidth = 2
        set.drawValuesEnabled = false
        chart.data = RadarChartData(dataSet: set)
        chart.xAxis.valueFormatter = RadarAxisFormatter(labels: Self.axisLabels)

        // Обновим динамичные цвета при перерисовке
        chart.xAxis.labelTextColor = .secondaryLabel
        chart.webColor = .separator
        chart.innerWebColor = .separator

        chart.animate(yAxisDuration: 0.3)
    }
}

struct SummaryItem: Identifiable {
    let id = UUID()
    let title: String
    let value: Double
}


struct StrengthsSummary: View {
    var values: [Double]

    private var topItems: [SummaryItem] {
        Array(
            zip(StatsRadarChart.axisLabels, values)
                .map { SummaryItem(title: $0.0, value: $0.1) }
                .sorted { $0.value > $1.value }
                .prefix(2)
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(topItems) { item in
                HStack(spacing: 10) {
                    Image(systemName: "checkmark")
                        .foregroundColor(.green)
                        .font(.system(size: 16, weight: .bold))

                    Text(item.title)
                        .fontWeight(.semibold)

                    Text("\(Int(item.value))%")
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

struct WeaknessesSummary: View {
    var values: [Double]

    private var weakItems: [SummaryItem] {
        Array(
            zip(StatsRadarChart.axisLabels, values)
                .map { SummaryItem(title: $0.0, value: $0.1) }
                .sorted { $0.value < $1.value }
                .prefix(2)
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(weakItems) { item in
                HStack(spacing: 10) {
                    Image(systemName: "arrow.up")
                        .foregroundColor(.orange)
                        .font(.system(size: 16, weight: .bold))

                    Text(item.title)
                        .fontWeight(.semibold)

                    Text("\(Int(item.value))%")
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

private final class RadarAxisFormatter: NSObject, AxisValueFormatter {
    let labels: [String]
    init(labels: [String]) { self.labels = labels }
    func stringForValue(_ value: Double, axis: DGCharts.AxisBase?) -> String {
        let i = Int(value)
        guard i >= 0, i < labels.count else { return "" }
        return labels[i]
    }
}
