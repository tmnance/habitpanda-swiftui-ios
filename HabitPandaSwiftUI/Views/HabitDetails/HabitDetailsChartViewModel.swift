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
    @Published private(set) var chartData: ChartData = .init(rollingSumPoints: [], minYAxisValue: 0, maxYAxisValue: 3)
    private var loadTask: Task<Void, Never>?

    struct RollingSumPoint: Identifiable, Equatable, Sendable {
        var id: Date { date }
        let date: Date
        let rollingSum: Int
    }
    struct ChartData: Equatable, Sendable {
        let rollingSumPoints: [RollingSumPoint]
        let minYAxisValue: Int
        let maxYAxisValue: Int
    }

    func load(habit: Habit, numDates: Int, dayWindow: Int = 7, checkIns: [CheckIn], calendar: Calendar) {
        loadTask?.cancel()
        loadTask = Task {
            let today = Date().stripTime()
            guard let first = habit.getFirstCheckInDate() else {
                let maxY = max(3, Int(habit.frequencyPerWeek) + 1)
                await MainActor.run {
                    self.chartData = ChartData(rollingSumPoints: [], minYAxisValue: 0, maxYAxisValue: maxY)
                }
                return
            }

            let startDate = max(first, calendar.date(byAdding: .day, value: -(numDates - 1), to: today)!.stripTime())
            let endDate = today
            let rollingSumPoints = computeRollingSumPoints(
                startDate: startDate,
                endDate: endDate,
                dayWindow: dayWindow,
                checkIns: checkIns,
                calendar: calendar
            )
            let rollingSumValues = rollingSumPoints.map { $0.rollingSum }
            let minYAxisValue = max(0, min(Int(habit.frequencyPerWeek), rollingSumValues.min() ?? 0) - 1)
            let maxYAxisValue = max(Int(habit.frequencyPerWeek), rollingSumValues.max() ?? 0) + 1

            await MainActor.run {
                self.chartData = ChartData(
                    rollingSumPoints: rollingSumPoints,
                    minYAxisValue: minYAxisValue,
                    maxYAxisValue: maxYAxisValue
                )
            }
        }
    }

    private func computeRollingSumPoints(
        startDate: Date,
        endDate: Date,
        dayWindow: Int,
        checkIns: [CheckIn],
        calendar: Calendar
    ) -> [RollingSumPoint] {
        let intervalDayCount = (calendar.dateComponents(
            [.day],
            from: startDate,
            to: endDate
        ).day ?? 0) + 1
        let startDateOffsetCheckInCountMap = getStartDateOffsetCheckInCountMap(
            fromStartDate: startDate,
            forCheckIns: checkIns,
            calendar: calendar
        )

        var rollingSumPoints: [RollingSumPoint] = []
        var rollingSum = 0

        for startDateOffset in (1 - dayWindow)..<intervalDayCount {
            if startDateOffset >= 1 {
                rollingSum -= startDateOffsetCheckInCountMap[startDateOffset - dayWindow] ?? 0
            }
            rollingSum += startDateOffsetCheckInCountMap[startDateOffset] ?? 0
            // skip over negative
            if startDateOffset >= 0 {
                rollingSumPoints.append(
                    RollingSumPoint(
                        date: calendar.date(
                            byAdding: .day,
                            value: startDateOffset + 1,
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
        fromStartDate startDate: Date,
        forCheckIns checkIns: [CheckIn],
        calendar: Calendar
    ) -> [Int: Int] {
        var startDateOffsetCheckInCountMap: [Int: Int] = [:]

        checkIns.forEach { checkIn in
            let checkInDate = checkIn.checkInDate!.stripTime()
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
