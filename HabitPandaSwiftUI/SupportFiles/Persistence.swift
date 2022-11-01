//
//  Persistence.swift
//  HabitPandaSwiftUI
//
//  Created by Tim Nance on 10/7/22.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)

        let viewContext = result.container.viewContext

        let habit = Habit(context: viewContext)
        habit.createdAt = Date()
        habit.uuid = UUID()
        habit.name = "Test habit"
        habit.frequencyPerWeek = Int32(5)
        habit.order = Int32(0)

        [-29, -28, -28, -1, 0].forEach { dateOffset in
            let checkIn = CheckIn(context: viewContext)
            let checkInDate = Calendar.current.date(
                byAdding: .day,
                value: dateOffset,
                to: Date()
            )!.stripTime()
            checkIn.createdAt = checkInDate
            checkIn.uuid = UUID()
            checkIn.isSuccess = true
            checkIn.checkInDate = checkInDate
            checkIn.habit = habit
        }

        let reminder1 = Reminder(context: viewContext)
        reminder1.createdAt = Date()
        reminder1.uuid = UUID()
        reminder1.habit = habit
        reminder1.hour = Int32(13)
        reminder1.minute = Int32(11)
        reminder1.frequencyDays =
            Array(" XXXXX ").enumerated().filter { $0.1 != " " }.map { $0.0 as NSNumber }

        let reminder2 = Reminder(context: viewContext)
        reminder2.createdAt = Date()
        reminder2.uuid = UUID()
        reminder2.habit = habit
        reminder2.hour = Int32(10)
        reminder2.minute = Int32(44)
        reminder2.frequencyDays =
            Array(" XXXXX ").enumerated().filter { $0.1 != " " }.map { $0.0 as NSNumber }

        do {
            try PersistenceController.save(context: viewContext)
        } catch {
            print(error.localizedDescription)
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }

        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "HabitPandaSwiftUI")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.loadPersistentStores { storeDescription, err in
            if let err = err {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                Typical reasons for an error here include:
                * The parent directory does not exist, cannot be created, or disallows writing.
                * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                * The device is out of space.
                * The store could not be migrated to the current model version.
                Check the error message to determine what the actual problem was.
                */
                fatalError(err.localizedDescription)
            }
        }
    }

    static func save(context: NSManagedObjectContext) throws {
        if context.hasChanges {
            try context.save()
        }
    }

    static func delete(_ object: NSManagedObject, context: NSManagedObjectContext) throws {
        context.delete(object)
        try PersistenceController.save(context: context)
    }
}
