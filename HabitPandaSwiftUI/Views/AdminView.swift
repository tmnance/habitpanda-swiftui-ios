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
    @State private var showConfirmAlert = false
    @State private var confirmAlertText = ""
    @State private var confirmAlertMessage = ""
    @State private var confirmAlertConfirmCallback: () -> Void = {}
    @State private var pendingRequests: [UNNotificationRequest] = []
    @State private var deliveredNotifications: [UNNotification] = []

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Reminder.createdAt, ascending: true)],
        animation: .none)
    private var reminders: FetchedResults<Reminder>

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(getReportMarkdownText())
                .font(.footnote)
                .padding(.horizontal)
                .padding(.vertical, 8)

            List {
                Section(header: Spacer(minLength: 0)) {
                    Button("Remove all pending notifications") {
                        NotificationHelper.removeAllPendingNotifications()
                        self.loadNotificationData()
                        showToast("Pending notifications removed")
                    }

                    Button("Remove all sent notifications") {
                        NotificationHelper.removeAllDeliveredNotifications()
                        self.loadNotificationData()
                        showToast("Sent notifications removed")
                    }

                    Button("Remove orphaned sent notifications") {
                        ReminderNotificationService.removeOrphanedDeliveredNotifications()
                        self.loadNotificationData()
                        showToast("Orphaned sent notifications removed")
                    }

                    Button("(Re)set all notifications") {
                        ReminderNotificationService.refreshNotificationsForAllReminders()
                        self.loadNotificationData()
                        showToast("All notifications refreshed")
                    }

                    Button("Send test notification") {
                        ReminderNotificationService.sendTestNotification()
                        showToast("Test notification sent")
                    }
                }

                Section() {
                    Button("Seed test data (normal)") {
                        showConfirmPrompt(
                            text: "Confirm Seed Data",
                            message: "Warning: seeding test data will clear all existing data",
                            confirmCallback: {
                                createSeedTestHabits()
                                ReminderNotificationService.refreshNotificationsForAllReminders()
                                self.loadNotificationData()
                                showToast("Test data seeded")
                            }
                        )
                    }

                    Button("Seed test data (large dataset)") {
                        showConfirmPrompt(
                            text: "Confirm Seed Data (large dataset)",
                            message: "Warning: seeding test data will clear all existing data",
                            confirmCallback: {
                                createSeedTestHabits(useLargeDataSet: true)
                                ReminderNotificationService.refreshNotificationsForAllReminders()
                                self.loadNotificationData()
                                showToast("Test data seeded")
                            }
                        )
                    }

                    Button("Delete all data") {
                        showConfirmPrompt(
                            text: "Delete All Data",
                            message: "Warning: this will clear all existing data",
                            confirmCallback: {
                                deleteAllHabits()
                                ReminderNotificationService.refreshNotificationsForAllReminders()
                                self.loadNotificationData()
                                showToast("All habit data deleted")
                            }
                        )
                    }
                }

                Section() {
                    Button("Export current data") {
                        self.exportCurrentData()
                        showToast("Current data exported to clipboard")
                    }

                    Button("Import data") {
                        showConfirmPrompt(
                            text: "Import data from clipboard",
                            message: "Warning: this will clear all existing data",
                            confirmCallback: {
                                if self.importData() {
                                    showToast("Data imported from clipboard")
                                    ReminderNotificationService.refreshNotificationsForAllReminders()
                                    self.loadNotificationData()
                                } else {
                                    showToast("Unable to import data from clipboard")
                                }
                            }
                        )
                    }
                }
            }
        }
        .alert(
            isPresented: $showConfirmAlert,
            content: {
                Alert(
                    title: Text(confirmAlertText),
                    message: Text(confirmAlertMessage),
                    primaryButton: .default(
                        Text("Cancel")
                    ),
                    secondaryButton: .destructive(
                        Text("Confirm"),
                        action: confirmAlertConfirmCallback
                    )
                )
            }
        )
        .toast(isPresenting: $showToast, duration: 2, tapToDismiss: true) {
            AlertToast(type: .regular, title: toastText)
        }
        .onAppear {
            loadNotificationData()
        }
        .navigationTitle("Admin")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func showConfirmPrompt(text: String, message: String, confirmCallback: @escaping () -> Void) {
        showConfirmAlert = true
        confirmAlertText = text
        confirmAlertMessage = message
        confirmAlertConfirmCallback = confirmCallback
    }

    private func showToast(_ text: String) {
        toastText = text
        showToast = true
    }

    private func loadNotificationData() {
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
}


// MARK: - UI Update Methods
extension AdminView {
    private var buildDate:Date
    {
        if let infoPath = Bundle.main.path(forResource: "Info.plist", ofType: nil),
            let infoAttr = try? FileManager.default.attributesOfItem(atPath: infoPath),
            let infoDate = infoAttr[FileAttributeKey.creationDate] as? Date
            {
                return infoDate
            }
        return Date()
    }

    private func getReportMarkdownText() -> LocalizedStringKey {
        let reportString = (
            "\(getAppVersionString())\n" +
            "\(getRemindersReportString())\n" +
            "\(getNotificationsReportString())"
        ).replacing(/\n-[ ]/, with: "\n  - ") // indent bulleted lines
        return LocalizedStringKey(stringLiteral: reportString)
    }

    private func getNotificationsReportString() -> String {
        return "**Notifications:**\n" +
            "- \(pendingRequests.count) pending, " +
            "\(deliveredNotifications.count) delivered"
    }

    private func getRemindersReportString() -> String {
        var notificationCount = 0
        var habitUUIDs = Set<UUID>()

        let remindersByDay = ReminderNotificationService.RemindersForWeek(forReminders: Array(reminders))

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

        return "**Reminders:**\n" +
            "- currentWeekdayIndex = \(currentWeekdayIndex)\n" +
            "- weekdayIndexLoop = \(weekdayIndexLoop)\n" +
            "- currentTimeInMinutes = \(currentTimeInMinutes)\n" +
            "- \(notificationCount) notification\(notificationCount == 1 ? "" : "s") " +
            "will be needed across \(habitUUIDs.count) habit\(habitUUIDs.count == 1 ? "" : "s")"
    }

    private func getAppVersionString() -> String {
        let dictionary = Bundle.main.infoDictionary!
        let version = dictionary["CFBundleShortVersionString"] as! String
        let build = dictionary["CFBundleVersion"] as! String
        let appName = dictionary["CFBundleName"] as! String

        return "**App version:** \(appName) v\(version) (Build \(build))\n" +
            "- buildDate = \(getDateAsString(buildDate))"
    }

    private func getDateAsString(_ date: Date) -> String {
        let df = DateFormatter()

        df.dateFormat = "EEE, MMMM d"
        let displayDate = df.string(from: date)

        df.dateFormat = "h:mm a"
        let displayTime = df.string(from: date)

        return "\(displayDate) at \(displayTime)"
    }
}


// MARK: - Data Modification Methods
extension AdminView {
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
            let newHabit = createHabit(
                name: seedHabit["name"] as? String ?? "",
                frequencyPerWeek: seedHabit["frequencyPerWeek"] as? Int ?? 1,
                createdAt: Calendar.current.date(
                    byAdding: .second,
                    value: i,
                    to: createdAtDate
                )!,
                order: i
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
                            let _ = createCheckIn(habit: newHabit, createdAt: checkInDate)
                        }
                    }
                }

            if let seedReminders = seedHabit["reminders"] as? [[String:Any]] {
                seedReminders.forEach { seedReminder in
                    let frequencyDays = Array(seedReminder["frequencyDays"] as? String ?? "")
                        .enumerated()
                        .filter { $0.1 != " " }
                        .map { $0.0 as Int }
                    let _ = createReminder(
                        habit: newHabit,
                        hour: seedReminder["hour"] as? Int ?? 0,
                        minute: seedReminder["minute"] as? Int ?? 0,
                        frequencyDays: frequencyDays
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

    private func createHabit(
        uuid: UUID? = nil,
        name: String,
        frequencyPerWeek: Int,
        createdAt: Date,
        order: Int
    ) -> Habit {
        let habitToSave = Habit(context: viewContext)
        habitToSave.createdAt = createdAt
        habitToSave.uuid = uuid ?? UUID()
        habitToSave.name = name
        habitToSave.frequencyPerWeek = Int32(frequencyPerWeek)
        habitToSave.order = Int32(order)

        return habitToSave
    }

    private func createCheckIn(
        uuid: UUID? = nil,
        habit: Habit,
        createdAt: Date,
        checkInDate: Date? = nil
    ) -> CheckIn {
        let checkInToSave = CheckIn(context: viewContext)
        checkInToSave.createdAt = createdAt
        checkInToSave.uuid = uuid ?? UUID()
        checkInToSave.habit = habit
        checkInToSave.checkInDate = checkInDate ?? createdAt.stripTime()
        checkInToSave.isSuccess = true

        return checkInToSave
    }

    private func createReminder(
        uuid: UUID? = nil,
        habit: Habit,
        createdAt: Date? = nil,
        hour: Int,
        minute: Int,
        frequencyDays: [Int]
    ) -> Reminder {
        let reminderToSave = Reminder(context: viewContext)
        reminderToSave.createdAt = createdAt ?? Date()
        reminderToSave.uuid = uuid ?? UUID()
        reminderToSave.habit = habit
        reminderToSave.hour = Int32(hour)
        reminderToSave.minute = Int32(minute)
        reminderToSave.frequencyDays = frequencyDays.map { $0 as NSNumber }

        return reminderToSave
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


// MARK: - Data Export Methods
extension AdminView {
    private struct ExportHabit: Codable {
        let uuid: String
        let createdAt: Int
        let name: String
        let order: Int
        let frequencyPerWeek: Int
        let checkIns: [ExportCheckIn]
        let reminders: [ExportReminder]

        init(habit: Habit) {
            self.uuid = habit.uuid!.uuidString
            self.createdAt = Int(habit.createdAt!.timeIntervalSince1970)
            self.name = habit.name!
            self.order = Int(habit.order)
            self.frequencyPerWeek = Int(habit.frequencyPerWeek)
            self.checkIns = (habit.checkIns as? Set<CheckIn> ?? [])
                .sorted { $0.createdAt! < $1.createdAt! }
                .map { ExportCheckIn(checkIn: $0) }
            self.reminders = (habit.reminders as? Set<Reminder> ?? [])
                .sorted { $0.createdAt! < $1.createdAt! }
                .map { ExportReminder(reminder: $0) }
        }
    }

    private struct ExportCheckIn: Codable {
        let uuid: String
        let createdAt: Int
        let checkInDate: Int
        let isSuccess: Bool

        init(checkIn: CheckIn) {
            self.uuid = checkIn.uuid!.uuidString
            self.createdAt = Int(checkIn.createdAt!.timeIntervalSince1970)
            self.checkInDate = Int(checkIn.checkInDate!.timeIntervalSince1970)
            self.isSuccess = checkIn.isSuccess
        }
    }

    private struct ExportReminder: Codable {
        let uuid: String
        let createdAt: Int
        let isEnabled: Bool
        let hour: Int
        let minute: Int
        let frequencyDays: [Int]

        init(reminder: Reminder) {
            self.uuid = reminder.uuid!.uuidString
            self.createdAt = Int(reminder.createdAt!.timeIntervalSince1970)
            self.isEnabled = reminder.isEnabled
            self.hour = Int(reminder.hour)
            self.minute = Int(reminder.minute)
            self.frequencyDays = (reminder.frequencyDays ?? []).map { Int(truncating: $0) }
        }
    }

    private func exportCurrentData() {
        let exportData: [ExportHabit] = Habit.getAll(
            sortedBy: [("order", .asc), ("createdAt", .asc)],
            context: viewContext
        )
            .map { ExportHabit(habit: $0) }
        let jsonEncoder = JSONEncoder()

        do {
            let jsonData = try jsonEncoder.encode(exportData)
            let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
            let pasteboard = UIPasteboard.general
            pasteboard.string = jsonString
        } catch {
            print(error.localizedDescription)
        }
    }

    private func importData() -> Bool {
        let pasteboard = UIPasteboard.general
        guard let importString = pasteboard.string else { return false }
        guard let jsonString = importString.data(using: .utf8) else { return false }
        let importedHabits: [ExportHabit] = {
            do {
                return try JSONDecoder().decode([ExportHabit].self, from: jsonString)
            } catch {
                return []
            }
        }()
        guard importedHabits.count > 0 else { return false }

        deleteAllHabits()

        importedHabits.forEach{ habit in
            let newHabit = createHabit(
                uuid: UUID(uuidString: habit.uuid),
                name: habit.name,
                frequencyPerWeek: habit.frequencyPerWeek,
                createdAt: Date(timeIntervalSince1970: Double(habit.createdAt)),
                order: habit.order
            )
            habit.checkIns.forEach { checkIn in
                let _ = createCheckIn(
                    uuid: UUID(uuidString: checkIn.uuid),
                    habit: newHabit,
                    createdAt: Date(timeIntervalSince1970: Double(checkIn.createdAt)),
                    checkInDate: Date(timeIntervalSince1970: Double(checkIn.checkInDate))
                )
            }
            habit.reminders.forEach { reminder in
                let _ = createReminder(
                    habit: newHabit,
                    hour: reminder.hour,
                    minute: reminder.minute,
                    frequencyDays: reminder.frequencyDays
                )
            }
        }

        do {
            try PersistenceController.save(context: viewContext)
        } catch {
            print(error.localizedDescription)
        }

        return true
    }
}


struct AdminView_Previews: PreviewProvider {
    static var previews: some View {
        AdminView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
