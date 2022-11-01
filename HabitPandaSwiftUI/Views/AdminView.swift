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
    @State private var showSeedTestDataLargeAlert = false
    @State private var showDeleteAllDataAlert = false

    @State private var pendingRequests: [UNNotificationRequest] = []
    @State private var deliveredNotifications: [UNNotification] = []
    @State private var reminders: [Reminder] = []

    var body: some View {
        ScrollView {
            VStack {
                Text("\(getAppVersionString())\n\n" +
                     "\(getRemindersReportString())\n\n" +
                     "\(getNotificationsReportString())"
                ).font(.footnote)

                Button("Remove all pending notifications") {
                    NotificationHelper.removeAllPendingNotifications()
                    self.loadNotificationData()
                    toastText = "Pending notifications removed"
                    showToast = true
                }

                Button("Remove all sent notifications") {
                    NotificationHelper.removeAllDeliveredNotifications()
                    self.loadNotificationData()
                    toastText = "Sent notifications removed"
                    showToast = true
                }

                Button("Remove orphaned sent notifications") {
                    ReminderNotificationService.removeOrphanedDeliveredNotifications()
                    self.loadNotificationData()
                    toastText = "Orphaned sent notifications removed"
                    showToast = true
                }

                Button("(Re)set all notifications") {
                    ReminderNotificationService.refreshNotificationsForAllReminders()
                    self.loadNotificationData()
                    toastText = "All notifications refreshed"
                    showToast = true
                }

                Button("Send test notification") {
                    ReminderNotificationService.sendTestNotification()
                    toastText = "Test notification sent"
                    showToast = true
                }

                Button("Seed test data (normal)") {
                    showSeedTestDataAlert = true
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

                Button("Seed test data (large dataset)") {
                    showSeedTestDataLargeAlert = true
                }.alert(
                    isPresented: $showSeedTestDataLargeAlert,
                    content: {
                        Alert(
                            title: Text("Confirm Seed Data (large dataset)"),
                            message: Text("Warning: seeding test data will clear all existing data"),
                            primaryButton: .default(
                                Text("Cancel")
                            ),
                            secondaryButton: .destructive(
                                Text("Confirm"),
                                action: seedTestDataLarge
                            )
                        )
                    }
                )

                Button("Delete all data") {
                    showDeleteAllDataAlert = true
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
        }
        .toast(isPresenting: $showToast, duration: 2, tapToDismiss: true) {
            AlertToast(type: .regular, title: toastText)
        }
        .onAppear {
            loadNotificationData()
            loadRemindersData()
        }
        .navigationTitle("Admin")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func seedTestData() {
        createSeedTestHabits()
        ReminderNotificationService.refreshNotificationsForAllReminders()
        self.loadNotificationData()
        toastText = "Test data seeded"
        showToast = true
    }
    private func seedTestDataLarge() {
        createSeedTestHabits(useLargeDataSet: true)
        ReminderNotificationService.refreshNotificationsForAllReminders()
        self.loadNotificationData()
        toastText = "Test data seeded"
        showToast = true
    }

    private func createSeedTestHabits(useLargeDataSet: Bool = false) {
        deleteAllHabits()

        var seedHabits: [[String:Any]] = [
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

        if useLargeDataSet {
            for i in 0..<14 {
                let frequencyPerWeek = i + 1
                let checkInHistory = Array(repeating: "", count: 30)
                    .map { _ in ["X", " "][Int.random(in: 0...frequencyPerWeek) == 0 ? 0 : 1] }
                    .joined(separator: "")
                seedHabits.append([
                    "name": "Test Habit \(i + 1)",
                    "frequencyPerWeek": frequencyPerWeek,
                    "checkInHistory": checkInHistory
                ])
            }
        }

        let createdAtDate = Calendar.current.date(
            byAdding: .day,
            value: -20,
            to: Date()
        )!

        seedHabits.enumerated().forEach { i, seedHabit in
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
                .forEach { dayOffset, checkInState in
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
                        (0..<checkInCount).forEach { _ in
                            let _ = createSeedCheckIn(forHabit: newHabit, forDate: checkInDate)
                        }
                    }
                }

            if let seedReminders = seedHabit["reminders"] as? [[String:Any]] {
                seedReminders.forEach { seedReminder in
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
            try PersistenceController.save(context: viewContext)
        } catch {
            print(error.localizedDescription)
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
            Array(frequencyDays).enumerated().filter { $0.1 != " " }.map { $0.0 as NSNumber }

        return reminderToSave
    }

    private func deleteAllData() {
        deleteAllHabits()
        ReminderNotificationService.refreshNotificationsForAllReminders()
        self.loadNotificationData()
        toastText = "All habit data deleted"
        showToast = true
    }

    private func deleteAllHabits() {
        Habit.getAll(context: viewContext).forEach { viewContext.delete($0) }
        do {
            try PersistenceController.save(context: viewContext)
        } catch {
            print(error.localizedDescription)
        }
    }
}

struct AdminView_Previews: PreviewProvider {
    static var previews: some View {
        AdminView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}


// MARK: - UI Update Methods
extension AdminView {
    func loadNotificationData() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            // send to main thread
            DispatchQueue.main.async {
                self.pendingRequests = requests
            }
        }

        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            // send to main thread
            DispatchQueue.main.async {
                self.deliveredNotifications = notifications
            }
        }
    }

    func getNotificationsReportString() -> String {
        return "Notifications:\n" +
            "- \(pendingRequests.count) pending notification(s) set\n" +
            "- \(deliveredNotifications.count) delivered notification(s)"
    }
}


extension AdminView {
    private func loadRemindersData() {
        reminders = Reminder.getAll(context: viewContext)
    }

    func getRemindersReportString() -> String {
        var notificationCount = 0
        var habitUUIDs = Set<UUID>()

        let remindersByDay = ReminderNotificationService.RemindersForWeek(forReminders: reminders)

        let currentWeekdayIndex = ReminderNotificationService.getCurrentWeekdayIndex()
        let weekdayIndexLoop = ReminderNotificationService.getNext7DayWeekdayIndexLoop()
        let currentTimeInMinutes = TimeOfDay.generateFromCurrentTime().getTimeInMinutes()

        for (i, weekdayIndex) in weekdayIndexLoop.enumerated() {
            let remindersForDay = remindersByDay.getForWeekdayIndex(weekdayIndex)
            let sortedTimes = remindersForDay.getSortedTimes()

            for time in sortedTimes {
                if i == 0 && weekdayIndex == currentWeekdayIndex && time <= currentTimeInMinutes {
                    continue
                }
                let remindersForDayAndTime = remindersForDay.getForTime(time)
                for reminder in remindersForDayAndTime {
                    notificationCount += 1
                    habitUUIDs.insert(reminder.habit!.uuid!)
                }
            }
        }

        return "Reminders:\n" +
            "- currentWeekdayIndex = \(currentWeekdayIndex)\n" +
            "- weekdayIndexLoop = \(weekdayIndexLoop)\n" +
            "- currentTimeInMinutes = \(currentTimeInMinutes)\n" +
            "- \(notificationCount) notification\(notificationCount == 1 ? "" : "s") " +
            "will be needed across \(habitUUIDs.count) habit\(habitUUIDs.count == 1 ? "" : "s")"
    }
}


extension AdminView {
    func getAppVersionString() -> String {
        let dictionary = Bundle.main.infoDictionary!
        let version = dictionary["CFBundleShortVersionString"] as! String
        let build = dictionary["CFBundleVersion"] as! String
        let appName = dictionary["CFBundleName"] as! String

        return "App version: \(appName) v\(version) (Build \(build))\n" +
            "- buildDate = \(getDateAsString(buildDate))"
    }

    func getDateAsString(_ date: Date) -> String {
        let df = DateFormatter()

        df.dateFormat = "EEE, MMMM d"
        let displayDate = df.string(from: date)

        df.dateFormat = "h:mm a"
        let displayTime = df.string(from: date)

        return "\(displayDate) at \(displayTime)"
    }

    var buildDate:Date
    {
        if let infoPath = Bundle.main.path(forResource: "Info.plist", ofType: nil),
            let infoAttr = try? FileManager.default.attributesOfItem(atPath: infoPath),
            let infoDate = infoAttr[FileAttributeKey.creationDate] as? Date
            {
                return infoDate
            }
        return Date()
    }
}
