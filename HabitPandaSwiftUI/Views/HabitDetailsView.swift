//
//  HabitDetailsView.swift
//  HabitPandaSwiftUI
//
//  Created by Tim Nance on 10/7/22.
//

import SwiftUI

struct HabitDetailsView: View {
    private enum TabOption: Hashable {
        case summary, checkIns, reminders
    }
    @State var habit: Habit
    @State private var tabSelection: TabOption = .summary
    @State private var selectedTab: TabOption = .summary

    var body: some View {
        VStack {
            HStack {
                Text(habit.name ?? "")
                Spacer()
                Text("Check In!")
            }
            //            .frame(maxWidth: .infinity, alignment: .leading)
            Color(red: .random(in: 0...1), green: .random(in: 0...1), blue: .random(in: 0...1))
                .frame(width: 50, height: 50)

            Picker(selection: $tabSelection, label: Text("mylabel")) {
                Text("Summary").tag(TabOption.summary)
                Text("Check-ins").tag(TabOption.checkIns)
                Text("Reminders").tag(TabOption.reminders)
            }.pickerStyle(.segmented)

            TabView(selection: $tabSelection) {
                VStack {
                    Text("Summary 2")
                    Color(red: .random(in: 0...1), green: .random(in: 0...1), blue: .random(in: 0...1))
                        .frame(width: 50, height: 50)
                }
                .tag(TabOption.summary)

                VStack {
                    Text("Check-ins 2")
                    Color(red: .random(in: 0...1), green: .random(in: 0...1), blue: .random(in: 0...1))
                    .frame(width: 50, height: 50)
                }
                .tag(TabOption.checkIns)

                VStack {
                    Text("Reminders 2")
                    Color(red: .random(in: 0...1), green: .random(in: 0...1), blue: .random(in: 0...1))
                    .frame(width: 50, height: 50)
                }
                .tag(TabOption.reminders)
            }
            .background(.yellow)
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

            Spacer()
        }
        .navigationTitle("Habit Details")
    }
}

struct HabitDetailsView_Previews: PreviewProvider {
    static let persistence = PersistenceController.preview
    static var habit: Habit = {
        let context = persistence.container.viewContext
        let habit = Habit(context: context)
        habit.createdAt = Date()
        habit.uuid = UUID()
        habit.name = "Test habit"
        habit.frequencyPerWeek = Int32(5)
        habit.order = Int32(0)
        return habit
    }()

    static var previews: some View {
        HabitDetailsView(habit: habit)
            .environment(\.managedObjectContext, persistence.container.viewContext)
    }
}
