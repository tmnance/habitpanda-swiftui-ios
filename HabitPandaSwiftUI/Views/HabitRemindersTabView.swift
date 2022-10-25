//
//  HabitRemindersTabView.swift
//  HabitPandaSwiftUI
//
//  Created by Tim Nance on 10/11/22.
//

import SwiftUI

struct HabitRemindersTabView: View {
    @ObservedObject var habit: Habit
    @FetchRequest var reminders: FetchedResults<Reminder>
    @State private var isAddReminderViewPresented = false

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
        VStack(alignment: .leading, spacing: 16) {
            Text("(reminders will trigger app notifications on the specified days and times)").font(.footnote)

            VStack(alignment: .leading) {
                ForEach(reminders) { reminder in
                    ReminderListCellView(reminder: reminder)
                }
                .padding(.vertical, 10)
            }

            Button("Add reminder") {
                isAddReminderViewPresented.toggle()
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .fullScreenCover(isPresented: $isAddReminderViewPresented) {
            AddEditReminderView(habit: habit)
        }
    }
}

struct HabitRemindersTabView_Previews: PreviewProvider {
    static var previews: some View {
        HabitRemindersTabView(habit: Habit.getPreviewHabit())
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
