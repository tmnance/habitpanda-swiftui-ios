//
//  DaysOfWeekPicker.swift
//  HabitPandaSwiftUI
//
//  Created by Tim Nance on 1/23/23.
//

import SwiftUI

struct DaysOfWeekPicker: View {
    private struct DaysOfWeekPickerOption: Equatable {
      let day: DayOfWeek.Day
      var isActive: Bool
    }

    @State private var selectedWeekSubsetType: DayOfWeek.WeekSubsetType = .custom
    @State private var dayOptionToggleStates = {
        return DayOfWeek.Day.allCases.map {
            DaysOfWeekPickerOption(day: $0, isActive: false)
        }
    }()
    @Binding var selectedDays: Set<DayOfWeek.Day>
    var pickerOptions: [(DayOfWeek.WeekSubsetType, String)] = [
        (.daily, "Daily"),
        (.weekdays, "Weekdays"),
        (.weekends, "Weekends"),
        (.custom, "Custom"),
    ]

    var body: some View {
        VStack {
            Picker("", selection: $selectedWeekSubsetType) {
                ForEach(pickerOptions, id: \.0) { tag, label in
                    Text(label).tag(tag)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedWeekSubsetType) { _ in
                // only change the day toggle values if they don't currently match the new picker option
                if selectedWeekSubsetType != getCurrentFrequencyOptionFromActiveDays() {
                    updateFrequencyDays(forOption: selectedWeekSubsetType)
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
                .onChange(of: dayOptionToggleStates) { _ in
                    selectedWeekSubsetType = getCurrentFrequencyOptionFromActiveDays()
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

    private func updateFrequencyDays(forOption option: DayOfWeek.WeekSubsetType) {
        for (index, toggleState) in dayOptionToggleStates.enumerated() {
            self.dayOptionToggleStates[index].isActive = option.frequencyDays.contains(toggleState.day)
        }
    }

    private func getCurrentFrequencyOptionFromActiveDays() -> DayOfWeek.WeekSubsetType {
        let currentActiveDaySet = Set(dayOptionToggleStates.filter { $0.isActive }.map { $0.day })
        switch currentActiveDaySet {
        case DayOfWeek.WeekSubsetType.daily.frequencyDays:
            return .daily
        case DayOfWeek.WeekSubsetType.weekdays.frequencyDays:
            return .weekdays
        case DayOfWeek.WeekSubsetType.weekends.frequencyDays:
            return .weekends
        default:
            return .custom
        }
    }
}

struct DaysOfWeekPicker_Previews: PreviewProvider {
    struct Container: View {
        @State var selectedDays: Set<DayOfWeek.Day> = []
        var body: some View {
            DaysOfWeekPicker(selectedDays: $selectedDays)
        }
    }

    static var previews: some View {
        VStack(spacing: 40) {
            Container(selectedDays: [.sat, .sun])
            Container().padding()
        }
    }
}
