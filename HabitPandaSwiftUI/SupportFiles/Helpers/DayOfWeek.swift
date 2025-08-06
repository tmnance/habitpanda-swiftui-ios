//
//  DayOfWeek.swift
//  HabitPandaSwiftUI
//
//  Created by Tim Nance on 10/9/22.
//

import Foundation

struct DayOfWeek {
    // Enum representing days of the week, both as readable strings and bitmask values
    enum Day: Int, CaseIterable {
        // Values are the offset from Sunday (0 to 6)
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
        var bitmaskValue: Int {
            return 1 << self.rawValue
        }

        static func from(offset: Int) -> Day? {
            return Day(rawValue: offset)
        }

        static func from(bitmask: Int) -> Day? {
            return Day(rawValue: Int(log2(Double(bitmask))))
        }
    }

    // Enum for subsets of days, like weekdays, weekends, etc.
    enum WeekSubset: Int {
        case all = 0, weekdays = 1, weekends = 2, custom = 3
        var description: String {
            switch self {
            case .all: return "All"
            case .weekdays: return "Weekdays"
            case .weekends: return "Weekends"
            case .custom: return "Custom"
            }
        }
        var days: Set<Day> {
            switch self {
            case .all: return Set(Day.allCases)
            case .weekdays: return [.mon, .tue, .wed, .thu, .fri]
            case .weekends: return [.sat, .sun]
            case .custom: return []
            }
        }
    }

    // Utility methods for working with bitmask values
    static func convertBitmaskToOffsets(_ bitmask: Int) -> [Int] {
        return Day.allCases
            .filter { (bitmask & $0.bitmaskValue) != 0 }
            .map { $0.rawValue }
    }

    static func convertOffsetsToBitmask(_ offsets: [Int]) -> Int {
        return offsets
            .compactMap { Day.from(offset: $0)?.bitmaskValue }
            .reduce(0, |)
    }
}
