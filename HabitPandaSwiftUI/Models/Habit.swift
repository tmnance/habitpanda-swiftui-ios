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
        sortedBy sortKeys: [(String, Constants.SortDir)] = [("name", .asc)]
    ) -> [Habit] {
        let context = PersistenceController.shared.container.viewContext
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

    public static func getCount() -> Int {
        let context = PersistenceController.shared.container.viewContext
        var count = 0

        let request: NSFetchRequest<Habit> = Habit.fetchRequest()

        do {
            count = try context.count(for: request)
        } catch {
            print("Error fetching data from context, \(error)")
        }

        return count
    }

    public static func fixHabitOrder() {
        let context = PersistenceController.shared.container.viewContext
        let habits = Habit.getAll(sortedBy: [("order", .asc), ("createdAt", .asc)])
        guard habits.count > 0 else {
            return
        }

        var order = 0

        habits.forEach { (habit) in
            let habitToSave = habit
            habitToSave.order = Int32(order)
            order += 1
        }

        do {
            try context.save()
        } catch {
            print("Error saving context, \(error)")
        }
    }

    func getFirstCheckInDate() -> Date? {
        let checkIns = CheckIn.getAll(
            forHabitUUIDs: [uuid!],
            withLimit: 1
        )
        return checkIns.first?.checkInDate!.stripTime()
    }
}
