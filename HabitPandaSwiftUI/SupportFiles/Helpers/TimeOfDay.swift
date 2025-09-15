//
//  TimeOfDay.swift
//  HabitPandaSwiftUI
//
//  Created by Tim Nance on 10/9/22.
//

import Foundation

struct TimeOfDay {
    var hour: Int
    var minute: Int

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = .autoupdatingCurrent
        return formatter
    }()

    func getDisplayTime() -> String {
        return TimeOfDay.getDisplayTime(hour: hour, minute: minute)
    }

    func getTimeInMinutes() -> Int {
        return hour * 60 + minute
    }

    static func getDisplayTime(hour: Int, minute: Int) -> String {
        let components = DateComponents(hour: hour, minute: minute)
        guard let date = Calendar.current.date(from: components) else {
            return "\(hour):\(minute)" // fallback
        }

        return timeFormatter.string(from: date)
    }

    static func generateFromCurrentTime(witMinuteRounding minuteRounding: Int? = nil) -> TimeOfDay {
        var now = Date()
        if minuteRounding != nil {
            now = now.rounded(
                minutes: TimeInterval(minuteRounding!),
                rounding: .floor
            )
        }
        let components = Calendar.current.dateComponents(
            [.hour, .minute],
            from: now
        )
        return TimeOfDay(hour: components.hour!, minute: components.minute!)
    }
}
