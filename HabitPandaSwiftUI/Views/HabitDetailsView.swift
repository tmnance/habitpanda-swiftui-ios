//
//  HabitDetailsView.swift
//  HabitPandaSwiftUI
//
//  Created by Tim Nance on 10/7/22.
//

import SwiftUI
import CoreData

struct HabitDetailsView: View {
    enum TabOption: Hashable {
        case summary, checkIns, reminders
    }
    @Environment(\.managedObjectContext) private var viewContext

    @ObservedObject var habit: Habit
    @State var selectedTab: TabOption = .summary
    @State private var toast: FancyToast? = nil
    @State private var isEditHabitViewPresented = false
    @State private var currentDate = Date().stripTime()

    private var checkInDateOptions: [Date] {
        let today = Date().stripTime()
        return Array(0...4).map { Calendar.current.date(byAdding: .day, value: (-1 * $0), to: today)! }
    }
    @FetchRequest var mostRecentCheckIns: FetchedResults<CheckIn>

    init(habit: Habit) {
        self.habit = habit
        let request: NSFetchRequest<CheckIn> = CheckIn.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \CheckIn.checkInDate, ascending: false),
        ]
        request.predicate = NSPredicate(format: "habit == %@", habit)
        request.fetchLimit = 1
        _mostRecentCheckIns = FetchRequest(fetchRequest: request)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(habit.name ?? "")
                    .font(.system(size: 20))
                    .lineLimit(3)
                Spacer()
                Menu {
                    Section(header: Text("Select a Check-in Date")) {
                        ForEach(Array(checkInDateOptions.enumerated()), id: \.element) { i, date in
                            Button(action: {
                                withAnimation {
                                    habit.addCheckIn(forDate: date, context: viewContext) { error in
                                        if let error {
                                            toast = FancyToast.errorMessage(error.localizedDescription)
                                            return
                                        }
                                        toast = FancyToast(
                                            type: .success,
                                            message: "Check-in added",
                                            duration: 2,
                                            tapToDismiss: true
                                        )
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
                    if !anyCheckInsToday() && !isTodayOff() {
                        Button(action: {
                            withAnimation {
                                habit.addCheckIn(
                                    forDate: Date().stripTime(),
                                    resultType: .dayOff,
                                    context: viewContext
                                ) { error in
                                    if let error {
                                        toast = FancyToast.errorMessage(error.localizedDescription)
                                        return
                                    }
                                    toast = FancyToast(
                                        type: .success,
                                        message: "Snoozed habit for today",
                                        duration: 2,
                                        tapToDismiss: true
                                    )
                                }
                            }
                        }) {
                            Label(
                                "Snooze for today",
                                systemImage: "zzz"
                            )
                        }
                    }
                }
                label: {
                    Text("Check In!")
                        .font(.system(size: 15))
                        .foregroundColor(Color(Constants.Colors.checkInButtonText))
                        .padding(12)
                        .frame(height: Constants.comfortableTappableDimension)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color(Constants.Colors.checkInButtonBorder), lineWidth: 1)
                        )
                }
                // fixes layout bug with keyboard dismiss on the habit edit view
                // TODO: confirm this is still necessary on newer versions of iOS (>16)
                .frame(height: Constants.comfortableTappableDimension)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)

            Picker("", selection: $selectedTab) {
                Text("Summary").tag(TabOption.summary)
                Text("Check-ins").tag(TabOption.checkIns)
                Text("Reminders").tag(TabOption.reminders)
            }
            .pickerStyle(.segmented)

            switch selectedTab {
            case .summary:
                HabitDetailsSummaryTabView(habit: habit)
            case .checkIns:
                HabitDetailsCheckInsTabView(habit: habit)
            case .reminders:
                HabitDetailsRemindersTabView(habit: habit)
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .toastView(toast: $toast)
        .fullScreenCover(isPresented: $isEditHabitViewPresented) {
            AddEditHabitView(habitToEdit: habit)
        }
        // date change redraws view
        .id("habitDetails-\(currentDate.formatted(.dateTime.month(.twoDigits).day(.twoDigits)))")
        .onNewDay {
            withAnimation {
                currentDate = Date().stripTime()
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    isEditHabitViewPresented.toggle()
                }
                .frame(minWidth: Constants.minTappableDimension)
                .frame(height: Constants.minTappableDimension)
            }
        }
        .navigationTitle("Habit Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    func anyCheckInsToday() -> Bool {
        return mostRecentCheckIns.first?.checkInDate == currentDate
    }

    func isTodayOff() -> Bool {
        if let mostRecentCheckIn = mostRecentCheckIns.first {
            if mostRecentCheckIn.checkInDate == currentDate {
                return mostRecentCheckIn.resultType == .dayOff
            }
            if habit.checkInCooldownDays > 0 &&
                Calendar.current.dateComponents(
                    [.day],
                    from: mostRecentCheckIn.checkInDate!,
                    to: currentDate
                ).day! <= habit.checkInCooldownDays {
                return true
            }
        }
        if habit.hasInactiveDaysOfWeek() {
            let inactiveDaysOfWeek = Set((habit.inactiveDaysOfWeek ?? [])
                .compactMap { $0.intValue })
            let currentDayOffset = (Calendar.current.component(.weekday, from: currentDate) % 7) - 1
            return inactiveDaysOfWeek.contains(currentDayOffset)
        }
        return false
    }
}

struct HabitDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            HabitDetailsView(habit: Habit.example)
        }
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
