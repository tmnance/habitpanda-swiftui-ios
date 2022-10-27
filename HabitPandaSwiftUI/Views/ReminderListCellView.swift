//
//  ReminderListCellView.swift
//  HabitPandaSwiftUI
//
//  Created by Tim Nance on 10/22/22.
//

import SwiftUI

struct ReminderListCellView: View {
    @ObservedObject var reminder: Reminder
    @State private var isEditReminderViewPresented = false

    var body: some View {
        HStack(spacing: 0) {
            Text(TimeOfDay.getDisplayDate(hour: Int(reminder.hour), minute: Int(reminder.minute)))
                .frame(width: 90, alignment: .leading)

            HStack(spacing: 0) {
                ForEach(Array(Calendar.current.veryShortWeekdaySymbols.enumerated()), id: \.0) { index, element in
                    Text(element).foregroundColor(reminder.isActiveOnDay(index) ? .primary : .gray)
                }
            }

            Button("Edit") {
                isEditReminderViewPresented.toggle()
            }
            .padding(.horizontal, 20)

            Button("Remove") {
                // TODO: add confirm delete alert?
                deleteReminder()
            }
        }
        .fullScreenCover(isPresented: $isEditReminderViewPresented) {
            AddEditReminderView(habit: reminder.habit!, reminderToEdit: reminder)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func deleteReminder() {
        do {
            try PersistenceController.shared.delete(reminder)

            ReminderNotificationService.refreshNotificationsForAllReminders()
        } catch {
            print(error.localizedDescription)
        }
    }
}

struct ReminderListCellView_Previews: PreviewProvider {
    static var previews: some View {
        ReminderListCellView(reminder: Reminder.example)
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
