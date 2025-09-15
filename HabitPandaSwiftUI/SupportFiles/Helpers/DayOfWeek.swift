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
            // Left shift 1 by rawValue positions to create a bitmask
            // For example: Day.mon (rawValue=1) becomes 1 << 1 = 2 (binary: 10)
            // This creates a unique bit position for each day of the week
            return 1 << self.rawValue
        }

        static func from(offset: Int) -> Day? {
            return Day(rawValue: offset)
        }

        static func from(bitmask: Int) -> Day? {
            // Ensure we have a valid positive number
            guard bitmask > 0 else { return nil }

            // trailingZeroBitCount returns the number of trailing (rightmost) zero bits
            // For example: 8 (binary: 1000) has 3 trailing zeros, so trailingZeroBitCount = 3
            // This gives us the position of the rightmost set bit (0-indexed from the right)
            let rawValue = bitmask.trailingZeroBitCount

            // Verify that the bitmask has exactly one bit set by reconstructing it
            // (1 << rawValue) creates a number with only one bit set at position rawValue
            // For example: 1 << 3 = 8 (binary: 1000)
            // If this equals the original bitmask, then the bitmask had exactly one bit set
            return (1 << rawValue) == bitmask ? Day(rawValue: rawValue) : nil
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
        // Convert a bitmask (like 42 = 101010) back to an array of day offsets
        return Day.allCases
            .filter { (bitmask & $0.bitmaskValue) != 0 }
            .map { $0.rawValue }
    }

    static func convertOffsetsToBitmask(_ offsets: [Int]) -> Int {
        // Convert an array of day offsets to a single bitmask
        // For each offset, get the corresponding day's bitmaskValue
        // Combine all bitmaskValues using bitwise OR (|) to create the final bitmask
        // For example: [0, 2, 4] becomes 1 | 4 | 16 = 21 (binary: 10101)
        return offsets
            .compactMap { Day.from(offset: $0)?.bitmaskValue }
            .reduce(0, |)
    }
}
