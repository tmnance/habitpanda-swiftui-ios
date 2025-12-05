//
//  HabitDetailsChartWrapperView.swift
//  HabitPandaSwiftUI
//
//  Created by Tim Nance on 12/5/25.
//

import SwiftUI
import CoreData

struct HabitDetailsChartWrapperView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.calendar) private var calendar
    
    private static let dateRangeLabelFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "EEE M'/'d"
        return df
    }()

    @ObservedObject private var habit: Habit
    @State private var today: Date
    @State private var rangeStartDate: Date
    @State private var rangeEndDate: Date
    @State private var targetRangeDayCount: Int
    @State private var rollingWindowDayCount: Int

    @FetchRequest private var earliestCheckIn: FetchedResults<CheckIn>
    private var earliestCheckInDate: Date? {
        earliestCheckIn.first?.checkInDate?.stripTime()
    }

    init(habit: Habit, targetRangeDayCount: Int = 14, rollingWindowDayCount: Int = 7) {
        let today = Date().stripTime()
        self.habit = habit
        _targetRangeDayCount = State(initialValue: targetRangeDayCount)
        _rollingWindowDayCount = State(initialValue: rollingWindowDayCount)
        _rangeStartDate = State(initialValue: Calendar.current.date(byAdding: .day, value: -(targetRangeDayCount - 1), to: today)!)
        _rangeEndDate = State(initialValue: today)
        _today = State(initialValue: today)
        _earliestCheckIn = {
            let fetchRequest: NSFetchRequest<CheckIn> = CheckIn.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CheckIn.checkInDate, ascending: true)]
            fetchRequest.predicate = NSPredicate(
                format: "habit == %@ AND (typeRaw != %@ OR typeRaw == nil)",
                habit,
                CheckInType.dayOff.rawValue
            )
            fetchRequest.fetchLimit = 1
            return FetchRequest(fetchRequest: fetchRequest, animation: .none)
        }()
    }

    var body: some View {
        VStack {
            VStack(spacing: 0) {
                Group {
                    Text("7-Day Rolling Sum")
                        .font(.system(size: 20))
                    Text("(\(Self.dateRangeLabelFormatter.string(from: rangeStartDate)) - " +
                         "\(Self.dateRangeLabelFormatter.string(from: rangeEndDate)))")
                        .font(.footnote)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()

            let showPrevious = {
                guard let earliestCheckInDate = earliestCheckInDate else {
                    return false
                }
                return earliestCheckInDate < rangeStartDate
            }()
            let showNext = (rangeEndDate < today)
            if showPrevious || showNext {
                HStack {
                    Button(action: {
                        self.rangeStartDate = Calendar.current.date(byAdding: .day, value: -(targetRangeDayCount), to: rangeStartDate)!
                        self.rangeEndDate = Calendar.current.date(byAdding: .day, value: -(targetRangeDayCount), to: rangeEndDate)!
                    }) {
                        Text("Prev")
                    }
                    .disabled(!showPrevious)
//                    Button(action: {
//                        self.rangeStartDate = Calendar.current.date(byAdding: .day, value: -(targetRangeDayCount - 1), to: today)!
//                        self.rangeEndDate = today
//                    }) {
//                        Text("Today")
//                    }
//                    .disabled(rangeEndDate == today)
                    Button(action: {
                        self.rangeStartDate = Calendar.current.date(byAdding: .day, value: (targetRangeDayCount), to: rangeStartDate)!
                        self.rangeEndDate = Calendar.current.date(byAdding: .day, value: (targetRangeDayCount), to: rangeEndDate)!
                    }) {
                        Text("Next")
                    }
                    .disabled(!showNext)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            }

            HabitDetailsChartView(
                habit: habit,
                rangeStartDate: rangeStartDate,
                rangeEndDate: rangeEndDate,
                rollingWindowDayCount: rollingWindowDayCount,
                earliestCheckInDate: earliestCheckInDate
            )
                .padding(.bottom, 16)
        }
        .onNewDay {
            today = Date().stripTime()
            rangeStartDate = Calendar.current.date(byAdding: .day, value: -(targetRangeDayCount - 1), to: today)!
            rangeEndDate = today
        }
    }
}

#Preview {
    HabitDetailsChartWrapperView(habit: Habit.example)
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
