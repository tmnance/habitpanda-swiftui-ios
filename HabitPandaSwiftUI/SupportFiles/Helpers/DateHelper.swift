//
//  DateHelper.swift
//  HabitPandaSwiftUI
//
//  Created by Tim Nance on 10/9/22.
//

import Foundation

struct DateHelper {
    static func getDateString(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "Today, \(date.formatted(.dateTime.day().month(.abbreviated)))"
        }
        if Calendar.current.isDateInYesterday(date) {
            return "Yesterday, \(date.formatted(.dateTime.day().month(.abbreviated)))"
        }
        return date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
    }

    static func getDaysBetween(startDate: Date, endDate: Date) -> Int {
        return Calendar.current.dateComponents([.day], from: startDate, to: endDate).day!
    }
}
