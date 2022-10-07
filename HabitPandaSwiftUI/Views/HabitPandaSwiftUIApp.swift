//
//  HabitPandaSwiftUIApp.swift
//  HabitPandaSwiftUI
//
//  Created by Tim Nance on 10/7/22.
//

import SwiftUI

@main
struct HabitPandaSwiftUIApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                HabitListView()
            }
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
