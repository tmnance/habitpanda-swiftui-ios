//
//  HabitDetailsChartView.swift
//  HabitPandaSwiftUI
//
//  Created by Tim Nance on 11/1/22.
//

import SwiftUI
import CoreData
import Charts

struct HabitDetailsChartView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.calendar) private var calendar

    private static let maxYAxisGridLines = 7
    private static let height: CGFloat = 250.0
    private static let xAxisDateLabelFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "EEE'\n'M'/'d"
        return df
    }()
    private struct ChartTaskKey: Equatable {
        let habitID: NSManagedObjectID
        let numDates: Int
        let checkInCount: Int
        let lastCheckInID: NSManagedObjectID?
    }

    @StateObject private var vm = HabitDetailsChartViewModel()
    @ObservedObject private var habit: Habit
    @State private var today: Date
    @State private var numDates = 14

    @FetchRequest private var checkIns: FetchedResults<CheckIn>

    init(habit: Habit, numDates: Int = 14) {
        let today = Date().stripTime()
        let lookbackStart = Calendar.current.date(byAdding: .day, value: -(numDates + 7), to: today)! // include rolling window
        self.habit = habit
        self._numDates = State(initialValue: numDates)
        _today = State(initialValue: today)
        _checkIns = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \CheckIn.checkInDate, ascending: true)],
            predicate: NSPredicate(format: "habit == %@ AND checkInDate >= %@", habit, lookbackStart as NSDate),
            animation: .none
        )
    }

    var body: some View {
        Chart {
            ForEach(vm.chartData.rollingSumPoints) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Rolling Sum", point.rollingSum)
                )
                .lineStyle(.init(lineWidth: 4, lineCap: .round))
                .foregroundStyle(Color(Constants.Colors.tint))
                AreaMark(
                    x: .value("Date", point.date),
                    yStart: .value("Chart Cutoff", vm.chartData.minYAxisValue),
                    yEnd: .value("Rolling Sum", point.rollingSum)
                )
                .foregroundStyle(Color(Constants.Colors.tint).opacity(0.15))
            }

            targetRuleMark
            if vm.chartData.rollingSumPoints.count == 0 {
                emptyStateRuleMark
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
                    .foregroundStyle(Color(.systemBackground))
                
                AxisValueLabel(centered: true) {
                    if let dateValue = value.as(Date.self) {
                        Text(Self.xAxisDateLabelFormatter.string(from: dateValue))
                            .foregroundColor(Color(Constants.Colors.labelText))
                            .font(.system(size: 10))
                            .multilineTextAlignment(.center)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: Self.maxYAxisGridLines)) { value in
                AxisGridLine(centered: true, stroke: StrokeStyle(lineWidth: 1))
                    .foregroundStyle(Color(Constants.Colors.chartGrid))
                AxisValueLabel {
                    if let intValue = value.as(Int.self) {
                        Text("\(intValue)")
                            .foregroundColor(Color(Constants.Colors.labelText))
                            .font(.system(size: 10))
                    }
                }
            }
        }
        .chartYScale(domain: vm.chartData.minYAxisValue ... vm.chartData.maxYAxisValue)
        .chartXScale(domain:
                        calendar.date(byAdding: .day, value: (-1 * numDates) + 2, to: today)! ...
                     calendar.date(byAdding: .day, value: 1, to: today)!
        )
        .frame(height: Self.height)
        .onNewDay {
            today = Date().stripTime()
        }
        .task(id: ChartTaskKey(
            habitID: habit.objectID,
            numDates: numDates,
            checkInCount: checkIns.count,
            lastCheckInID: checkIns.last?.objectID
        )) {
            vm.load(habit: habit, numDates: numDates, checkIns: Array(checkIns), calendar: calendar)
        }
    }

    var targetRuleMark: some ChartContent {
        RuleMark(y: .value("🎯\(habit.frequencyPerWeek)x/wk", habit.frequencyPerWeek))
            .lineStyle(.init(lineWidth: 2, lineCap: .round, dash: [10, 10]))
            .foregroundStyle(Color(Constants.Colors.tint2))
            .annotation(position: .overlay, alignment: .leading) {
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text("🎯").baselineOffset(1)
                    Text("\(habit.frequencyPerWeek)x/wk")
                }
                .foregroundColor(Color(Constants.Colors.subText))
                .font(.system(size: 12))
                .padding(EdgeInsets(top: 0, leading: 4, bottom: 2, trailing: 4))
                .background(Color(.systemBackground).opacity(0.8))
                .cornerRadius(15)
            }
    }
    var emptyStateRuleMark: some ChartContent {
        RuleMark(y: .value("Zero check ins", (vm.chartData.minYAxisValue + vm.chartData.maxYAxisValue) / 2))
            .annotation(position: .overlay, alignment: .center) {
                Text("No check-in data yet")
                    .font(.footnote)
                    .padding(8)
                    .background(Color(.systemBackground))
            }
            .foregroundStyle(Color(Constants.Colors.clear))
    }
}

#Preview {
    HabitDetailsChartView(habit: Habit.example)
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
