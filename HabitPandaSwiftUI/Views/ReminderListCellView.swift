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

    let onEdit: (Reminder) -> Void
    let onRemove: (Reminder) -> Void

    var body: some View {
        HStack(spacing: 0) {
            Text(TimeOfDay.getDisplayDate(hour: Int(reminder.hour), minute: Int(reminder.minute)))
                .frame(width: 90, alignment: .leading)

            HStack(spacing: 0) {
                ForEach(Array(Calendar.current.veryShortWeekdaySymbols.enumerated()), id: \.0) { index, element in
                    Text(element)
                        .opacity(reminder.isActiveOnDay(index) ? 1.0 : 0.45)
                }
            }

            Button("Edit") {
                onEdit(reminder)
            }
            .padding(.horizontal, 20)

            Button("Remove") {
                onRemove(reminder)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ReminderListCellView_Previews: PreviewProvider {
    static var previews: some View {
        ReminderListCellView(
            reminder: Reminder.example,
            onEdit: { _ in },
            onRemove: { _ in }
        )
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
