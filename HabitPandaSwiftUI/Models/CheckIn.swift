//
//  CheckIn.swift
//  HabitPandaSwiftUI
//
//  Created by Tim Nance on 10/9/22.
//

import Foundation
import CoreData

public enum CheckInType: String, Hashable {
    case success,        // only show positive indicators
         failure,        // used when caring about logging both positive and negative indicators,
                         //   e.g. something maintaining a streak on or something you're trying not to do
         letterGrade,    // something you want to score A-F
         sentimentEmoji, // something you want to score with a sentiment emoji
         dayOff          // treat as a day off, e.g. on vacation or sick
    static let defaultValue: CheckInType = .success
    func descriptionWithCheckInValue(_ checkInValue: String? = nil) -> String {
        switch self {
        case .success: return "Success ✅"
        case .failure: return "Missed ❌"
        case .dayOff: return "Day off 💤 (override)"
        case .letterGrade: return "Grade: \(checkInValue ?? "unknown")"
        case .sentimentEmoji: return "Sentiment: \(checkInValue ?? "unknown")"
        }
    }
    var label: String {
        switch self {
        case .success: return "Success (✔️)"
        case .failure: return "Failure (❌)"
        case .dayOff: return "Day off"
        case .letterGrade: return "Letter Grade (A to F)"
        case .sentimentEmoji: return "Sentiment (😄 to 😢)"
        }
    }
    var options: [String] {
        switch self {
        case .success: return ["✅"]
        case .failure: return ["❌"]
        case .dayOff: return []
        case .letterGrade: return ["A", "B", "C", "D", "F"]
        case .sentimentEmoji: return ["😄", "🙂", "😐", "😟", "😢"]
        }
    }
    static func getFromRawValue(_ rawValue: String? = nil) -> CheckInType {
        return CheckInType(
            rawValue: rawValue ?? CheckInType.defaultValue.rawValue
        ) ?? CheckInType.defaultValue
    }
}

extension CheckIn {
    var type: CheckInType {
        guard let typeRaw else {
            return CheckInType.defaultValue
        }
        return CheckInType(rawValue: typeRaw) ?? CheckInType.defaultValue
    }
    var value: String? {
        return valueRaw == "" ? nil : valueRaw
    }

    public static func getAll(
        sortedBy sortKeys: [(String, Constants.SortDir)] = [("checkInDate", .asc)],
        forHabitUUIDs habitUUIDs: [UUID]? = nil,
        fromStartDate startDate: Date? = nil,
        toEndDate endDate: Date? = nil,
        ofType types: [CheckInType]? = nil,
        withLimit limit: Int? = nil,
        context: NSManagedObjectContext
    ) -> [CheckIn] {
        var checkIns: [CheckIn] = []

        let request: NSFetchRequest<CheckIn> = CheckIn.fetchRequest()
        var predicates: [NSPredicate] = []

        if let habitUUIDs {
            let uuidArgs = habitUUIDs.map { $0.uuidString as CVarArg }
            if uuidArgs.count > 0 {
                predicates.append(NSPredicate(format: "habit.uuid IN %@", argumentArray: [uuidArgs]))
            }
        }

        if let types {
            let uuidArgs = types.map { $0.rawValue as CVarArg }
            if uuidArgs.count > 0 {
                predicates.append(NSPredicate(format: "typeRaw IN %@", argumentArray: [uuidArgs]))
            }
        }

        if let startDate {
            predicates.append(NSPredicate(format: "checkInDate >= %@", startDate as NSDate))
        }
        if let endDate {
            predicates.append(NSPredicate(format: "checkInDate <= %@", endDate as NSDate))
        }

        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        request.sortDescriptors = sortKeys.map {
            NSSortDescriptor(key: $0.0, ascending: $0.1 == Constants.SortDir.asc)
        }

        if let limit {
            request.fetchLimit = limit
        }

        do {
            checkIns = try context.fetch(request)
        } catch {
            print("Error fetching data from context, \(error)")
        }

        return checkIns
    }

    public static func getHabitFirstCheckInMap(
        forHabitUUIDs habitUUIDs: [UUID]? = nil,
        fromStartDate startDate: Date? = nil,
        toEndDate endDate: Date? = nil,
        context: NSManagedObjectContext
    ) -> [UUID: Date] {
        return self.getHabitFirstOrLastCheckInMap(
            forHabitUUIDs: habitUUIDs,
            fromStartDate: startDate,
            toEndDate: endDate,
            firstOrLast: .first,
            context: context
        )
    }

    public static func getHabitLastCheckInMap(
        forHabitUUIDs habitUUIDs: [UUID]? = nil,
        fromStartDate startDate: Date? = nil,
        toEndDate endDate: Date? = nil,
        context: NSManagedObjectContext
    ) -> [UUID: Date] {
        return self.getHabitFirstOrLastCheckInMap(
            forHabitUUIDs: habitUUIDs,
            fromStartDate: startDate,
            toEndDate: endDate,
            firstOrLast: .last,
            context: context
        )
    }

    private static func getHabitFirstOrLastCheckInMap(
        forHabitUUIDs habitUUIDs: [UUID]? = nil,
        fromStartDate startDate: Date? = nil,
        toEndDate endDate: Date? = nil,
        firstOrLast: Constants.FirstOrLast = .first,
        context: NSManagedObjectContext
    ) -> [UUID: Date] {
        let request: NSFetchRequest<CheckIn> = CheckIn.fetchRequest()
        var predicates: [NSPredicate] = []

        if let habitUUIDs {
            let uuidArgs = habitUUIDs.map { $0.uuidString as CVarArg }
            if uuidArgs.count > 0 {
                predicates.append(NSPredicate(format: "habit.uuid IN %@", argumentArray: [uuidArgs]))
            }
        }

        if let startDate {
            predicates.append(NSPredicate(format: "checkInDate >= %@", startDate as NSDate))
        }
        if let endDate {
            predicates.append(NSPredicate(format: "checkInDate <= %@", endDate as NSDate))
        }

        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)

        let minOrMaxExpression = firstOrLast == .first ?
            NSExpression(format: "min:(checkInDate)") :
            NSExpression(format: "max:(checkInDate)")
        let minOrMaxED = NSExpressionDescription()
        minOrMaxED.expression = minOrMaxExpression
        minOrMaxED.name = "minOrMaxCheckInDate"
        minOrMaxED.expressionResultType = .dateAttributeType
        request.propertiesToFetch = ["habit.uuid", minOrMaxED]
        request.propertiesToGroupBy = ["habit.uuid"]
        request.resultType = .dictionaryResultType
        request.returnsObjectsAsFaults = false

        do {
            return Dictionary(
                uniqueKeysWithValues: (try context.fetch(request) as! [NSDictionary])
                    .filter { $0["habit.uuid"] as? UUID != nil && $0["minOrMaxCheckInDate"] as? Date != nil }
                    .map { ($0["habit.uuid"] as! UUID, $0["minOrMaxCheckInDate"] as! Date) }
            )
        } catch {
            print("Error fetching data from context, \(error)")
        }
        return [:]
    }

    func wasAddedForPriorDate() -> Bool {
        return getAddedVsCheckInDateDayOffset() > 0
    }

    func getAddedVsCheckInDateDayOffset() -> Int {
        return Calendar.current.dateComponents(
            [.day],
            from: checkInDate!,
            to: createdAt!
        ).day ?? 0
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
