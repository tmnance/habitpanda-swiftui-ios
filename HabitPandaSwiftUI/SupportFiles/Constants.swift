//
//  Constants.swift
//  HabitPandaSwiftUI
//
//  Created by Tim Nance on 10/7/22.
//

import SwiftUI

struct Constants {
    static let minTappableDimension: CGFloat = 44
    static let comfortableTappableDimension: CGFloat = 46

    struct Colors {
        static let clear = Color.clear
        static let labelText = Color("labelText")

        static let mainViewBg = Color("mainViewBg")

        static let tint = Color("tint")
        static let textForTintBackground = Color("textForTintBackground")

        static let tint2 = Color("tint2")
        static let disabledText = Color("disabledText")
        static let subText = Color("subText")

        static let popupOverlayBg = Color("popupOverlayBg")
        static let popupButtonSeparator = Color("popupButtonSeparator")

        static let chartGrid = Color("chartGrid")

        static let listWeekdayBg1 = Color("listWeekdayBg1")
        static let listWeekdayBg2 = Color("listWeekdayBg2")
        static let listWeekendBg = Color("listWeekendBg")
        static let listCheckmark = Color("listCheckmark")
        static let listRowOverlayBg = Color("listRowOverlayBg")
        static let listBorder = Color("listBorder")

        static let checkInButtonBorder = Color("checkInButtonBorder")
        static let checkInButtonText = Color("checkInButtonText")
        static let deleteButtonBorder = Color("deleteButtonBorder")
        static let deleteButtonText = Color("deleteButtonText")

        static let toastText = Color("toastText")
        static let toastBg = Color("toastBg")
        static let toastShadow = Color("toastShadow")
        static let toastAccentSuccess = Color("toastAccentSuccess")
        static let toastAccentError = Color("toastAccentError")
        static let toastAccentWarning = Color("toastAccentWarning")
        static let toastAccentInfo = Color("toastAccentInfo")
    }

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

    enum SortDir: String {
        case asc, desc
    }

    enum FirstOrLast: String {
        case first, last
    }

    enum ViewInteractionMode {
        case add, edit
    }
}
