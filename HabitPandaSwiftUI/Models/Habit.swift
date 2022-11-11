//
//  Habit.swift
//  HabitPandaSwiftUI
//
//  Created by Tim Nance on 10/7/22.
//

import Foundation
import CoreData

//@objc(Habit)
public class Habit: NSManagedObject {
    public static func getAll(
        sortedBy sortKeys: [(String, Constants.SortDir)] = [("name", .asc)],
        context: NSManagedObjectContext
    ) -> [Habit] {
        var habits: [Habit] = []

        let request: NSFetchRequest<Habit> = Habit.fetchRequest()
        request.sortDescriptors = sortKeys.map {
            NSSortDescriptor(key: $0.0, ascending: $0.1 == Constants.SortDir.asc)
        }

        do {
            habits = try context.fetch(request)
        } catch {
            print("Error fetching data from context, \(error)")
        }

        return habits
    }

    public static func getCount(context: NSManagedObjectContext) -> Int {
        let request: NSFetchRequest<Habit> = Habit.fetchRequest()
        var count = 0

        do {
            count = try context.count(for: request)
        } catch {
            print("Error fetching data from context, \(error)")
        }

        return count
    }

    public static func fixHabitOrder(context: NSManagedObjectContext) {
        let habits = Habit.getAll(
            sortedBy: [("order", .asc), ("createdAt", .asc)],
            context: context
        )
        guard habits.count > 0 else { return }

        var order = 0

        habits.forEach { habit in
            let habitToSave = habit
            habitToSave.order = Int32(order)
            order += 1
        }

        do {
            try PersistenceController.save(context: context)
        } catch {
            print(error.localizedDescription)
        }
    }

    func getFirstCheckInDate() -> Date? {
        guard let context = managedObjectContext else { return nil }
        let checkIns = CheckIn.getAll(
            forHabitUUIDs: [uuid!],
            withLimit: 1,
            context: context
        )
        return checkIns.first?.checkInDate!.stripTime()
    }

    func addCheckIn(
        forDate date: Date,
        context: NSManagedObjectContext,
        completionHandler: ((Error?) -> Void)? = nil
    ) {
        let checkInToSave = CheckIn(context: context)

        checkInToSave.createdAt = Date()
        checkInToSave.uuid = UUID()
        checkInToSave.habit = self
        checkInToSave.checkInDate = date.stripTime()
        checkInToSave.isSuccess = true

        do {
            try PersistenceController.save(context: context)
            ReminderNotificationService.refreshNotificationsForAllReminders()
            completionHandler?(nil)
        } catch {
            completionHandler?(error)
        }
    }
}


// MARK: - Xcode preview content
extension Habit {
    static var example: Habit {
        let context = PersistenceController.preview.container.viewContext

        let request: NSFetchRequest<Habit> = Habit.fetchRequest()
        request.sortDescriptors = [("order", Constants.SortDir.asc)].map {
            NSSortDescriptor(key: $0.0, ascending: $0.1 == Constants.SortDir.asc)
        }
        request.fetchLimit = 1

        let results = try? context.fetch(request)

        return (results?.first!)!
    }
}
