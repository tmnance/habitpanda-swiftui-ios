import SwiftUI
import CoreData

// Shared view for check-in menu content
struct CheckInMenuContent: View {
    @Environment(\.managedObjectContext) private var viewContext

    let habit: Habit
    let checkInDateOptions: [Date]
    // Controls whether to show a snooze option and which date to snooze
    let showSnooze: Bool
    // Called after a successful add (either check-in or snooze)
    var afterSuccess: (() -> Void)? = nil
    // Toast helpers
    var onSuccessToast: ((String) -> Void)? = nil
    var onErrorToast: ((String) -> Void)? = nil

    var body: some View {
        Group {
            if habit.checkInType.options.count <= 1 {
                Section(header: Text("Select a Check-in Date")) {
                    ForEach(Array(checkInDateOptions.enumerated()), id: \.element) { i, date in
                        Button(action: {
                            withAnimation {
                                habit.addCheckIn(forDate: date, context: viewContext) { error in
                                    if let error {
                                        onErrorToast?(error.localizedDescription)
                                        return
                                    }
                                    afterSuccess?()
                                    onSuccessToast?("Check-in added")
                                }
                            }
                        }) {
                            Label(
                                DateHelper.getDateString(date),
                                systemImage: i == 0 ? "calendar" : "calendar.badge.clock"
                            )
                        }
                    }
                }
            } else {
                Section(header: Text("Select a Check-in Date")) {
                    ForEach(Array(checkInDateOptions.enumerated()), id: \.element) { i, date in
                        Menu {
                            Section(header: Text("Select a Check-in Value")) {
                                ForEach(habit.checkInType.options, id: \.self) { option in
                                    Button(action: {
                                        withAnimation {
                                            habit.addCheckIn(forDate: date, value: option, context: viewContext) { error in
                                                if let error {
                                                    onErrorToast?(error.localizedDescription)
                                                    return
                                                }
                                                afterSuccess?()
                                                onSuccessToast?("Check-in added")
                                            }
                                        }
                                    }) {
                                        Text(option)
                                    }
                                }
                            }
                        } label: {
                            Label(
                                DateHelper.getDateString(date),
                                systemImage: i == 0 ? "calendar" : "calendar.badge.clock"
                            )
                        }
                    }
                }
            }

            if showSnooze {
                Button(action: {
                    withAnimation {
                        habit.addDayOffCheckIn(forDate: Date().stripTime(), context: viewContext) { error in
                            if let error {
                                onErrorToast?(error.localizedDescription)
                                return
                            }
                            afterSuccess?()
                            onSuccessToast?("Snoozed habit for today")
                        }
                    }
                }) {
                    Label("Snooze for today", systemImage: "zzz")
                }
            }
        }
    }
}

#Preview {
    VStack {
        Menu("Check In!") {
            CheckInMenuContent(
                habit: Habit.example,
                checkInDateOptions: [Date().stripTime()],
                showSnooze: true,
                afterSuccess: {},
                onSuccessToast: { _ in },
                onErrorToast: { _ in }
            )
        }
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
