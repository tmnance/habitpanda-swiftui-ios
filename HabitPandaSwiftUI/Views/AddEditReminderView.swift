//
//  AddEditReminderView.swift
//  HabitPandaSwiftUI
//
//  Created by Tim Nance on 10/23/22.
//

import SwiftUI

struct AddEditReminderView: View {
    private typealias FrequencyOption = DayOfWeek.WeekSubsetType
    private typealias FrequencyDay = DayOfWeek.Day
    private struct FrequencyOptionToggleState: Equatable {
      let day: FrequencyDay
      var isActive: Bool
    }
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    @State private var time: Date = Date().rounded(
        minutes: TimeInterval(Constants.TimePicker.minuteInterval),
        rounding: .floor
    )
    @State private var selectedFrequencyOption: FrequencyOption = .custom
    @State private var frequencyDaysToggleStates: [FrequencyOptionToggleState] = {
        return FrequencyDay.allCases.map { FrequencyOptionToggleState(day: $0, isActive: false) }
    }()
    @State private var interactionMode: Constants.ViewInteractionMode = .add

    let habit: Habit
    var reminderToEdit: Reminder? = nil
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

                Picker("", selection: $selectedFrequencyOption) {
                    Text("Daily").tag(FrequencyOption.daily)
                    Text("Weekdays").tag(FrequencyOption.weekdays)
                    Text("Custom").tag(FrequencyOption.custom)
                }
                .pickerStyle(.segmented)
                .onChange(of: selectedFrequencyOption) { _ in
                    // Only change the day toggle values if they don't currently match the new picker option
                    // (in effect was the change triggered by the user changing the frequency picker value or
                    // programatically by changing active days)
                    if selectedFrequencyOption != getCurrentFrequencyOptionFromActiveDays() {
                        updateFrequencyDays(forOption: selectedFrequencyOption)
                    }
                }

                LazyVGrid(columns: layoutGrid, spacing: 5) {
                    ForEach($frequencyDaysToggleStates, id: \.day.rawValue) { $frequencyOption in
                        Toggle(isOn: $frequencyOption.isActive) {
                            Text(frequencyOption.day.description)
                                .padding(6)
                                .frame(maxWidth: .infinity)
                        }
                        .toggleStyle(.button)
                    }
                    .onChange(of: frequencyDaysToggleStates) { _ in
                        selectedFrequencyOption = getCurrentFrequencyOptionFromActiveDays()
                    }
                }

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
                    .disabled(frequencyDaysToggleStates.filter { $0.isActive }.count == 0)
                }
            }
            .navigationTitle(interactionMode == .add ? "Add a New Reminder" : "Edit Reminder")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            interactionMode = reminderToEdit == nil ? .add : .edit
            guard let reminderToEdit = reminderToEdit else { return }
            guard interactionMode == .edit else { return }

            time = Calendar.current.date(
                bySettingHour: Int(reminderToEdit.hour),
                minute: Int(reminderToEdit.minute),
                second: 0,
                of: Date()
            )!

            let frequencyDays = (reminderToEdit.frequencyDays ?? [])
                .compactMap { FrequencyDay(rawValue: $0.intValue) }
            for (index, toggleState) in frequencyDaysToggleStates.enumerated() {
                frequencyDaysToggleStates[index].isActive = frequencyDays.contains(toggleState.day)
            }
            selectedFrequencyOption = getCurrentFrequencyOptionFromActiveDays()
        }
    }

    private func updateFrequencyDays(forOption option: FrequencyOption) {
        for (index, toggleState) in frequencyDaysToggleStates.enumerated() {
            self.frequencyDaysToggleStates[index].isActive = option.frequencyDays.contains(toggleState.day)
        }
    }

    private func getCurrentFrequencyOptionFromActiveDays() -> FrequencyOption {
        let currentActiveDaySet = Set(frequencyDaysToggleStates.filter { $0.isActive }.map { $0.day })
        if currentActiveDaySet == FrequencyOption.daily.frequencyDays {
            return .daily
        }
        if currentActiveDaySet == FrequencyOption.weekdays.frequencyDays {
            return .weekdays
        }
        return .custom
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

        reminderToSave.frequencyDays = frequencyDaysToggleStates.filter { $0.isActive }
            .map { $0.day.rawValue }
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
        AddEditReminderView(habit: Habit.example)
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
