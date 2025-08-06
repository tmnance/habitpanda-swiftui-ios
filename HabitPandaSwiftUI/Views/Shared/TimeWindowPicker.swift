//
//  TimeWindowPicker.swift
//  HabitPandaSwiftUI
//
//  Created by Tim Nance on 3/12/25.
//

import SwiftUI

struct TimeWindowPicker: View {
    @Environment(\.managedObjectContext) private var viewContext

    @State private var isAllActive = true
    @State private var timeWindows: [TimeWindow] = []

    private struct TimeWindowToggleState: Equatable {
      let timeWindow: TimeWindow
      var isActive: Bool
    }

    @State private var timeWindowOptionToggleStates: [TimeWindowToggleState] = []

    @State var showAllButton: Bool = false
    @Binding var selectedTimeWindows: Set<TimeWindow>

    var body: some View {
        VStack {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 110))], spacing: 5) {
                if showAllButton {
                    Toggle(isOn: $isAllActive) {
                        Text("All")
                            .padding(6)
                            .minimumScaleFactor(0.75)
                            .lineLimit(0)
                            .frame(maxWidth: .infinity)
                    }
                    .toggleStyle(.button)
                }

                ForEach($timeWindowOptionToggleStates, id: \.timeWindow.uuid) { $timeWindowOption in
                    Toggle(isOn: $timeWindowOption.isActive) {
                        Text(timeWindowOption.timeWindow.displayName)
                            .padding(6)
                            .minimumScaleFactor(0.75)
                            .lineLimit(0)
                            .frame(maxWidth: .infinity)
                    }
                    .toggleStyle(.button)
                }
                .onChange(of: isAllActive) {
                    let activeTimeWindowOptionToggleStates = timeWindowOptionToggleStates.filter { $0.isActive }
                    if isAllActive && activeTimeWindowOptionToggleStates.count != timeWindows.count {
                        for (index, _) in timeWindowOptionToggleStates.enumerated() {
                            timeWindowOptionToggleStates[index].isActive = false
                        }
                    } else if (selectedTimeWindows.count == 0 || activeTimeWindowOptionToggleStates.count == timeWindows.count) {
                        isAllActive = true
                    }
                }
                .onChange(of: timeWindowOptionToggleStates) {
                    let activeTimeWindowOptionToggleStates = timeWindowOptionToggleStates.filter { $0.isActive }
                    selectedTimeWindows = Set(activeTimeWindowOptionToggleStates.map { $0.timeWindow })
                    if activeTimeWindowOptionToggleStates.count == 0 || activeTimeWindowOptionToggleStates.count == timeWindows.count {
                        isAllActive = true
                    } else if activeTimeWindowOptionToggleStates.count > 0 {
                        isAllActive = false
                    }
                }
            }
        }
        .onAppear {
            timeWindows = TimeWindow.getAll(
                context: viewContext
            )
            timeWindowOptionToggleStates = timeWindows.map {
                TimeWindowToggleState(timeWindow: $0, isActive: false)
            }
            for (index, toggleState) in timeWindowOptionToggleStates.enumerated() {
                timeWindowOptionToggleStates[index].isActive = selectedTimeWindows.contains(toggleState.timeWindow)
            }
        }
    }
}

struct TimeWindowPicker_Previews: PreviewProvider {
    struct Container: View {
        @State var selectedTimeWindows: Set<TimeWindow> = []
        @State var showAllButton: Bool = false
        var body: some View {
            TimeWindowPicker(
                showAllButton: showAllButton,
                selectedTimeWindows: $selectedTimeWindows
            )
        }
    }

    static var previews: some View {
        let viewContext = PersistenceController.preview.container.viewContext
        let timeWindows = TimeWindow.getAll(context: viewContext)

        VStack(spacing: 20) {
            Container(
                selectedTimeWindows: Set(
                    [timeWindows.first, timeWindows.last].compactMap { $0 }
                )
            )
            Container(showAllButton: true).padding(.horizontal)
        }
        .environment(\.managedObjectContext, viewContext)
    }
}
