//
//  TimeWindow.swift
//  HabitPandaSwiftUI
//
//  Created by Tim Nance on 2/11/25.
//

import Foundation
import CoreData

extension TimeWindow {
    // MARK: - Computed Properties
    var applicableDayIndexes: [Int] {
        get {
            DayOfWeek.convertBitmaskToOffsets(Int(self.applicableDaysOfWeekBitmask))
        }
        set {
            self.applicableDaysOfWeekBitmask = Int32(DayOfWeek.convertOffsetsToBitmask(newValue))
        }
    }

    var displayName: String {
        name ?? ""
    }

    var displayEmoji: String {
        emoji ?? "❓"
    }

    // MARK: - Instance Methods
    func isActiveOnDay(_ dayIndex: Int) -> Bool {
        return (applicableDaysOfWeekBitmask & (1 << dayIndex)) != 0
    }

    // MARK: - Static Methods
    static func getForDayIndex(
        _ dayIndex: Int,
        context: NSManagedObjectContext
    ) -> [TimeWindow] {
        return getAll(forDayIndex: dayIndex, context: context)
    }

    static func getAll(
        forDayIndex dayIndex: Int? = nil,
        context: NSManagedObjectContext
    ) -> [TimeWindow] {
        var timeWindows: [TimeWindow] = []

        let request: NSFetchRequest<TimeWindow> = TimeWindow.fetchRequest()
        var predicates: [NSPredicate] = []

        if let dayIndex {
            predicates.append(NSPredicate(format: "(applicableDaysOfWeekBitmask & %d) != 0", (1 << dayIndex)))
        }

        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        request.sortDescriptors = [
            NSSortDescriptor(key: "order", ascending: true)
        ]

        do {
            timeWindows = try context.fetch(request)
        } catch {
            print("Error fetching data from context, \(error)")
        }

        return timeWindows
    }

    static func get(
        withUUID uuid: UUID,
        context: NSManagedObjectContext
    ) -> TimeWindow? {
        var timeWindow: TimeWindow? = nil

        let request: NSFetchRequest<TimeWindow> = TimeWindow.fetchRequest()
        request.predicate = NSPredicate(format: "uuid = %@", uuid as CVarArg)

        do {
            timeWindow = try context.fetch(request).first
        } catch {
            print("Error fetching data from context, \(error)")
        }
        return timeWindow
    }

    // MARK: - Date/DayIndex Helpers
    static func dayIndex(for date: Date, calendar: Calendar = .current) -> Int {
        // Match existing convention used elsewhere: 0 = Sun
        return (calendar.component(.weekday, from: date) + 6) % 7
    }

    func isActive(on date: Date, calendar: Calendar = .current) -> Bool {
        let idx = Self.dayIndex(for: date, calendar: calendar)
        return self.isActiveOnDay(idx)
    }

    // MARK: - Active Windows Convenience
    static func activeWindows(on date: Date, context: NSManagedObjectContext) -> [TimeWindow] {
        let idx = dayIndex(for: date)
        return getAll(forDayIndex: idx, context: context)
    }

    static func firstActiveWindow(on date: Date, context: NSManagedObjectContext) -> TimeWindow? {
        return activeWindows(on: date, context: context).sorted { $0.order < $1.order }.first
    }

    static func lastActiveWindow(on date: Date, context: NSManagedObjectContext) -> TimeWindow? {
        return activeWindows(on: date, context: context).sorted { $0.order < $1.order }.last
    }

    // MARK: - Previous / Next Helpers
    func getPreviousTimeWindow(on date: Date, allowDayWrap: Bool, context: NSManagedObjectContext, calendar: Calendar = .current) -> TimeWindow? {
        let todays = Self.activeWindows(on: date, context: context).sorted { $0.order < $1.order }
        // Prefer previous by order on the same day
        if let prev = todays.filter({ $0.order < self.order }).last {
            return prev
        }
        // If none and wrapping allowed, choose the last active window from yesterday
        guard allowDayWrap, let y = calendar.date(byAdding: .day, value: -1, to: date) else { return nil }
        return Self.lastActiveWindow(on: y, context: context)
    }

    func getNextTimeWindow(on date: Date, allowDayWrap: Bool, context: NSManagedObjectContext, calendar: Calendar = .current) -> TimeWindow? {
        let todays = Self.activeWindows(on: date, context: context).sorted { $0.order < $1.order }
        // Prefer next by order on the same day
        if let next = todays.first(where: { $0.order > self.order }) {
            return next
        }
        // If none and wrapping allowed, choose the first active window from tomorrow
        guard allowDayWrap, let t = calendar.date(byAdding: .day, value: 1, to: date) else { return nil }
        return Self.firstActiveWindow(on: t, context: context)
    }

    // Convenience overloads defaulting to today
    func getPreviousTimeWindow(allowDayWrap: Bool, context: NSManagedObjectContext) -> TimeWindow? {
        return getPreviousTimeWindow(on: Date().today(), allowDayWrap: allowDayWrap, context: context)
    }

    func getNextTimeWindow(allowDayWrap: Bool, context: NSManagedObjectContext) -> TimeWindow? {
        return getNextTimeWindow(on: Date().today(), allowDayWrap: allowDayWrap, context: context)
    }
}

// MARK: - Xcode preview content
extension TimeWindow {
    static var example: TimeWindow {
        let context = PersistenceController.preview.container.viewContext

        let fetchRequest: NSFetchRequest<TimeWindow> = TimeWindow.fetchRequest()
        fetchRequest.fetchLimit = 1

        let results = try? context.fetch(fetchRequest)

        return (results?.first!)!
    }
}
