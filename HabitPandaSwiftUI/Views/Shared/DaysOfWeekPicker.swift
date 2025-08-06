//
//  DaysOfWeekPicker.swift
//  HabitPandaSwiftUI
//
//  Created by Tim Nance on 1/23/23.
//

import SwiftUI

struct DaysOfWeekPicker: View {
    struct WeekSubsetOption {
        var tag: DayOfWeek.WeekSubset
        var label: String

        init(_ tag: DayOfWeek.WeekSubset, label: String? = nil) {
            self.tag = tag
            self.label = label ?? tag.description
        }
    }

    private struct DayToggleState: Equatable {
      let day: DayOfWeek.Day
      var isActive: Bool
    }

    @State private var selectedWeekSubset: DayOfWeek.WeekSubset = .custom
    @State private var dayOptionToggleStates = {
        return DayOfWeek.Day.allCases.map {
            DayToggleState(day: $0, isActive: false)
        }
    }()
    @Binding var selectedDays: Set<DayOfWeek.Day>
    var weekSubsetOptions: [WeekSubsetOption] = [
        WeekSubsetOption(.all),
        WeekSubsetOption(.weekdays),
        WeekSubsetOption(.weekends),
        WeekSubsetOption(.custom),
    ]

    var body: some View {
        VStack {
            Picker("", selection: $selectedWeekSubset) {
                ForEach(weekSubsetOptions, id: \.tag) { weekSubsetOption in
                    Text(weekSubsetOption.label).tag(weekSubsetOption.tag)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedWeekSubset) {
                // only change the day toggle values if they don't currently match the new picker option
                if selectedWeekSubset != getCurrentWeekSubsetFromActiveDays() {
                    updateSelectedDays(forWeekSubset: selectedWeekSubset)
                }
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 5) {
                ForEach($dayOptionToggleStates, id: \.day.rawValue) { $dayOption in
                    Toggle(isOn: $dayOption.isActive) {
                        Text(dayOption.day.description)
                            .padding(6)
                            .frame(maxWidth: .infinity)
                    }
                    .toggleStyle(.button)
                }
                .onChange(of: dayOptionToggleStates) {
                    selectedWeekSubset = getCurrentWeekSubsetFromActiveDays()
                    selectedDays = Set(dayOptionToggleStates.filter { $0.isActive }.map { $0.day })
                }
            }
        }
        .onAppear {
            for (index, toggleState) in dayOptionToggleStates.enumerated() {
                dayOptionToggleStates[index].isActive = selectedDays.contains(toggleState.day)
            }
        }
    }

    private func updateSelectedDays(forWeekSubset weekSubset: DayOfWeek.WeekSubset) {
        for (index, toggleState) in dayOptionToggleStates.enumerated() {
            self.dayOptionToggleStates[index].isActive = weekSubset.days.contains(toggleState.day)
        }
    }

    private func getCurrentWeekSubsetFromActiveDays() -> DayOfWeek.WeekSubset {
        let currentActiveDaySet = Set(dayOptionToggleStates.filter { $0.isActive }.map { $0.day })
        // verify this option is available
        if !Set(weekSubsetOptions.map { $0.tag.days }).contains(currentActiveDaySet) {
            return .custom
        }
        switch currentActiveDaySet {
        case DayOfWeek.WeekSubset.all.days:
            return .all
        case DayOfWeek.WeekSubset.weekdays.days:
            return .weekdays
        case DayOfWeek.WeekSubset.weekends.days:
            return .weekends
        default:
            return .custom
        }
    }
}

struct DaysOfWeekPicker_Previews: PreviewProvider {
    struct Container: View {
        @State var selectedDays: Set<DayOfWeek.Day> = []
        var weekSubsetOptions: [DaysOfWeekPicker.WeekSubsetOption]? = nil
        var body: some View {
            if let weekSubsetOptions {
                DaysOfWeekPicker(
                    selectedDays: $selectedDays,
                    weekSubsetOptions: weekSubsetOptions
                )
            } else {
                DaysOfWeekPicker(selectedDays: $selectedDays)
            }
        }
    }

    static var previews: some View {
        VStack(spacing: 20) {
            Container(selectedDays: [.sat, .sun])
            Container().padding(.horizontal)
            Container(
                weekSubsetOptions: [
                    DaysOfWeekPicker.WeekSubsetOption(.weekdays),
                    DaysOfWeekPicker.WeekSubsetOption(.weekends),
                    DaysOfWeekPicker.WeekSubsetOption(.custom),
                ]
            )
        }
    }
}
