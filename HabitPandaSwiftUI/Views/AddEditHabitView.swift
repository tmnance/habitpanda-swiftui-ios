//
//  AddEditHabitView.swift
//  HabitPandaSwiftUI
//
//  Created by Tim Nance on 10/7/22.
//

import SwiftUI

struct AddEditHabitView: View {
    private enum Field: Hashable {
        case name, frequencyOverflow
    }
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    @State private var name: String = ""
    @State private var frequencyPerWeek = Constants.Habit.defaultFrequencyPerWeek
    @State private var isSliderOverflowActive = false
    @State private var frequencySliderValue = Float(Constants.Habit.defaultFrequencyPerWeek)
    @State private var frequencyOverflow = ""
    @State private var selectedActiveDaysOfWeek: Set<DayOfWeek.Day> = []
    @State private var isCheckInCooldownActive = false
    @State private var checkInCooldownDays: Int = 1
    @FocusState private var focusedField: Field?
    @State private var timer: Timer?
    @State private var interactionMode: Constants.ViewInteractionMode = .add

    let frequencySliderOverflowThreshold = 8
    var habitToEdit: Habit? = nil

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Group {
                        Text("Habit Activity / Behavior").font(.title2)
                        Text("(e.g. \"Go to the gym\", \"Make the bed\")").font(.footnote)
                        TextField("", text: $name)
                            .focused($focusedField, equals: .name)
                            .onTapGesture { } // override parent view onTapGesture's keyboard dismissal
                            .submitLabel(.done)
                    }
                    .onTapGesture {
                        hideKeyboard()
                    }

                    Group {
                        Text("Habit Target Frequency 🎯").font(.title2)
                            .padding([.top], 16)
                        Text("(how often do you aim to perform this activity / behavior)").font(.footnote)
                        Text(getFrequencyPerWeekDisplayText())
                            .frame(maxWidth: .infinity, alignment: .center)
                        // TODO: refactor slider to shared component?
                        HStack(spacing: 0) {
                            Slider(
                                value: $frequencySliderValue,
                                in: 1...Float(frequencySliderOverflowThreshold),
                                step: 1
                            ) { isEditing in
                                hideKeyboard()
                                if !isEditing { // done editing
                                    isSliderOverflowActive = Int(frequencySliderValue) == frequencySliderOverflowThreshold
                                    if isSliderOverflowActive {
                                        focusedField = .frequencyOverflow
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .onChange(of: frequencySliderValue) { _ in
                                frequencyOverflow = ""
                                frequencyPerWeek = Int(frequencySliderValue)
                            }
                            if isSliderOverflowActive {
                                TextField("", text: $frequencyOverflow)
                                    .focused($focusedField, equals: .frequencyOverflow)
                                    .frame(width: 45)
                                    .keyboardType(.numberPad)
                                    .onChange(of: frequencyOverflow) { [frequencyOverflow] newValue in
                                        let oldValue = frequencyOverflow
                                        var cleanNewValue = newValue.filter { Set("0123456789").contains($0) }
                                        if cleanNewValue.count > 2 { // trim/ignore excess characters
                                            cleanNewValue = oldValue.count == 2 ? oldValue : String(cleanNewValue.prefix(2))
                                        }
                                        if cleanNewValue.count == 2 && cleanNewValue.prefix(1) == "0" { // remove leading zero
                                            cleanNewValue = String(cleanNewValue.suffix(1))
                                        }
                                        if cleanNewValue != newValue { // replace with the clean value
                                            self.frequencyOverflow = cleanNewValue
                                        }
                                        // change frequencyPerWeek state if the overflow field is relevant
                                        // (it becomes irrelevant if the slider is being changed)
                                        if Int(frequencySliderValue) == frequencySliderOverflowThreshold {
                                            let cleanNewValueInt = Int(cleanNewValue) ?? 0
                                            frequencyPerWeek = (cleanNewValueInt > 0 ?
                                                                cleanNewValueInt :
                                                                    frequencySliderOverflowThreshold
                                            )
                                        }
                                    }
                                    .onTapGesture { } // override parent view onTapGesture's keyboard dismissal
                            }
                        }
                        .frame(height: Constants.comfortableTappableDimension, alignment: .center)
                    }
                    .onTapGesture {
                        hideKeyboard()
                    }

                    Group {
                        Group {
                            Text("Active Days").font(.title2)
                            Text("(which days should this habit occur on)").font(.footnote)
                        }
                        .onTapGesture {
                            hideKeyboard()
                        }
                        DaysOfWeekPicker(
                            selectedDays: $selectedActiveDaysOfWeek,
                            pickerOptions: [
                                (.daily, "All"),
                                (.weekdays, "Weekdays"),
                                (.weekends, "Weekends"),
                                (.custom, "Custom"),
                            ]
                        )
                            .onChange(of: selectedActiveDaysOfWeek) { _ in
                                hideKeyboard()
                            }
                    }

                    Group {
                        Group {
                            Text("Check In Cooldown").font(.title2)
                            Text("(how many days off after a successful check in)").font(.footnote)
                        }
                        .onTapGesture {
                            hideKeyboard()
                        }
                        HStack(spacing: 0) {
                            HStack(spacing: 8) {
                                Text("Active")
                                Toggle("Active", isOn: $isCheckInCooldownActive)
                                    .labelsHidden()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .onTapGesture {
                                hideKeyboard()
                            }
                            HStack(spacing: 8) {
                                Text(getCheckInCooldownDaysDisplayText())
                                Stepper("Cooldown day(s)", value: $checkInCooldownDays, in: 1...6, step: 1)
                                    .labelsHidden()
                                    .onChange(of: checkInCooldownDays) { _ in
                                        hideKeyboard()
                                    }
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .opacity(isCheckInCooldownActive ? 1.0 : 0)
                        }
                    }

                    Spacer()
                        .onTapGesture {
                            hideKeyboard()
                        }
                }
//                .contentShape(Rectangle()) // used to enable gesture recognition on the entire view
//                .onTapGesture {
//                    hideKeyboard()
//                }
                .padding(.horizontal, 20)
                .textFieldStyle(.roundedBorder)
            }
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
                    .disabled(!isValidInput())
                }
            }
            .navigationTitle(interactionMode == .add ? "Create a New Habit" : "Edit Habit")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            interactionMode = habitToEdit == nil ? .add : .edit
            switch interactionMode {
            case .add:
                // auto focus on name field when adding new
                self.timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
                    focusedField = .name
                    if focusedField == .name {
                        self.timer?.invalidate()
                    }
                }
            case .edit:
                guard let habitToEdit else { return }
                name = habitToEdit.name ?? ""
                frequencyPerWeek = Int(habitToEdit.frequencyPerWeek)

                if frequencyPerWeek >= frequencySliderOverflowThreshold {
                    frequencySliderValue = Float(frequencySliderOverflowThreshold)
                    isSliderOverflowActive = true
                    frequencyOverflow = String(frequencyPerWeek)
                }
                else {
                    frequencySliderValue = Float(frequencyPerWeek)
                }
            }

            selectedActiveDaysOfWeek = Set((habitToEdit?.activeDaysOfWeek ?? [])
                .compactMap { DayOfWeek.Day(rawValue: $0.intValue) })
            if selectedActiveDaysOfWeek.count == 0 {
                selectedActiveDaysOfWeek = DayOfWeek.WeekSubsetType.daily.frequencyDays
            }
            isCheckInCooldownActive = (habitToEdit?.checkInCooldownDays ?? 0) > 0
            checkInCooldownDays = max(Int(habitToEdit?.checkInCooldownDays ?? 0), 1)
        }
    }

    func hideKeyboard() {
        focusedField = nil
    }

    func isValidInput() -> Bool {
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            (!isSliderOverflowActive || Int(frequencyOverflow) ?? 0 > 0) &&
            selectedActiveDaysOfWeek.count > 0
    }

    func getFrequencyPerWeekDisplayText() -> String {
        let frequencyOverflowInt = Int(frequencyOverflow) ?? 0
        let displayValue = frequencyOverflowInt > 0 ? frequencyOverflowInt : frequencyPerWeek
        let isPlural = displayValue != 1
        let isShowingOverflowPlaceholder = (
            frequencyOverflowInt == 0 && frequencyPerWeek == frequencySliderOverflowThreshold
        )
        return "\(displayValue)\(isShowingOverflowPlaceholder ? "+" : "") time\(isPlural ? "s" : "") / week"
    }

    func getCheckInCooldownDaysDisplayText() -> String {
        let isPlural = checkInCooldownDays != 1
        return "\(checkInCooldownDays) day\(isPlural ? "s" : "")"
    }

    func save() {
        let isNew = interactionMode == .add
        let habitToSave = isNew ? Habit(context: viewContext) : habitToEdit!

        if isNew {
            habitToSave.createdAt = Date()
            habitToSave.uuid = UUID()
            habitToSave.order = Int32(Habit.getCount(context: viewContext) - 1)
        }

        habitToSave.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        habitToSave.frequencyPerWeek = Int32(frequencyPerWeek)
        habitToSave.activeDaysOfWeek = selectedActiveDaysOfWeek
            .map { $0.rawValue }
            .sorted()
            .map { $0 as NSNumber }
        habitToSave.checkInCooldownDays = Int32(isCheckInCooldownActive ? checkInCooldownDays : 0)

        do {
            try PersistenceController.save(context: viewContext)
            ReminderNotificationService.refreshNotificationsForAllReminders()
        } catch {
            print(error.localizedDescription)
        }
    }
}

struct AddHabitView_Previews: PreviewProvider {
    static var previews: some View {
        AddEditHabitView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
