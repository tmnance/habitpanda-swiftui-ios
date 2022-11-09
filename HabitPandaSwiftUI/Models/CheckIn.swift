//
//  CheckIn.swift
//  HabitPandaSwiftUI
//
//  Created by Tim Nance on 10/9/22.
//

import Foundation
import CoreData

//@objc(CheckIn)
public class CheckIn: NSManagedObject {
    public static func getAll(
        sortedBy sortKeys: [(String, Constants.SortDir)] = [("checkInDate", .asc)],
        forHabitUUIDs habitUUIDs: [UUID]? = nil,
        fromStartDate startDate: Date? = nil,
        toEndDate endDate: Date? = nil,
        withLimit limit: Int? = nil,
        context: NSManagedObjectContext
    ) -> [CheckIn] {
        var checkIns: [CheckIn] = []

        let request: NSFetchRequest<CheckIn> = CheckIn.fetchRequest()
        var predicates: [NSPredicate] = []

        if let habitUUIDs = habitUUIDs {
            let uuidArgs = habitUUIDs.map { $0.uuidString as CVarArg }
            if uuidArgs.count > 0 {
                predicates.append(NSPredicate(format: "habit.uuid IN %@", argumentArray: [uuidArgs]))
            }
        }

        if let startDate = startDate {
            predicates.append(NSPredicate(format: "checkInDate >= %@", startDate as NSDate))
        }
        if let endDate = endDate {
            predicates.append(NSPredicate(format: "checkInDate <= %@", endDate as NSDate))
        }

        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        request.sortDescriptors = sortKeys.map {
            NSSortDescriptor(key: $0.0, ascending: $0.1 == Constants.SortDir.asc)
        }

        if let limit = limit {
            request.fetchLimit = limit
        }

        do {
            checkIns = try context.fetch(request)
        } catch {
            print("Error fetching data from context, \(error)")
        }

        return checkIns
    }
}


// MARK: - Xcode preview content
extension CheckIn {
    static var example: CheckIn {
        let context = PersistenceController.preview.container.viewContext

        let fetchRequest: NSFetchRequest<CheckIn> = CheckIn.fetchRequest()
        fetchRequest.fetchLimit = 1

        let results = try? context.fetch(fetchRequest)

        return (results?.first!)!
    }
}
