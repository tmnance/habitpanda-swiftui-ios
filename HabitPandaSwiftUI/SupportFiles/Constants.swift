//
//  Constants.swift
//  HabitPandaSwiftUI
//
//  Created by Tim Nance on 10/7/22.
//

import UIKit

public struct Constants {
    static let minTappableDimension: CGFloat = 44
    static let comfortableTappableDimension: CGFloat = 46

    struct Colors {
        static let clear = UIColor.clear
        static let label = UIColor(named: "label")!

        static let mainViewBg = UIColor(named: "mainViewBg")!

        static let tint = UIColor(named: "tint")!
        static let textForTintBackground = UIColor(named: "textForTintBackground")!

        static let tint2 = UIColor(named: "tint2")!
        static let disabledText = UIColor(named: "disabledText")!
        static let subText = UIColor(named: "subText")!

        static let popupOverlayBg = UIColor(named: "popupOverlayBg")!
        static let popupButtonSeparator = UIColor(named: "popupButtonSeparator")!

        static let chartGrid = UIColor(named: "chartGrid")!

        static let listWeekdayBg1 = UIColor(named: "listWeekdayBg1")!
        static let listWeekdayBg2 = UIColor(named: "listWeekdayBg2")!
        static let listWeekendBg = UIColor(named: "listWeekendBg")!
        static let listCheckmark = UIColor(named: "listCheckmark")!
        static let listRowOverlayBg = UIColor(named: "listRowOverlayBg")!
        static let listBorder = UIColor(named: "listBorder")!

        static let checkInButtonBorder = UIColor(named: "checkInButtonBorder")!
        static let checkInButtonText = UIColor(named: "checkInButtonText")!
        static let deleteButtonBorder = UIColor(named: "deleteButtonBorder")!
        static let deleteButtonText = UIColor(named: "deleteButtonText")!

        static let toastText = UIColor(named: "toastText")!
        static let toastSuccessBg = UIColor(named: "toastSuccessBg")!
        static let toastErrorBg = UIColor(named: "toastErrorBg")!
        static let toastWarningBg = UIColor(named: "toastWarningBg")!
        static let toastInfoBg = UIColor(named: "toastInfoBg")!
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

    public enum SortDir: String {
        case asc, desc
    }

    public enum ViewInteractionMode {
        case add, edit, view
    }
}
