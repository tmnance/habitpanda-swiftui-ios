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

        let habit1 = Habit(context: viewContext)
        habit1.createdAt = Date()
        habit1.uuid = UUID()
        habit1.name = "Test habit 1"
        habit1.frequencyPerWeek = Int32(5)
        habit1.order = Int32(0)

        [-8, -4, -4, -1, 0].forEach { dateOffset in
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
            checkIn.habit = habit1
        }

        let reminder1 = Reminder(context: viewContext)
        reminder1.createdAt = Date()
        reminder1.uuid = UUID()
        reminder1.habit = habit1
        reminder1.hour = Int32(13)
        reminder1.minute = Int32(15)
        reminder1.frequencyDays =
            Array(" XXXXX ").enumerated().filter { $0.1 != " " }.map { $0.0 as NSNumber }

        let reminder2 = Reminder(context: viewContext)
        reminder2.createdAt = Date()
        reminder2.uuid = UUID()
        reminder2.habit = habit1
        reminder2.hour = Int32(10)
        reminder2.minute = Int32(45)
        reminder2.frequencyDays =
            Array(" XXXXX ").enumerated().filter { $0.1 != " " }.map { $0.0 as NSNumber }

        let habit2 = Habit(context: viewContext)
        habit2.createdAt = Date()
        habit2.uuid = UUID()
        habit2.name = "Test habit 2"
        habit2.frequencyPerWeek = Int32(2)
        habit2.order = Int32(1)

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
        container.loadPersistentStores { storeDescription, error in
            if let error {
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
                fatalError(error.localizedDescription)
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
