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

        habits.forEach { habit in
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

    static func getPreviewHabit(_ name: String? = nil) -> Habit {
        let context = PersistenceController.preview.container.viewContext
        let habit = Habit(context: context)
        habit.createdAt = Date()
        habit.uuid = UUID()
        habit.name = name ?? "Test habit"
        habit.frequencyPerWeek = Int32(5)
        habit.order = Int32(0)

        let checkIn = CheckIn(context: context)
        checkIn.createdAt = Date()
        checkIn.uuid = UUID()
        checkIn.isSuccess = true
        checkIn.checkInDate = Date().stripTime()
        checkIn.habit = habit

        let reminder1 = Reminder(context: context)
        reminder1.createdAt = Date()
        reminder1.uuid = UUID()
        reminder1.habit = habit
        reminder1.hour = Int32(13)
        reminder1.minute = Int32(11)
        reminder1.frequencyDays =
            Array(" XXXXX ").enumerated().filter { $0.1 != " " }.map { $0.0 as NSNumber }

        let reminder2 = Reminder(context: context)
        reminder2.createdAt = Date()
        reminder2.uuid = UUID()
        reminder2.habit = habit
        reminder2.hour = Int32(10)
        reminder2.minute = Int32(44)
        reminder2.frequencyDays =
            Array(" XXXXX ").enumerated().filter { $0.1 != " " }.map { $0.0 as NSNumber }

        return habit
    }
}
