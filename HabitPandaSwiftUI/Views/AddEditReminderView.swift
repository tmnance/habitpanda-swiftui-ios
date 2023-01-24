//
//  AddEditReminderView.swift
//  HabitPandaSwiftUI
//
//  Created by Tim Nance on 10/23/22.
//

import SwiftUI

struct AddEditReminderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    @State private var time: Date = Date().rounded(
        minutes: TimeInterval(Constants.TimePicker.minuteInterval),
        rounding: .floor
    )
    @State private var selectedFrequencyDays: Set<DayOfWeek.Day> = []
    @State private var interactionMode: Constants.ViewInteractionMode = .add

    let habit: Habit
    @Binding var reminderToEdit: Reminder?
    private let layoutGrid = [
        GridItem(.adaptive(minimum: 80)),
    ]

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Reminder Time").font(.title2)
                DatePicker(
                    "",
                    selection: $time,
                    displayedComponents: [.hourAndMinute]
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .onAppear {
                    // TODO: refactor into something that doesn't clobber all datepickers
                    // (e.g. https://d1v1b.com/en/swiftui/datepicker)
                    UIDatePicker.appearance().minuteInterval = Constants.TimePicker.minuteInterval
                }
                .frame(maxWidth: .infinity, alignment: .center)

                Text("Reminder Days").font(.title2)
                Text("(which days should this reminder be sent)").font(.footnote)
                DaysOfWeekPicker(selectedDays: $selectedFrequencyDays)

                Spacer()
            }
            .padding(.horizontal, 20)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .frame(minWidth: Constants.minTappableDimension)
                    .frame(height: Constants.minTappableDimension)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        save()
                        dismiss()
                    }
                    .frame(minWidth: Constants.minTappableDimension)
                    .frame(height: Constants.minTappableDimension)
                    .disabled(selectedFrequencyDays.count == 0)
                }
            }
            .navigationTitle(interactionMode == .add ? "Add a New Reminder" : "Edit Reminder")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            interactionMode = reminderToEdit == nil ? .add : .edit
            guard let reminderToEdit else { return }
            guard interactionMode == .edit else { return }

            time = Calendar.current.date(
                bySettingHour: Int(reminderToEdit.hour),
                minute: Int(reminderToEdit.minute),
                second: 0,
                of: Date()
            )!

            selectedFrequencyDays = Set((reminderToEdit.frequencyDays ?? [])
                .compactMap { DayOfWeek.Day(rawValue: $0.intValue) })
        }
    }

    private func save() {
        // TODO: add duplicate checking?
        let isNew = interactionMode == .add
        let reminderToSave = isNew ? Reminder(context: viewContext) : reminderToEdit!

        if isNew {
            reminderToSave.createdAt = Date()
            reminderToSave.uuid = UUID()
            reminderToSave.habit = habit
        }

        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        reminderToSave.hour = Int32(components.hour ?? 0)
        reminderToSave.minute = Int32(components.minute ?? 0)

        reminderToSave.frequencyDays = selectedFrequencyDays
            .map { $0.rawValue }
            .sorted()
            .map { $0 as NSNumber }

        do {
            try PersistenceController.save(context: viewContext)
            ReminderNotificationService.refreshNotificationsForAllReminders()
        } catch {
            print(error.localizedDescription)
        }
    }
}

struct AddReminderView_Previews: PreviewProvider {
    static var previews: some View {
        AddEditReminderView(habit: Habit.example, reminderToEdit: .constant(nil))
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
