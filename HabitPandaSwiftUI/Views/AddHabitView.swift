//
//  AddHabitView.swift
//  HabitPandaSwiftUI
//
//  Created by Tim Nance on 10/7/22.
//

import SwiftUI

struct AddHabitView: View {
//    private enum Field: Hashable {
//        case name
//    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    @State private var name: String = ""
//    @State private var timer: Timer?
//    @FocusState private var focusedField: Field?


    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Habit Activity / Behavior").font(.title2)
                Text("(e.g. \"Go to the gym\", \"Make the bed\")").font(.footnote)
                TextField("", text: $name)
//                        .focused($focusedField, equals: .name)
//                        .onAppear {
//                            self.timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { (_) in
//                                focusedField = .name
//                                if focusedField == .name {
//                                    self.timer?.invalidate()
//                                }
//                            }
//                        }

                Spacer()
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
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("Create a New Habit")
            .navigationBarTitleDisplayMode(.inline)
        }
//        .navigationViewStyle(StackNavigationViewStyle())
    }

    func save() {
        let habitToSave = Habit(context: viewContext)

        habitToSave.createdAt = Date()
        habitToSave.uuid = UUID()
        habitToSave.order = Int32(Habit.getCount() - 1)

        habitToSave.name = name
        habitToSave.frequencyPerWeek = Int32(1)//frequencyPerWeek.value)

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
        AddHabitView()
    }
}
