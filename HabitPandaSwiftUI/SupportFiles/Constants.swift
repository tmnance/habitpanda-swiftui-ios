//
//  Constants.swift
//  HabitPandaSwiftUI
//
//  Created by Tim Nance on 10/7/22.
//

import Foundation

public struct Constants {
    struct Habit {
        // mirrors the default Habit.frequencyPerWeek attribute in DataModel.xcdatamodel
        static let defaultFrequencyPerWeek = 1
    }

    struct Reminder {
        static let maxReminderNotificationCount = 50
    }

    struct TimePicker {
        static let minuteInterval = 5
    }

    public enum SortDir: String {
        case asc, desc
    }

    public enum ViewInteractionMode {
        case add, edit, view
    }
}
