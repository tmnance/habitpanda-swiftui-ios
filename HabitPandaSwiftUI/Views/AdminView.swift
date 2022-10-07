//
//  AdminView.swift
//  HabitPandaSwiftUI
//
//  Created by Tim Nance on 10/7/22.
//

import SwiftUI
import AlertToast

struct AdminView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @State private var showToast = false
    @State private var toastText = ""
    @State private var showSeedTestDataAlert = false
    @State private var showDeleteAllDataAlert = false

    var body: some View {
        VStack {
            Button(action: {
                showSeedTestDataAlert = true
            }) {
                Text("Seed test data")
            }.alert(
                isPresented: $showSeedTestDataAlert,
                content: {
                    Alert(
                        title: Text("Confirm Seed Data"),
                        message: Text("Warning: seeding test data will clear all existing data"),
                        primaryButton: .default(
                            Text("Cancel")
                        ),
                        secondaryButton: .destructive(
                            Text("Confirm"),
                            action: seedTestData
                        )
                    )
                }
            )

            Button(action: {
                showDeleteAllDataAlert = true
            }) {
                Text("Delete all data")
            }.alert(
                isPresented: $showDeleteAllDataAlert,
                content: {
                    Alert(
                        title: Text("Delete All Data"),
                        message: Text("Warning: this will clear all existing data"),
                        primaryButton: .default(
                            Text("Cancel")
                        ),
                        secondaryButton: .destructive(
                            Text("Confirm"),
                            action: deleteAllData
                        )
                    )
                }
            )

            Spacer()
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .toast(isPresenting: $showToast, duration: 2, tapToDismiss: true) {
            AlertToast(type: .regular, title: toastText)
        }

        .navigationTitle("Admin")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func seedTestData() {
        createSeedTestHabits()
//        ReminderNotificationService.refreshNotificationsForAllReminders()
//        self.loadNotificationData()
        toastText = "Test data seeded"
        showToast = true
    }

    private func createSeedTestHabits() {
        deleteAllHabits()

        let seedHabits:[[String:Any]] = [
            [
                "name": "Call mom",
                "frequencyPerWeek": 1,
                //                 98765432109876543210
                "checkInHistory": "    X      X      X "
            ],
            [
                "name": "Do some form of exercise",
                "frequencyPerWeek": 5,
                //                 98765432109876543210
                "checkInHistory": " XXX X  X X X X 2 XX"
            ],
            [
                "name": "Have a no-TV night",
                "frequencyPerWeek": 2,
                //                 98765432109876543210
                "checkInHistory": " X  X      X      X "
            ],
            [
                "name": "Make the bed every morning",
                "frequencyPerWeek": 7,
                //                 98765432109876543210
                "checkInHistory": "XXXXXXXXXXXXXXXXXXXX",
                "reminders": [
                    [
                        "hour": 8,
                        "minute": 30,
                        //                SMTWTFS
                        "frequencyDays": "X     X",
                    ],
                    [
                        "hour": 7,
                        "minute": 30,
                        //                SMTWTFS
                        "frequencyDays": " XXXXX ",
                    ],
                ],
            ],
            [
                "name": "Read for fun or growth 20 minutes",
                "frequencyPerWeek": 5,
                //                 98765432109876543210
                "checkInHistory": " X X X X XXXX X XX X"
            ],
            [
                "name": "Take daily vitamins",
                "frequencyPerWeek": 7,
                //                 98765432109876543210
                "checkInHistory": "XX XXXXXXXXXX XXXXXX"
            ],
        ]

        let createdAtDate = Calendar.current.date(
            byAdding: .day,
            value: -20,
            to: Date()
        )!

        seedHabits.enumerated().forEach{ (i, seedHabit) in
            let newHabit = createSeedHabit(
                withName: seedHabit["name"] as? String ?? "",
                withFrequencyPerWeek: seedHabit["frequencyPerWeek"] as? Int ?? 1,
                forDate: Calendar.current.date(
                    byAdding: .second,
                    value: i,
                    to: createdAtDate
                )!,
                withOrder: i
            )

            Array(seedHabit["checkInHistory"] as? String ?? "").reversed().enumerated()
                .forEach{ (dayOffset, checkInState) in
                    let checkInCount: Int = {
                        switch checkInState {
                        case " ":
                            return 0
                        case "X":
                            return 1
                        default:
                            return Int("\(checkInState)") ?? 0
                        }
                    }()

                    if checkInCount > 0 {
                        let checkInDate = Calendar.current.date(
                            byAdding: .day,
                            value: -1 * dayOffset,
                            to: Date()
                        )!
                        (0..<checkInCount).forEach{ _ in
                            let _ = createSeedCheckIn(forHabit: newHabit, forDate: checkInDate)
                        }
                    }
                }

            if let seedReminders = seedHabit["reminders"] as? [[String:Any]] {
                seedReminders.forEach{ (seedReminder) in
                    let _ = createSeedReminder(
                        forHabit: newHabit,
                        withHour: seedReminder["hour"] as? Int ?? 0,
                        withMinute: seedReminder["minute"] as? Int ?? 0,
                        withFrequencyDays: seedReminder["frequencyDays"] as? String ?? ""
                    )
                }
            }
        }

        do {
            try viewContext.save()
        } catch {
            print("Error saving context, \(error)")
        }
    }

    func createSeedHabit(
        withName name: String,
        withFrequencyPerWeek frequencyPerWeek: Int,
        forDate date: Date,
        withOrder order: Int
    ) -> Habit {
        let habitToSave = Habit(context: viewContext)
        habitToSave.createdAt = date
        habitToSave.uuid = UUID()
        habitToSave.name = name
        habitToSave.frequencyPerWeek = Int32(frequencyPerWeek)
        habitToSave.order = Int32(order)

        return habitToSave
    }

    func createSeedCheckIn(forHabit habit: Habit, forDate date: Date) -> CheckIn {
        let checkInToSave = CheckIn(context: viewContext)
        checkInToSave.createdAt = date
        checkInToSave.uuid = UUID()
        checkInToSave.habit = habit
        checkInToSave.checkInDate = date.stripTime()
        checkInToSave.isSuccess = true

        return checkInToSave
    }

    func createSeedReminder(
        forHabit habit: Habit,
        withHour hour: Int,
        withMinute minute: Int,
        withFrequencyDays frequencyDays: String
        ) -> Reminder {
        let reminderToSave = Reminder(context: viewContext)
        reminderToSave.createdAt = Date()
        reminderToSave.uuid = UUID()
        reminderToSave.habit = habit

        reminderToSave.hour = Int32(hour)
        reminderToSave.minute = Int32(minute)
        reminderToSave.frequencyDays =
            Array(frequencyDays).enumerated().filter{ $0.1 != " " }.map{ $0.0 as NSNumber }

        return reminderToSave
    }

    private func deleteAllData() {
        deleteAllHabits()
//        ReminderNotificationService.refreshNotificationsForAllReminders()
//        self.loadNotificationData()
        toastText = "All habit data deleted"
        showToast = true
    }

    private func deleteAllHabits() {
        Habit.getAll().forEach({ viewContext.delete($0) })

        do {
            try viewContext.save()
        } catch {
            print("Error saving context, \(error)")
        }
    }
}

struct AdminView_Previews: PreviewProvider {
    static var previews: some View {
        AdminView()
    }
}
