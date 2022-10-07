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
}
