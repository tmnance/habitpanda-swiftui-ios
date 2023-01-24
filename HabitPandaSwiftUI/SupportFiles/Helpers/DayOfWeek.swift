//
//  DayOfWeek.swift
//  HabitPandaSwiftUI
//
//  Created by Tim Nance on 10/9/22.
//

import Foundation

struct DayOfWeek {
    enum WeekSubsetType: Int {
        case daily = 0, weekdays = 1, weekends = 2, custom = 3
        var description: String {
            switch self {
            case .daily: return "Daily"
            case .weekdays: return "Weekdays"
            case .weekends: return "Weekend"
            case .custom: return "Custom"
            }
        }
        var frequencyDays: Set<Day> {
            switch self {
            case .daily: return [.sun, .mon, .tue, .wed, .thu, .fri, .sat]
            case .weekdays: return [.mon, .tue, .wed, .thu, .fri]
            case .weekends: return [.sat, .sun]
            case .custom: return []
            }
        }
    }
    enum Day: Int, CaseIterable {
        case sun = 0, mon = 1, tue = 2, wed = 3, thu = 4, fri = 5, sat = 6
        var description: String {
            switch self {
            case .sun: return "Sun"
            case .mon: return "Mon"
            case .tue: return "Tue"
            case .wed: return "Wed"
            case .thu: return "Thu"
            case .fri: return "Fri"
            case .sat: return "Sat"
            }
        }
    }
}
