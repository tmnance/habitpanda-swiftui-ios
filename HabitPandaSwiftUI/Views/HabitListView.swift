//
//  HabitListView.swift
//  HabitPandaSwiftUI
//
//  Created by Tim Nance on 10/7/22.
//

import SwiftUI

struct HabitListView: View {
    typealias CheckInGridOffsetMap = [Int: Int]
    @Environment(\.managedObjectContext) private var viewContext
    static let daysToDisplay = 30

    @StateObject var router = Router.shared
    @State private var isAddHabitViewPresented = false
    @State private var isReorderHabitsViewPresented = false
    @State private var currentDate = Date().stripTime()

    var body: some View {
        let startDate = Calendar.current.date(
            byAdding: .day,
            value: -1 * (HabitListView.daysToDisplay - 1),
            to: currentDate
        )!
        let endDate = currentDate

        NavigationStack(path: $router.path) {
            HabitListCheckInGridView(startDate: startDate, endDate: endDate)
                // date change redraws view
                .id("checkInGrid-\(currentDate.formatted(.dateTime.month(.twoDigits).day(.twoDigits)))")
                .onNewDay {
                    withAnimation {
                        currentDate = Date().stripTime()
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        NavigationLink(destination: AboutView()) {
                            Text("About")
                        }
                    }

                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Reorder Habits", systemImage: "arrow.up.arrow.down") {
                            isReorderHabitsViewPresented.toggle()
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Add Habit", systemImage: "plus") {
                            isAddHabitViewPresented.toggle()
                        }
                    }
                }
                .navigationTitle("HabitPanda 🐼")
                .navigationBarTitleDisplayMode(.inline)
                .fullScreenCover(isPresented: $isAddHabitViewPresented) {
                    HabitAddEditView()
                }
                .fullScreenCover(isPresented: $isReorderHabitsViewPresented) {
                    HabitReorderView()
                }
        }
    }
}

#Preview {
    NavigationStack {
        HabitListView()
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
