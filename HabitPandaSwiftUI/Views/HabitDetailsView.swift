//
//  HabitDetailsView.swift
//  HabitPandaSwiftUI
//
//  Created by Tim Nance on 10/7/22.
//

import SwiftUI
import AlertToast

struct HabitDetailsView: View {
    enum TabOption: Hashable {
        case summary, checkIns, reminders
    }
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var router: Router
    @State var habit: Habit
    @State var selectedTab: TabOption = .summary
    @State private var showToast = false
    @State private var toastText = ""
    private var checkInDateOptions: [Date] {
        let today = Date().stripTime()
        var dateArray = [today]
        for i in 1...4 {
            let pastDay = Calendar.current.date(byAdding: .day, value: (-1 * i), to: today)!
            dateArray.append(pastDay)
        }
        return dateArray
    }

    var body: some View {
        VStack {
            HStack {
                Text(habit.name ?? "")
                    .lineLimit(1)
                Spacer()
                Menu {
                    Section(header: Text("Select a Check-in Date")) {
                        ForEach(Array(checkInDateOptions.enumerated()), id: \.element) { i, date in
                            Button(action: {
                                addCheckIn(forDate: date)
                                toastText = "Check-in added"
                                showToast = true
                            }) {
                                Label(
                                    date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)),
                                    systemImage: i == 0 ? "calendar" : "calendar.badge.clock"
                                )
                            }
                        }

                        Button(action: {}) {
                            Text("Cancel")
                        }
                    }
                }
                label: {
                    Text("Check In!")
                        .foregroundColor(.blue)
                        .padding(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.blue, lineWidth: 1)
                        )
                }
            }
            .padding()

            Picker("", selection: $selectedTab) {
                Text("Summary").tag(TabOption.summary)
                Text("Check-ins").tag(TabOption.checkIns)
                Text("Reminders").tag(TabOption.reminders)
            }.pickerStyle(.segmented)

            switch selectedTab {
            case .summary:
                HabitSummaryTabView(habit: habit)
            case .checkIns:
                HabitCheckInsTabView(habit: habit)
            case .reminders:
                HabitRemindersTabView(habit: habit)
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .toast(isPresenting: $showToast, duration: 2, tapToDismiss: true) {
            AlertToast(type: .complete(.green), title: toastText)
        }
        .navigationTitle("Habit Details")
    }

    func addCheckIn(forDate date: Date) {
        // TODO: may want to move this to the habit model
        let checkInToSave = CheckIn(context: viewContext)

        checkInToSave.createdAt = Date()
        checkInToSave.uuid = UUID()
        checkInToSave.habit = habit
        checkInToSave.checkInDate = date.stripTime()
        checkInToSave.isSuccess = true

        do {
            // TODO: not the right way to handle preview save
//            try viewContext.save() // use this one?
            try PersistenceController.shared.save()
//            ReminderNotificationService.refreshNotificationsForAllReminders()
        } catch {
            print("Error saving context, \(error)")
        }
    }
}

struct HabitDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        HabitDetailsView(habit: Habit.getPreviewHabit())
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
