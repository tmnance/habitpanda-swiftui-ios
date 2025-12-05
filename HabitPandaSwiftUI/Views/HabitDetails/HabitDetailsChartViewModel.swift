//
//  HabitDetailsChartViewModel.swift
//  HabitPandaSwiftUI
//
//  Created by Tim Nance on 12/4/25.
//

import SwiftUI
import CoreData
import Charts

final class HabitDetailsChartViewModel: ObservableObject {
    @Published private(set) var chartData: ChartData = .init(rollingSumPoints: [], yMin: 0, yMax: 3)
    private var loadTask: Task<Void, Never>?

    deinit { loadTask?.cancel() }

    struct RollingSumPoint: Identifiable, Equatable, Sendable {
        var id: Date { date }
        let date: Date
        let rollingSum: Int
    }
    struct ChartData: Equatable, Sendable {
        let rollingSumPoints: [RollingSumPoint]
        let yMin: Int
        let yMax: Int
    }

    func reset(target: Int) {
        self.chartData = ChartData(
            rollingSumPoints: [],
            yMin: 0,
            yMax: max(3, target + 1)
        )
    }

    func loadRange(
        startDate: Date,
        endDate: Date,
        checkInDates: [Date],
//        hasCheckInsBeforeRange: Bool,
        target: Int,
//        targetRangeDayCount: Int,
        rollingWindowDayCount: Int,
        calendar: Calendar
    ) {
        loadTask?.cancel()
        loadTask = Task {
            guard !Task.isCancelled else { return }
//            guard let firstCheckInDate = checkInDates.first else {
//                let maxY = max(3, target + 1)
//                await MainActor.run {
//                    reset(target: target)
//                }
//                return
//            }

//            let today = Date().stripTime()
//            let startDate = (hasCheckInsBeforeRange ?
//                             calendar.date(byAdding: .day, value: -(targetRangeDayCount - 1), to: today)! :
//                                firstCheckInDate)
//            let endDate = today
            let rollingSumPoints = computeRollingSumPoints(
                startDate: startDate,
                endDate: endDate,
                rollingWindowDayCount: rollingWindowDayCount,
                checkInDates: checkInDates,
                calendar: calendar
            )
            let rollingSumValues = rollingSumPoints.map { $0.rollingSum }
            let yMin = max(0, min(target, rollingSumValues.min() ?? 0) - 1)
            let yMax = max(target, rollingSumValues.max() ?? 0) + 1

            await MainActor.run {
                self.chartData = ChartData(
                    rollingSumPoints: rollingSumPoints,
                    yMin: yMin,
                    yMax: yMax
                )
                print("loaded")
                print("checkInDates: \(checkInDates)")
                print("\(rollingSumPoints)")

            }
        }
    }

    private func computeRollingSumPoints(
        startDate: Date,
        endDate: Date,
        rollingWindowDayCount: Int,
        checkInDates: [Date],
        calendar: Calendar
    ) -> [RollingSumPoint] {
        let intervalDayCount = (calendar.dateComponents(
            [.day],
            from: startDate,
            to: endDate
        ).day ?? 0) + 1
        let startDateOffsetCheckInCountMap = getStartDateOffsetCheckInCountMap(
            startDate: startDate,
            checkInDates: checkInDates,
            calendar: calendar
        )

        var rollingSumPoints: [RollingSumPoint] = []
        var rollingSum = 0

        for startDateOffset in (1 - rollingWindowDayCount)..<intervalDayCount {
            if startDateOffset >= 1 {
                rollingSum -= startDateOffsetCheckInCountMap[startDateOffset - rollingWindowDayCount] ?? 0
            }
            rollingSum += startDateOffsetCheckInCountMap[startDateOffset] ?? 0
            // skip over negative
            if startDateOffset >= 0 {
                rollingSumPoints.append(
                    RollingSumPoint(
                        date: calendar.date(
                            byAdding: .day,
                            value: startDateOffset,
                            to: startDate
                        )!,
                        rollingSum: rollingSum
                    )
                )
            }
        }

        return rollingSumPoints
    }

    private func getStartDateOffsetCheckInCountMap(
        startDate: Date,
        checkInDates: [Date],
        calendar: Calendar
    ) -> [Int: Int] {
        var startDateOffsetCheckInCountMap: [Int: Int] = [:]

        checkInDates.forEach { checkInDate in
            let startDateOffset = calendar.dateComponents(
                [.day],
                from: startDate,
                to: checkInDate
            ).day ?? 0
            startDateOffsetCheckInCountMap[startDateOffset, default: 0] += 1
        }

        return startDateOffsetCheckInCountMap
    }
}
