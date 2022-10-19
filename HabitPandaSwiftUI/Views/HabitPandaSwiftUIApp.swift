//
//  HabitPandaSwiftUIApp.swift
//  HabitPandaSwiftUI
//
//  Created by Tim Nance on 10/7/22.
//

import SwiftUI

@main
struct HabitPandaSwiftUIApp: App {
    @StateObject var router = Router()
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $router.path) {
                HabitListView()
            }
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
            .environmentObject(router)
//            .task { // task to open the first habit details view on app load
//                if let firstHabit = Habit.getAll().first {
//                    router.reset()
//                    router.path.append(firstHabit)
//                }
//            }
        }
    }
}
