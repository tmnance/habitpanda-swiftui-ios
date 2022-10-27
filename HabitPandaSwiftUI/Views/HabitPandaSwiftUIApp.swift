//
//  HabitPandaSwiftUIApp.swift
//  HabitPandaSwiftUI
//
//  Created by Tim Nance on 10/7/22.
//

import SwiftUI

@main
struct HabitPandaSwiftUIApp: App {
    @StateObject var router = Router.shared
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

//    init() {
//        NotificationHelper.requestAuthorization()
//    }

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $router.path) {
                HabitListView()
            }
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
            .environmentObject(router)
            .onAppear {
                NotificationHelper.requestAuthorization()
            }
//            .task { // task to open the first habit details view on app load (used for testing)
//                if let firstHabit = Habit.getAll(
//                    sortedBy: [("order", .asc)],
//                    context: PersistenceController.shared.container.viewContext
//                ).first {
//                    router.reset()
//                    router.path.append(firstHabit)
//                }
//            }
            // TODO: look into other ways to do notifications without AppDelegate, e.g. below
//            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("testIdentifier"))) { data in
//                print("onReceive")
//               // Change key as per your "UserLogs"
//                guard let userInfo = data.userInfo, let info = userInfo["UserInfo"] else {
//                    return
//                }
//                print("info")
//                print(info)
//            }

        }
    }
}
