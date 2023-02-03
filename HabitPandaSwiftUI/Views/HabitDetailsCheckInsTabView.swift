//
//  HabitDetailsCheckInsTabView.swift
//  HabitPandaSwiftUI
//
//  Created by Tim Nance on 10/11/22.
//

import SwiftUI

struct HabitDetailsCheckInsTabView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @ObservedObject var habit: Habit
    @FetchRequest var checkIns: FetchedResults<CheckIn>

    init(habit: Habit) {
        self.habit = habit
        _checkIns = FetchRequest(
            entity: CheckIn.entity(),
            sortDescriptors: [
                NSSortDescriptor(keyPath: \CheckIn.checkInDate, ascending: false),
                NSSortDescriptor(keyPath: \CheckIn.createdAt, ascending: false),
            ],
            predicate: NSPredicate(format: "habit == %@", habit)
        )
    }

    var body: some View {
        VStack {
            if checkIns.isEmpty {
                Text("No check-ins yet").font(.title3)
                    .padding()
            } else {
                List {
                    ForEach(checkIns) { checkIn in
                        VStack(alignment: .leading) {
                            Text(getTitleText(checkIn: checkIn))
                                .font(.system(size: 17))
                            Text(getSubTitleText(checkIn: checkIn))
                                .foregroundColor(Color(Constants.Colors.subText))
                                .font(.system(size: 13))
                        }
                        .padding(.vertical, 2)
                    }
                    .onDelete(perform: delete(offsets:))
                }
                .listStyle(.plain)
                .padding(8)
            }
        }
    }

    func getTitleText(checkIn: CheckIn) -> String {
        return DateHelper.getDateString(checkIn.checkInDate!) + " — " +
            checkIn.resultType.descriptionWithResultValue(checkIn.resultValue)
    }

    func getSubTitleText(checkIn: CheckIn) -> String {
        guard let createdAt = checkIn.createdAt else { return "" }
        var subTitleText = createdAt.formatted(.dateTime.hour().minute())
        if checkIn.wasAddedForPriorDate() {
            let dayOffset = checkIn.getAddedVsCheckInDateDayOffset()
            subTitleText = "*\(subTitleText) (added \(dayOffset) day\(dayOffset == 1 ? "" : "s") later)"
        }
        return subTitleText
    }

    private func delete(offsets: IndexSet) {
        withAnimation {
            offsets.forEach { offset in
                let checkIn = checkIns[offset]
                do {
                    try PersistenceController.delete(checkIn, context: viewContext)
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
    }
}

struct HabitCheckInsTabView_Previews: PreviewProvider {
    static var previews: some View {
        HabitDetailsCheckInsTabView(habit: Habit.example)
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
