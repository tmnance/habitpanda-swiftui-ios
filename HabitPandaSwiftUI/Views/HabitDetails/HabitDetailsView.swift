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
                HStack(spacing: 0) {
                    TimeWindowShortDisplayView(timeWindows: habit.timeWindows as? Set<TimeWindow>)
                        .padding(.trailing, 4)
                        .frame(width: 40)
                    Text(habit.name ?? "")
                        .font(.system(size: 20))
                        .lineLimit(3)
                }
                Spacer()
                Menu {
                    CheckInMenuContent(
                        habit: habit,
                        checkInDateOptions: checkInDateOptions,
                        showSnooze: (!anyCheckInsToday() && !isTodayOff()),
                        afterSuccess: { /* no-op; view updates via Core Data */ },
                        onSuccessToast: { message in
                            toast = FancyToast(type: .success, message: message, duration: 2, tapToDismiss: true)
                        },
                        onErrorToast: { message in
                            toast = FancyToast.errorMessage(message)
                        }
                    )
                }
                label: {
                    Text("Check In!")
                        .font(.system(size: 15))
                        .foregroundColor(Constants.Colors.checkInButtonText)
                        .padding(12)
                        .frame(height: Constants.comfortableTappableDimension)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Constants.Colors.checkInButtonBorder, lineWidth: 1)
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
                HabitDetailsSummaryView(habit: habit)
            case .checkIns:
                HabitDetailsCheckInsView(habit: habit)
            case .reminders:
                HabitDetailsRemindersView(habit: habit)
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .toastView(toast: $toast)
        .fullScreenCover(isPresented: $isEditHabitViewPresented) {
            HabitAddEditView(habitToEdit: habit)
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
                return mostRecentCheckIn.type == .dayOff
            }
            if habit.checkInCooldownDays > 0,
               let lastDate = mostRecentCheckIn.checkInDate,
               let dayDelta = Calendar.current.dateComponents([.day], from: lastDate, to: currentDate).day,
               dayDelta <= habit.checkInCooldownDays {
                return true
            }
        }
        if habit.hasInactiveDaysOfWeek {
            let currentDayOffset = (Calendar.current.component(.weekday, from: currentDate) % 7) - 1
            return !habit.isActiveOnDay(currentDayOffset)
        }
        return false
    }
}

#Preview {
    NavigationStack {
        HabitDetailsView(habit: Habit.example)
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

