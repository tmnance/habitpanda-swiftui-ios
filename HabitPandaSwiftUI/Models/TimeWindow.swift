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
