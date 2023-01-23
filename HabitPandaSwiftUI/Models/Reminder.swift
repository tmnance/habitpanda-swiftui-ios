//
//  Reminder.swift
//  HabitPandaSwiftUI
//
//  Created by Tim Nance on 10/9/22.
//

import Foundation
import CoreData

extension Reminder {
    public static func getAll(
        withLimit limit: Int? = nil,
        context: NSManagedObjectContext
    ) -> [Reminder] {
        var reminders: [Reminder] = []

        let request: NSFetchRequest<Reminder> = Reminder.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: "hour", ascending: true),
            NSSortDescriptor(key: "minute", ascending: true),
            NSSortDescriptor(key: "frequencyDays", ascending: true)
        ]
        if let limit {
            request.fetchLimit = limit
        }

        do {
            reminders = try context.fetch(request)
        } catch {
            print("Error fetching data from context, \(error)")
        }

        return reminders
    }

    public static func get(
        withUUID uuid: UUID,
        context: NSManagedObjectContext
    ) -> Reminder? {
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

    public func getTimeOfDay() -> TimeOfDay {
        return TimeOfDay(hour: Int(hour), minute: Int(minute))
    }

    public func getTimeInMinutes() -> Int {
        return Int(hour * 60) + Int(minute)
    }

    public func isActiveOnDay(_ offset: Int) -> Bool {
        return (frequencyDays ?? []).contains(NSNumber(value: offset))
    }
}


// MARK: - Xcode preview content
extension Reminder {
    static var example: Reminder {
        let context = PersistenceController.preview.container.viewContext

        let fetchRequest: NSFetchRequest<Reminder> = Reminder.fetchRequest()
        fetchRequest.fetchLimit = 1

        let results = try? context.fetch(fetchRequest)

        return (results?.first!)!
    }
}
