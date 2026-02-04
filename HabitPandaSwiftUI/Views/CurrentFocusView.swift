//
//  CurrentFocusView.swift
//  HabitPandaSwiftUI
//
//  Created by Tim Nance on 2/11/25.
//

import SwiftUI
import CoreData

struct CurrentFocusView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @State private var toast: FancyToast? = nil
    @State private var today: Date = Date().today()
    @State private var yesterday: Date = Date().yesterday()
    @State private var mostRecent: MostRecentTimeWindowStore.Entry? = nil
    @State private var refreshID: UUID = UUID()

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \TimeWindow.order, ascending: true)],
        animation: .none)
    private var timeWindows: FetchedResults<TimeWindow>

    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Habit.order, ascending: true),
            NSSortDescriptor(keyPath: \Habit.createdAt, ascending: true)
        ],
        animation: .none)
    private var habits: FetchedResults<Habit>

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Group {
                    if shouldShowWrapUpYesterday(), let lastYesterdayWindow = wrapUpYesterdayWindows().last {
                        VStack(spacing: 0) {
                            header(for: lastYesterdayWindow, isForYesterday: true)
                            eligibleHabitList(for: wrapUpYesterdayWindows(), on: yesterday)
                        }
                    } else if let currentWindow = currentTimeWindow() {
                        header(for: currentWindow)
                        eligibleHabitList(for: [currentWindow], on: today)
                    } else {
                        emptyState()
                    }
                }
                .id(refreshID)
                .frame(maxWidth: .infinity, alignment: .top)
            }
            .padding(.horizontal)
            .padding(.top, 10)
            .toastView(toast: $toast)
            .navigationTitle("Current Focus")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { reloadState() }
            .onNewDay {
                today = Date().today()
                yesterday = Date().yesterday()
                reloadState()
            }
        }
    }
}

// MARK: - UI Builders
extension CurrentFocusView {
    @ViewBuilder private func header(for timeWindow: TimeWindow, isForYesterday: Bool = false) -> some View {
        HStack {
            Text(isForYesterday ? "Wrap up Yesterday" : "\(timeWindow.displayEmoji) \(timeWindow.displayName)")
                .font(.system(size: 22, weight: .semibold))
            Spacer()
            HStack(spacing: 8) {
                if !isForYesterday, let _ = lastCompletedWindowToday(), !currentTimeWindowIsFirstOfDay() {
                    Button(action: { undoLastFinish() }) {
                        Text("Undo last finish")
                            .font(.system(size: 14, weight: .semibold))
                            .padding(.horizontal, 12)
                            .frame(height: Constants.comfortableTappableDimension)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Constants.Colors.checkInButtonBorder, lineWidth: 1)
                            )
                    }
                }
                Button(action: { finishUp(timeWindow, on: isForYesterday ? yesterday : today) }) {
                    Text("Finish up\(isForYesterday ? "" : " " + timeWindow.displayName)")
                        .font(.system(size: 14, weight: .semibold))
                        .padding(.horizontal, 12)
                        .frame(height: Constants.comfortableTappableDimension)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Constants.Colors.checkInButtonBorder, lineWidth: 1)
                        )
                }
            }
        }
        .padding(.bottom, 8)
    }

    @ViewBuilder private func eligibleHabitList(for timeWindows: [TimeWindow], on date: Date) -> some View {
        let eligible = eligibleHabits(for: timeWindows, on: date)
        if eligible.isEmpty {
            VStack(spacing: 8) {
                Text("No habits to show right now")
                    .font(.title3)
                let joinedNames = timeWindows.map { $0.displayName }.joined(separator: "/")
                Text("You're all caught up for \(joinedNames)!")
                    .font(.footnote)
                    .foregroundColor(Constants.Colors.subText)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 30)
        } else {
            List {
                ForEach(eligible, id: \.self) { habit in
                    habitRow(habit: habit, on: date)
                }
            }
            .listStyle(.plain)
        }
    }

    @ViewBuilder private func habitRow(habit: Habit, on date: Date) -> some View {
        HStack(spacing: 10) {
            TimeWindowShortDisplayView(timeWindows: habit.timeWindows as? Set<TimeWindow>)
                .frame(width: 40)
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name ?? "")
                    .font(.system(size: 17))
                Text("🎯 \(habit.frequencyPerWeek)x/wk")
                    .font(.footnote)
                    .foregroundColor(Constants.Colors.subText)
            }
            Spacer()
            Menu {
                CheckInMenuContent(
                    habit: habit,
                    checkInDateOptions: [date],
                    showSnooze: Calendar.current.isDateInToday(date),
                    afterSuccess: { reloadState() },
                    onSuccessToast: { message in
                        toast = FancyToast(type: .success, message: message, duration: 2, tapToDismiss: true)
                    },
                    onErrorToast: { message in
                        toast = FancyToast.errorMessage(message)
                    }
                )
            } label: {
                Text("Check In!")
                    .font(.system(size: 15))
                    .foregroundColor(Constants.Colors.checkInButtonText)
                    .padding(10)
                    .frame(height: Constants.comfortableTappableDimension)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Constants.Colors.checkInButtonBorder, lineWidth: 1)
                    )
            }
        }
        .padding(.vertical, 6)
    }

    @ViewBuilder private func emptyState() -> some View {
        VStack(spacing: 8) {
            Text("🥳")
            Text("No current time window")
                .font(.title3)
            Text("You're done for today, or your next window hasn't started yet.")
                .font(.footnote)
                .foregroundColor(Constants.Colors.subText)
            if let _ = lastCompletedWindowToday(), !currentTimeWindowIsFirstOfDay() {
                Button(action: { undoLastFinish() }) {
                    Text("Undo last finish")
                        .font(.system(size: 14, weight: .semibold))
                        .padding(.horizontal, 12)
                        .frame(height: Constants.comfortableTappableDimension)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Constants.Colors.checkInButtonBorder, lineWidth: 1)
                        )
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 30)
    }
}

// MARK: - Logic
extension CurrentFocusView {
    private func reloadState() {
        mostRecent = MostRecentTimeWindowStore.shared.getMostRecent()
        refreshID = UUID()
    }

    private func finishUp(_ timeWindow: TimeWindow, on date: Date) {
        guard let id = timeWindow.uuid else { return }
        MostRecentTimeWindowStore.shared.markCompleted(timeWindowID: id, on: date)
        reloadState()
        toast = FancyToast(type: .success, message: "Finished \(timeWindow.displayName)", duration: 2, tapToDismiss: true)
    }

    private func currentTimeWindow() -> TimeWindow? {
        let activeToday = TimeWindow.activeWindows(on: today, context: viewContext).sorted { $0.order < $1.order }

        guard !activeToday.isEmpty else {
            return nil
        }

        if
            let recent = mostRecent,
            Calendar.current.isDate(recent.date, inSameDayAs: today),
            let recentWindow = TimeWindow.get(withUUID: recent.timeWindowID, context: viewContext),
            activeToday.contains(where: { $0.objectID == recentWindow.objectID })
        {
            // Find next window with order > recentWindow.order
            let nextWindows = activeToday.filter { $0.order > recentWindow.order }
            return nextWindows.first ?? nil
        } else {
            return activeToday.first
        }
    }

    private func eligibleHabits(for timeWindows: [TimeWindow], on date: Date) -> [Habit] {
        let dayIndex = TimeWindow.dayIndex(for: date)
        let habitsActiveToday = habits.filter { habit in
            habit.isActiveOnDay(dayIndex)
        }

        let notSnoozedToday = habitsActiveToday.filter { habit in
            // Snoozed is represented by a .dayOff check-in for today
            habit.getCheckInsForDate(date, ofType: [.dayOff], context: viewContext).isEmpty
        }

        let noCheckInsToday = notSnoozedToday.filter { habit in
            habit.getCheckInsForDate(date, context: viewContext).isEmpty
        }

        let timeWindowObjectIDs = Set(timeWindows.map(\.objectID))
        let applicableToWindow = noCheckInsToday.filter { habit in
            guard let set = habit.timeWindows as? Set<TimeWindow>, !set.isEmpty else {
                // No time windows => all day
                return true
            }
            // Otherwise must include the current window
            return set.contains(where: { timeWindowObjectIDs.contains($0.objectID) })
        }

        return applicableToWindow
    }

    private func eligibleHabits(for timeWindows: [TimeWindow]) -> [Habit] {
        eligibleHabits(for: timeWindows, on: today)
    }

    private func shouldShowWrapUpYesterday() -> Bool {
        // Consider showing wrap-up if at beginning of day and there are windows to wrap up yesterday
        if currentTimeWindowIsFirstOfDay() && !wrapUpYesterdayWindows().isEmpty {
            // Ensure there would be anything to show
            let eligible = eligibleHabits(for: wrapUpYesterdayWindows(), on: yesterday)
            return !eligible.isEmpty
        }
        return false
    }

    // TODO: memoize
    private func wrapUpYesterdayWindows() -> [TimeWindow] {
        let activeYesterday = TimeWindow.activeWindows(on: yesterday, context: viewContext).sorted { $0.order < $1.order }

        guard !activeYesterday.isEmpty else { return [] }

        if
            let recent = mostRecent,
            Calendar.current.isDate(recent.date, inSameDayAs: yesterday),
            let lastWindow = TimeWindow.get(withUUID: recent.timeWindowID, context: viewContext),
            activeYesterday.contains(where: { $0.objectID == lastWindow.objectID })
        {
            // Return windows with order > lastWindow.order
            return activeYesterday.filter { $0.order > lastWindow.order }
        } else {
            // No completion yesterday, so all active yesterday windows remain
            return activeYesterday
        }
    }

    private func lastCompletedWindowToday() -> TimeWindow? {
        guard
            let recent = mostRecent,
            Calendar.current.isDate(recent.date, inSameDayAs: today),
            let window = TimeWindow.get(withUUID: recent.timeWindowID, context: viewContext)
        else {
            return nil
        }
        return window
    }

    private func undoLastFinish() {
        guard let entry = mostRecent else { return }
        var date = entry.date
        guard let recentWindow = TimeWindow.get(withUUID: entry.timeWindowID, context: viewContext) else { return }

        // Move the most recent completion back to the previous time window (allow wrapping)
        var prev = recentWindow.getPreviousTimeWindow(on: date, allowDayWrap: false, context: viewContext)
        if prev == nil {
            date = Calendar.current.date(byAdding: .day, value: -1, to: date)!
            prev = TimeWindow.lastActiveWindow(on: date, context: viewContext)
        }

        if let prev, let prevID = prev.uuid {
            MostRecentTimeWindowStore.shared.markCompleted(timeWindowID: prevID, on: date)
            reloadState()
            toast = FancyToast(type: .success, message: "Undid finish; back to \(prev.displayName)", duration: 2, tapToDismiss: true)
        } else {
            // If no previous window can be determined, clear the state
            MostRecentTimeWindowStore.shared.reset()
            reloadState()
            toast = FancyToast(type: .success, message: "Undid finish", duration: 2, tapToDismiss: true)
        }
    }

    private func currentTimeWindowIsFirstOfDay() -> Bool {
        // Returns true if there is no mostRecent for today (meaning first time finishing today)
        guard
            let recent = mostRecent,
            Calendar.current.isDate(recent.date, inSameDayAs: today)
        else {
            return true
        }
        return false
    }
}

#Preview {
    NavigationStack {
        CurrentFocusView()
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

