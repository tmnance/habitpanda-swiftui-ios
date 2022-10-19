//
//  HabitSummaryTabView.swift
//  HabitPandaSwiftUI
//
//  Created by Tim Nance on 10/11/22.
//

import SwiftUI

struct HabitSummaryTabView: View {
    @EnvironmentObject var router: Router
    @ObservedObject var habit: Habit
    @FetchRequest var checkIns: FetchedResults<CheckIn>
    @State private var showDeleteHabitAlert = false

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
            Text("Summary tab!")
            Text(habit.name ?? "")
            Color(red: .random(in: 0...1), green: .random(in: 0...1), blue: .random(in: 0...1))
                .frame(width: 50, height: 50)

            Button(action: {
                showDeleteHabitAlert = true
            }) {
                Text("Delete Habit")
                    .foregroundColor(.red)
                    .padding(6)
                    .frame(maxWidth: .infinity)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.red, lineWidth: 1)
                    )
            }
            .padding(.horizontal, 16)
            .alert(
                isPresented: $showDeleteHabitAlert,
                content: {
                    Alert(
                        title: Text("Confirm Delete"),
                        message: Text("Are you sure you want to delete your habit named \"\(habit.name!)\"?"),
                        primaryButton: .default(
                            Text("Cancel")
                        ),
                        secondaryButton: .destructive(
                            Text("Confirm"),
                            action: deleteHabit
                        )
                    )
                }
            )
        }
    }

    private func deleteHabit() {
        do {
            try PersistenceController.shared.delete(habit)

//            Habit.fixHabitOrder()
//            ReminderNotificationService.refreshNotificationsForAllReminders()
//            ReminderNotificationService.removeOrphanedDeliveredNotifications()

            router.reset()
        } catch {
            print(error.localizedDescription)
        }
    }
}

struct HabitSummaryTabView_Previews: PreviewProvider {
    static var previews: some View {
        HabitSummaryTabView(habit: Habit.getPreviewHabit())
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(Router())
    }
}
