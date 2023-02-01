//
//  HabitDetailsSummaryTabChartView.swift
//  HabitPandaSwiftUI
//
//  Created by Tim Nance on 11/1/22.
//

import SwiftUI
import Charts

struct HabitDetailsSummaryTabChartView: View {
    @Environment(\.managedObjectContext) private var viewContext
    static let maxYAxisGridLines = 7.0

    private struct DailyCheckInRollingAverage: Identifiable {
        var id = UUID()
        var date: Date
        var rollingAverage: Double
    }
    private struct ChartData {
        var dailyCheckInRollingAverageData: [DailyCheckInRollingAverage]
        var minYAxisValue: Double
        var maxYAxisValue: Double
    }

    @ObservedObject var habit: Habit
    @State var numDates = 14

    private var chartData: ChartData {
        guard let firstCheckInDate = habit.getFirstCheckInDate() else {
            return ChartData(
                dailyCheckInRollingAverageData: [],
                minYAxisValue: 0,
                // no less than 3 to prevent overlap of frequency marker and "no data" text
                maxYAxisValue: max(3, Double(habit.frequencyPerWeek) + 1)
            )
        }

        let currentDate = Date().stripTime()
        let startDate = max(
            firstCheckInDate,
            Calendar.current.date(
                byAdding: .day,
                value: -1 * (numDates - 1),
                to: currentDate
            )!
        ).stripTime()

        let data = getCheckInFrequencyRollingAverageData(fromStartDate: startDate)
        let dataValues = data.map { $0.rollingAverage }
        return ChartData(
            dailyCheckInRollingAverageData: data,
            minYAxisValue: max(0, min(Double(habit.frequencyPerWeek), dataValues.min() ?? 0) - 1),
            maxYAxisValue: max(Double(habit.frequencyPerWeek), dataValues.max() ?? 0) + 1
        )
    }

    var body: some View {
        let chartData = chartData // prevent recalculations within the same view draw

        Chart {
            ForEach(
                Array(chartData.dailyCheckInRollingAverageData.enumerated()),
                id: \.offset
            ) { offset, element in
                LineMark(
                    x: .value("Date", element.date),
                    y: .value("Rolling Average", element.rollingAverage)
                )
                .lineStyle(.init(lineWidth: 4, lineCap: .round))
                .foregroundStyle(Color(Constants.Colors.tint))
            }
            if chartData.dailyCheckInRollingAverageData.count == 0 {
                RuleMark(y: .value("Zero check ins", (chartData.minYAxisValue + chartData.maxYAxisValue) / 2))
                    .annotation(position: .overlay, alignment: .center) {
                        Text("No check-in data yet")
                            .font(.footnote)
                            .padding(8)
                            .background(Color(UIColor.systemBackground))
                    }
                    .foregroundStyle(Color(Constants.Colors.clear))
            }
            RuleMark(y: .value("🎯\(habit.frequencyPerWeek)x/wk", habit.frequencyPerWeek))
                .lineStyle(.init(lineWidth: 2, lineCap: .round, dash: [10, 10]))
                .foregroundStyle(Color(Constants.Colors.tint2))
                .annotation(position: .overlay, alignment: .leading) {
                    Group {
                        Text("🎯").baselineOffset(1) +
                        Text("\(habit.frequencyPerWeek)x/wk")
                    }
                    .foregroundColor(Color(Constants.Colors.subText))
                    .font(.system(size: 12))
                    .padding(EdgeInsets(top: 0, leading: 4, bottom: 2, trailing: 4))
                    .background(Color(UIColor.systemBackground).opacity(0.8))
                    .cornerRadius(15)
                }
        }
        .chartXAxis {
            AxisMarks(
                values: .stride(by: .day, count: 1, roundLowerBound: true, roundUpperBound: true)
            ) { _ in
                AxisGridLine(centered: true, stroke: StrokeStyle(lineWidth: 1, dash: [10, 10]))
                    .foregroundStyle(Color(Constants.Colors.chartGrid))
            }
            AxisMarks(values: .stride(by: .day, count: 2, roundLowerBound: true, roundUpperBound: true)) { value in
                // paint over (erase) every other day, in effect centers the labels and the remaining vertical lines
                AxisGridLine(centered: true, stroke: StrokeStyle(lineWidth: 1, dash: [10, 10]))
                    .foregroundStyle(Color(UIColor.systemBackground))

                AxisValueLabel(centered: true) {
                    if let dateValue = value.as(Date.self) {
                        Text(getXAxisDisplayDate(dateValue))
                            .foregroundColor(Color(Constants.Colors.label))
                            .font(.system(size: 10))
                            .multilineTextAlignment(.center)
                    }
                }
            }
        }
        .chartYAxis{
            AxisMarks(
                position: .leading,
                values: .stride(by: ceil((chartData.maxYAxisValue - chartData.minYAxisValue) / HabitDetailsSummaryTabChartView.maxYAxisGridLines))
            ) { value in
                AxisGridLine(centered: true, stroke: StrokeStyle(lineWidth: 1))
                    .foregroundStyle(Color(Constants.Colors.chartGrid))
                AxisValueLabel() {
                    if let intValue = value.as(Int.self) {
                        Text("\(intValue)")
                            .foregroundColor(Color(Constants.Colors.label))
                            .font(.system(size: 10))
                    }
                }
            }
        }
        .chartPlotStyle { plotContent in
            plotContent
                .border(Color.blue, width: 0)
        }
        .chartYScale(domain: chartData.minYAxisValue ... chartData.maxYAxisValue)
        .chartXScale(domain:
                        Calendar.current.date(byAdding: .day, value: (-1 * numDates) + 2, to: Date().stripTime())! ...
                     Calendar.current.date(byAdding: .day, value: 1, to: Date().stripTime())!
        )
        .frame(height: 250)
    }

    private func getXAxisDisplayDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "EEE'\n'M'/'d"
        return df.string(from: date)
    }
}


// MARK: - Rolling average calculation
extension HabitDetailsSummaryTabChartView {
    private func getCheckInFrequencyRollingAverageData(
        fromStartDate startDate: Date? = nil,
        toEndDate endDate: Date? = nil,
        withDayWindow dayWindow: Int = 7
    ) -> [DailyCheckInRollingAverage] {
        let startDate = (startDate ?? habit.createdAt!).stripTime()
        let endDate = (endDate ?? Date()).stripTime()
        let intervalDayCount = (Calendar.current.dateComponents(
            [.day],
            from: startDate,
            to: endDate
        ).day ?? 0) + 1

        // get extra days before startDate to be used in rolling average calculations
        let startDateIncludingWindow = Calendar.current.date(
            byAdding: .day,
            value: (1 - dayWindow),
            to: startDate
        )!
        let checkIns = CheckIn.getAll(
            sortedBy: [("checkInDate", .asc)],
            forHabitUUIDs: [habit.uuid!],
            fromStartDate: startDateIncludingWindow,
            toEndDate: endDate,
            context: viewContext
        )

        let startDateOffsetCheckInCountMap = getStartDateOffsetCheckInCountMap(
            fromStartDate: startDate,
            forCheckIns: checkIns
        )

        var checkInFrequencyRollingAverageData: [DailyCheckInRollingAverage] = []
        var rollingSum = 0

        for startDateOffset in (1 - dayWindow)..<intervalDayCount {
            if startDateOffset >= 1 {
                rollingSum -= startDateOffsetCheckInCountMap[startDateOffset - dayWindow] ?? 0
            }
            rollingSum += startDateOffsetCheckInCountMap[startDateOffset] ?? 0
            // skip over negative
            if startDateOffset >= 0 {
                checkInFrequencyRollingAverageData.append(
                    DailyCheckInRollingAverage(
                        date: Calendar.current.date(
                            byAdding: .day,
                            value: startDateOffset + 1,
                            to: startDate
                        )!,
                        rollingAverage: Double(rollingSum)
                    )
                )
            }
        }

        return checkInFrequencyRollingAverageData
    }

    private func getStartDateOffsetCheckInCountMap(
        fromStartDate startDate: Date,
        forCheckIns checkIns: [CheckIn]
    ) -> [Int: Int] {
        var startDateOffsetCheckInCountMap: [Int: Int] = [:]

        checkIns.forEach { checkIn in
            let checkInDate = checkIn.checkInDate!.stripTime()
            let startDateOffset = Calendar.current.dateComponents(
                [.day],
                from: startDate,
                to: checkInDate
            ).day ?? 0
            startDateOffsetCheckInCountMap[startDateOffset] = (startDateOffsetCheckInCountMap[startDateOffset] ?? 0) + 1
        }

        return startDateOffsetCheckInCountMap
    }
}


struct HabitSummaryChartView_Previews: PreviewProvider {
    static var previews: some View {
        HabitDetailsSummaryTabChartView(habit: Habit.example)
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
