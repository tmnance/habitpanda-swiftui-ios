//
//  HabitDetailsRemindersTabView.swift
//  HabitPandaSwiftUI
//
//  Created by Tim Nance on 10/11/22.
//

import SwiftUI

struct HabitDetailsRemindersTabView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @ObservedObject var habit: Habit
    @FetchRequest var reminders: FetchedResults<Reminder>
    @State private var isAddEditReminderViewPresented = false
    @State private var reminderToEdit: Reminder? = nil

    init(habit: Habit) {
        self.habit = habit
        _reminders = FetchRequest(
            entity: Reminder.entity(),
            sortDescriptors: [
                NSSortDescriptor(keyPath: \Reminder.hour, ascending: true),
                NSSortDescriptor(keyPath: \Reminder.minute, ascending: true)
            ],
            predicate: NSPredicate(format: "habit == %@", habit)
        )
    }

    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 16) {
                Text("(reminders will trigger app notifications on the specified days and times)").font(.footnote)

                VStack(alignment: .leading) {
                    ForEach(reminders) { reminder in
                        ReminderListCellView(
                            reminder: reminder,
                            onEdit: { reminder in
                                reminderToEdit = reminder
                                isAddEditReminderViewPresented.toggle()
                            },
                            onRemove: { reminder in
                                // TODO: add confirm delete alert?
                                deleteReminder(reminder)
                            }
                        )
                    }
                    .padding(.vertical, 10)
                }

                Button("Add reminder") {
                    reminderToEdit = nil
                    isAddEditReminderViewPresented.toggle()
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .fullScreenCover(isPresented: $isAddEditReminderViewPresented) {
                AddEditReminderView(habit: habit, reminderToEdit: self.$reminderToEdit)
            }
        }
        .onAppear {
            reminderToEdit = nil
        }
    }

    private func deleteReminder(_ reminder: Reminder) {
        do {
            try PersistenceController.delete(reminder, context: viewContext)
            ReminderNotificationService.refreshNotificationsForAllReminders()
        } catch {
            print(error.localizedDescription)
        }
    }
}

struct HabitRemindersTabView_Previews: PreviewProvider {
    static var previews: some View {
        HabitDetailsRemindersTabView(habit: Habit.example)
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
