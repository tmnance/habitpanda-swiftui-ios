//
//  DateHelper.swift
//  HabitPandaSwiftUI
//
//  Created by Tim Nance on 10/9/22.
//

import Foundation

struct DateHelper {
    static func getDateString(_ date: Date) -> String {
        if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        }
        if Calendar.current.isDateInToday(date) {
            return "Today"
        }
        if Calendar.current.isDateInTomorrow(date) {
            return "Tomorrow"
        }
        return date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
    }

    static func getDaysBetween(startDate: Date, endDate: Date) -> Int {
        return Calendar.current.dateComponents([.day], from: startDate, to: endDate).day!
    }
}
