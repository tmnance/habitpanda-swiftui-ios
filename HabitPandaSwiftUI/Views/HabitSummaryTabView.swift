//
//  HabitSummaryTabView.swift
//  HabitPandaSwiftUI
//
//  Created by Tim Nance on 10/11/22.
//

import SwiftUI

struct HabitSummaryTabView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var router: Router

    @ObservedObject var habit: Habit
    var checkIns: [CheckIn] = []
    @State private var showDeleteHabitAlert = false

    var body: some View {
        ScrollView(.vertical) {
            VStack {
                Text("7-Day Rolling Average")
                    .font(.system(size: 20))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()

                HabitSummaryChartView(habit: habit)
                    .padding(EdgeInsets(top: 0, leading: 4, bottom: 16, trailing: 16))
                
                Button(action: {
                    showDeleteHabitAlert = true
                }) {
                    Text("Delete Habit")
                        .font(.system(size: 15))
                        .foregroundColor(Color(Constants.Colors.deleteButtonText))
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .frame(height: Constants.comfortableTappableDimension)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(Constants.Colors.deleteButtonBorder), lineWidth: 1)
                        )
                }
                .padding()//.horizontal, 16)
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
    }

    private func deleteHabit() {
        do {
            try PersistenceController.shared.delete(habit)

            Habit.fixHabitOrder(context: viewContext)
            ReminderNotificationService.refreshNotificationsForAllReminders()
            ReminderNotificationService.removeOrphanedDeliveredNotifications()

            router.reset()
        } catch {
            print(error.localizedDescription)
        }
    }
}

struct HabitSummaryTabView_Previews: PreviewProvider {
    static var previews: some View {
        HabitSummaryTabView(habit: Habit.example)
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(Router())
    }
}
