//
//  HabitCheckInsTabView.swift
//  HabitPandaSwiftUI
//
//  Created by Tim Nance on 10/11/22.
//

import SwiftUI

struct HabitCheckInsTabView: View {
    @ObservedObject var habit: Habit
    @FetchRequest var checkIns: FetchedResults<CheckIn>

    init(habit: Habit) {
        self.habit = habit
        _checkIns = FetchRequest(
            entity: CheckIn.entity(),
            sortDescriptors: [
                NSSortDescriptor(keyPath: \CheckIn.checkInDate, ascending: false)
            ],
            predicate: NSPredicate(format: "habit == %@", habit)
        )
    }

//    @FetchRequest(
//        sortDescriptors: [NSSortDescriptor(keyPath: \CheckIn.checkInDate, ascending: false)],
//        animation: .none)
//    private var checkIns: FetchedResults<CheckIn>

    var body: some View {
        VStack {
            if checkIns.isEmpty {
                Text("No check-ins yet").font(.title3)
                    .padding()
            } else {
                List {
                    ForEach(checkIns) { checkIn in
                        VStack(alignment: .leading) {
                            Text(checkIn.checkInDate!.formatted(
                                .dateTime.weekday(.abbreviated).day().month(.wide))
                            )
                            Text(checkIn.createdAt!.formatted(
                                .dateTime.hour().minute())
                            ).font(.footnote)
                        }
                    }
                    .onDelete(perform: delete(offsets:))
                }
                .listStyle(.plain)
                .padding(8)
            }
        }
    }

    private func delete(offsets: IndexSet) {
        withAnimation {
            offsets.forEach { offset in
                let checkIn = checkIns[offset]
                do {
                    try PersistenceController.shared.delete(checkIn)
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
    }
}

struct HabitCheckInsTabView_Previews: PreviewProvider {
    static var previews: some View {
        HabitCheckInsTabView(habit: Habit.getPreviewHabit())
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
//        HabitDetailsView(habit: Habit.getPreviewHabit(), selectedTab: .checkIns)
//            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
