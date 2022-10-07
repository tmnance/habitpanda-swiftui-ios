//
//  TimeOfDay.swift
//  HabitPandaSwiftUI
//
//  Created by Tim Nance on 10/9/22.
//

import Foundation

public struct TimeOfDay {
    var hour: Int
    var minute: Int

    func getDisplayDate() -> String {
        return TimeOfDay.getDisplayDate(hour: hour, minute: minute)
    }

    func getTimeInMinutes() -> Int {
        return hour * 60 + minute
    }

    static func getDisplayDate(hour: Int, minute: Int) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat =  "HH:mm"
        let date = dateFormatter.date(from: "\(hour):\(minute)")
        dateFormatter.dateFormat = "h:mm a"
        return dateFormatter.string(from: date!)
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
