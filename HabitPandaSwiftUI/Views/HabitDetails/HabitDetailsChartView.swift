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
    private static let maxXAxisGridLines = 6
    private static let height: CGFloat = 250.0
    private static let xAxisDateLabelFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "EEE'\n'M'/'d"
        return df
    }()
    private struct ChartTaskKey: Equatable {
        let habitID: NSManagedObjectID
        let rangeStartDate: Date
        let rangeEndDate: Date
        let rollingWindowDayCount: Int
        let checkInCount: Int
        let lastCheckInID: NSManagedObjectID?
    }

    @StateObject private var vm = HabitDetailsChartViewModel()
    @ObservedObject private var habit: Habit
    private var rangeStartDate: Date
    private var rangeEndDate: Date
    private var targetRangeDayCount: Int
    private var rollingWindowDayCount: Int
    private var earliestCheckInDate: Date?

    @FetchRequest private var checkInsForRangeIncludingWindow: FetchedResults<CheckIn>

    init(
        habit: Habit,
        rangeStartDate: Date,
        rangeEndDate: Date,
        rollingWindowDayCount: Int,
        earliestCheckInDate: Date?
    ) {
        let lookbackStart = Calendar.current.date(byAdding: .day, value: -rollingWindowDayCount, to: rangeStartDate)! // include rolling window
        let lookaheadEnd = Calendar.current.date(byAdding: .day, value: rollingWindowDayCount, to: rangeEndDate)! // include rolling window
        self.habit = habit
        self.rangeStartDate = rangeStartDate
        self.rangeEndDate = rangeEndDate
        self.targetRangeDayCount = Calendar.current.dateComponents(
            [.day],
            from: rangeStartDate,
            to: rangeEndDate
        ).day ?? 0
        self.rollingWindowDayCount = rollingWindowDayCount
        self.earliestCheckInDate = earliestCheckInDate
        _checkInsForRangeIncludingWindow = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \CheckIn.checkInDate, ascending: true)],
            predicate: NSPredicate(
                format: "habit == %@ AND checkInDate >= %@ AND checkInDate <= %@ AND (typeRaw != %@ OR typeRaw == nil)",
                habit,
                lookbackStart as NSDate,
                lookaheadEnd as NSDate,
                CheckInType.dayOff.rawValue
            ),
            animation: .none
        )
    }

    var body: some View {
        VStack {
            Chart {
                let points = vm.chartData.rollingSumPoints
                switch points.count {
                case 0:
                    targetRuleMark
                    emptyStateRuleMark

                case 1:
                    // draw a PointMark when only one
                    if let point = points.first {
                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("Rolling Sum", point.rollingSum)
                        )
                        .lineStyle(.init(lineWidth: 4, lineCap: .round))
                        .foregroundStyle(Color(Constants.Colors.tint))
                    }
                    targetRuleMark

                default:
                    // use LineMark when > 1 point
                    ForEach(points) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Rolling Sum", point.rollingSum)
                        )
                        .lineStyle(.init(lineWidth: 4, lineCap: .round))
                        .foregroundStyle(Color(Constants.Colors.tint))
                        AreaMark(
                            x: .value("Date", point.date),
                            yStart: .value("Chart Cutoff", vm.chartData.yMin),
                            yEnd: .value("Rolling Sum", point.rollingSum)
                        )
                        .foregroundStyle(Color(Constants.Colors.tint).opacity(0.15))
                    }
                    targetRuleMark
                }
            }
            .frame(height: Self.height)
            .padding(.horizontal, 10)
            .chartXAxis {
                AxisMarks(preset: .aligned, values: .automatic(desiredCount: Self.maxXAxisGridLines)) { value in
                    AxisGridLine(centered: false, stroke: StrokeStyle(lineWidth: 1, dash: [10, 10]))
                        .foregroundStyle(Color(Constants.Colors.chartGrid))
                    AxisValueLabel(centered: false) {
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
            .chartYScale(domain: vm.chartData.yMin ... vm.chartData.yMax)
            .chartXScale(domain: rangeStartDate ... rangeEndDate)
            .task(id: ChartTaskKey(
                habitID: habit.objectID,
                rangeStartDate: rangeStartDate,
                rangeEndDate: rangeEndDate,
                rollingWindowDayCount: rollingWindowDayCount,
                checkInCount: checkInsForRangeIncludingWindow.count,
                lastCheckInID: checkInsForRangeIncludingWindow.last?.objectID
            )) {
                let checkInDates = checkInsForRangeIncludingWindow.compactMap { $0.checkInDate?.stripTime() }
                let hasCheckInsBeforeRange: Bool = {
                    guard let earliestCheckInDate else { return false } // no check-ins yet
                    guard let startOfRange = checkInDates.first else { return true } // check-ins exist prior to empty range
                    return earliestCheckInDate < startOfRange
                }()
                guard let earliestCheckInDate, earliestCheckInDate <= rangeEndDate else { // no check-ins in range
                    vm.reset(target: Int(habit.frequencyPerWeek))
                    return
                }

                let startDate = (hasCheckInsBeforeRange ? rangeStartDate : max(rangeStartDate, checkInDates.first ?? rangeStartDate))
                let endDate = rangeEndDate
                
                vm.loadRange(
                    startDate: startDate,
                    endDate: endDate,
                    checkInDates: checkInDates,
                    target: Int(habit.frequencyPerWeek),
                    rollingWindowDayCount: rollingWindowDayCount,
                    calendar: calendar
                )
            }
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
        RuleMark(y: .value("Zero check ins", (vm.chartData.yMin + vm.chartData.yMax) / 2))
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
    let today = Date().stripTime()
    let targetRangeDayCount = 14
    let rollingWindowDayCount = 7
    HabitDetailsChartView(
        habit: Habit.example,
        rangeStartDate: Calendar.current.date(byAdding: .day, value: -(targetRangeDayCount - 1), to: today)!,
        rangeEndDate: today,
        rollingWindowDayCount: rollingWindowDayCount,
        earliestCheckInDate: Habit.example.getFirstCheckInDate()
    )
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
