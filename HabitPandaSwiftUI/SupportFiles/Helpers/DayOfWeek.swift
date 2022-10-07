//
//  DayOfWeek.swift
//  HabitPandaSwiftUI
//
//  Created by Tim Nance on 10/9/22.
//

import Foundation

struct DayOfWeek {
    enum WeekSubsetType: Int {
        case daily = 0, weekdays = 1, custom = 2
        var description: String {
            var str: String
            switch self {
            case .daily:
                str = "Daily"
            case .weekdays:
                str = "Weekdays"
            case .custom:
                str = "Custom"
            }
            return str
        }
    }
    enum Day: Int {
        case sun = 0, mon = 1, tue = 2, wed = 3, thu = 4, fri = 5, sat = 6
        var description: String {
            var str: String
            switch self {
            case .sun:
                str = "Sun"
            case .mon:
                str = "Mon"
            case .tue:
                str = "Tue"
            case .wed:
                str = "Wed"
            case .thu:
                str = "Thu"
            case .fri:
                str = "Fri"
            case .sat:
                str = "Sat"
            }
            return str
        }
    }
}
