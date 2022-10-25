//
//  Reminder.swift
//  HabitPandaSwiftUI
//
//  Created by Tim Nance on 10/9/22.
//

import Foundation
import CoreData

//@objc(Reminder)
public class Reminder: NSManagedObject {
    public func getTimeOfDay() -> TimeOfDay {
        return TimeOfDay(hour: Int(hour), minute: Int(minute))
    }

    public func getTimeInMinutes() -> Int {
        return Int(hour * 60) + Int(minute)
    }

    public func isActiveOnDay(_ offset: Int) -> Bool {
        return (frequencyDays ?? []).contains(NSNumber(value: offset))
    }

    public static func getAll(withLimit limit: Int? = nil) -> [Reminder] {
        let context = PersistenceController.shared.container.viewContext
        var reminders: [Reminder] = []

        let request: NSFetchRequest<Reminder> = Reminder.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: "hour", ascending: true),
            NSSortDescriptor(key: "minute", ascending: true),
            NSSortDescriptor(key: "frequencyDays", ascending: true)
        ]
        if let limit = limit {
            request.fetchLimit = limit
        }

        do {
            reminders = try context.fetch(request)
        } catch {
            print("Error fetching data from context, \(error)")
        }

        return reminders
    }

    public static func get(withUUID uuid: UUID) -> Reminder? {
        let context = PersistenceController.shared.container.viewContext
        var reminder: Reminder? = nil

        let request: NSFetchRequest<Reminder> = Reminder.fetchRequest()
        request.predicate = NSPredicate(format: "uuid = %@", uuid as CVarArg)

        do {
            reminder = try context.fetch(request).first
        } catch {
            print("Error fetching data from context, \(error)")
        }
        return reminder
    }

    static func getPreviewReminder(_ name: String? = nil) -> Reminder {
        let context = PersistenceController.preview.container.viewContext
        let reminder = Reminder(context: context)
        reminder.createdAt = Date()
        reminder.uuid = UUID()
        reminder.habit = Habit.getPreviewHabit()

        reminder.hour = Int32(7)
        reminder.minute = Int32(30)
        reminder.frequencyDays =
            Array(" XXXXX ").enumerated().filter { $0.1 != " " }.map { $0.0 as NSNumber }

        return reminder
    }
}
