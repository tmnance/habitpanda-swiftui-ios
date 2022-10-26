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
    @FocusState private var focusedField: Field?
//    @State private var timer: Timer?
    @State private var interactionMode: Constants.ViewInteractionMode = .add

    let frequencySliderOverflowThreshold = 8
    var habitToEdit: Habit? = nil

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Habit Activity / Behavior").font(.title2)
                Text("(e.g. \"Go to the gym\", \"Make the bed\")").font(.footnote)
                TextField("", text: $name)
                    .focused($focusedField, equals: .name)
//                    .onAppear {
//                        self.timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
//                            focusedField = .name
//                            if focusedField == .name {
//                                self.timer?.invalidate()
//                            }
//                        }
//                    }
                    .onTapGesture { } // override parent view onTapGesture's keyboard dismissal
                    .submitLabel(.done)

                Text("Habit Target Frequency 🎯").font(.title2)
                    .padding([.top], 16)
                Text("(how often do you aim to perform this activity / behavior)").font(.footnote)
                Text(getFrequencyPerWeekDisplayText())
                    .frame(maxWidth: .infinity, alignment: .center)
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
                .frame(height: 46, alignment: .center)

                Spacer()
            }
            .contentShape(Rectangle()) // used to enable gesture recognition on the entire view
            .onTapGesture {
                hideKeyboard()
            }
            .padding(.horizontal, 20)
            .textFieldStyle(.roundedBorder)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        save()
                        dismiss()
                    }
                    .disabled(!isValidInput())
                }
            }
            .navigationTitle(interactionMode == .add ? "Create a New Habit" : "Edit Habit")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            interactionMode = habitToEdit == nil ? .add : .edit
            guard let habitToEdit = habitToEdit else { return }
            guard interactionMode == .edit else { return }

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
    }

    func hideKeyboard() {
        focusedField = nil
    }

    func isValidInput() -> Bool {
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            (!isSliderOverflowActive || Int(frequencyOverflow) ?? 0 > 0)
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

    func save() {
        let isNew = interactionMode == .add
        let habitToSave = isNew ? Habit(context: viewContext) : habitToEdit!

        if isNew {
            habitToSave.createdAt = Date()
            habitToSave.uuid = UUID()
            habitToSave.order = Int32(Habit.getCount() - 1)
        }

        habitToSave.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        habitToSave.frequencyPerWeek = Int32(frequencyPerWeek)

        do {
            try PersistenceController.shared.save()
            ReminderNotificationService.refreshNotificationsForAllReminders()
        } catch {
            print("Error saving context, \(error)")
        }
    }
}

struct AddHabitView_Previews: PreviewProvider {
    static var previews: some View {
        AddEditHabitView()
    }
}
