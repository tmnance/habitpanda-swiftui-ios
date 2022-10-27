//
//  HabitListView.swift
//  HabitPandaSwiftUI
//
//  Created by Tim Nance on 10/7/22.
//

import SwiftUI

struct HabitListView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @State private var isAddHabitViewPresented = false
    @State private var isReorderHabitsViewPresented = false

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Habit.order, ascending: true)],
        animation: .none)
    private var habits: FetchedResults<Habit>

    var body: some View {
        VStack {
            if habits.isEmpty {
                Text("🥺")
                Text("No habits found").font(.title2)
                Text("Tap the + button above to create your first habit!").font(.footnote)
                Spacer()
            } else {
                List {
                    ForEach(habits) { habit in
                        NavigationLink((habit.name ?? "") + " (🎯\(habit.frequencyPerWeek)x/wk)", value: habit)
                    }
                    .onDelete(perform: delete(offsets:))
                }
                .navigationDestination(for: Habit.self) { habit in
                    HabitDetailsView(habit: habit)
                }
                .listStyle(.plain)
                Spacer()
            }
        }
        .toolbar {
            #if DEBUG
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                }) {
                    NavigationLink(destination: AdminView()) {
                        Text("Admin")
                    }
                }
            }
            #endif

            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    isReorderHabitsViewPresented.toggle()
                }) {
                    Label("Reorder Habits", systemImage: "arrow.up.arrow.down")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    isAddHabitViewPresented.toggle()
                }) {
                    Label("Add Habit", systemImage: "plus")
                }
            }
        }
        .navigationTitle("HabitPanda 🐼")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $isAddHabitViewPresented) {
            AddEditHabitView()
        }
        .fullScreenCover(isPresented: $isReorderHabitsViewPresented) {
            ReorderHabitsView()
        }
    }

    private func delete(offsets: IndexSet) {
        withAnimation {
            offsets.forEach { offset in
                let habit = habits[offset]
                viewContext.delete(habit)
            }
            do {
                try viewContext.save()
            } catch {
                print("Error saving context, \(error)")
            }
            Habit.fixHabitOrder(context: viewContext)
        }
    }
}

struct HabitListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            HabitListView()
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        }
    }
}
