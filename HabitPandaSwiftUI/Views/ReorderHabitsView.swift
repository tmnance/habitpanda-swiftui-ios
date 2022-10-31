//
//  ReorderHabitsView.swift
//  HabitPandaSwiftUI
//
//  Created by Tim Nance on 10/7/22.
//

import SwiftUI

struct ReorderHabitsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    @State var habits: [Habit] = []
    @State var isHovering: Bool = false

    var body: some View {
        NavigationView {
            VStack {
                if habits.isEmpty {
                    Text("No habits").font(.title2)
                    Spacer()
                } else {
                    List {
                        ForEach(habits) { habit in
                            HStack {
                                Text(habit.name ?? "")
                                Spacer()
                                Image(systemName: "line.horizontal.3")
                            }
                        }
                        .onMove { indices, newOffset in
                            habits.move(
                                fromOffsets: indices,
                                toOffset: newOffset
                            )
                        }
                    }
                    .listStyle(.plain)
                    Spacer()
                }
            }
            .onAppear {
                habits = Habit.getAll(
                    sortedBy: [("order", .asc)],
                    context: viewContext
                )
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .frame(minWidth: Constants.minTappableDimension)
                    .frame(height: Constants.minTappableDimension)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        updateHabitOrder()
                        dismiss()
                    }
                    .frame(minWidth: Constants.minTappableDimension)
                    .frame(height: Constants.minTappableDimension)
                }
            }
            .navigationTitle("Reorder Habits")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    func updateHabitOrder() {
        guard habits.count > 0 else {
            return
        }

        var order = 0

        habits.forEach { habit in
            let habitToSave = habit
            habitToSave.order = Int32(order)
            order += 1
        }

        do {
            try PersistenceController.shared.save()
        } catch {
            print("Error saving context, \(error)")
        }
    }
}

struct ReorderHabitsView_Previews: PreviewProvider {
    static var previews: some View {
        ReorderHabitsView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
