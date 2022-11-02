//
//  DateHelper.swift
//  HabitPandaSwiftUI
//
//  Created by Tim Nance on 10/9/22.
//

import Foundation

struct DateHelper {
    enum DateFormat: String {
        case dateOnly, timeOnly, dateAndTime
    }

    static func getDateString(forDate date: Date, withFormat format: DateFormat) -> String {
        let df = DateFormatter()
        var displayDate = ""

        if format == .dateOnly || format == .dateAndTime {
            df.dateFormat = "EEE, MMMM d"
            displayDate = df.string(from: date)
        }

        if format == .timeOnly || format == .dateAndTime {
            df.dateFormat = "h:mm a"
            displayDate += displayDate == "" ? "" : " at "
            displayDate += df.string(from: date)
        }

        return displayDate
    }

    static func getDaysBetween(startDate: Date, endDate: Date) -> Int {
        return Calendar.current.dateComponents([.day], from: startDate, to: endDate).day!
    }
}
