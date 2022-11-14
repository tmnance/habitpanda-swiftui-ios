//
//  HabitPandaSwiftUIApp.swift
//  HabitPandaSwiftUI
//
//  Created by Tim Nance on 10/7/22.
//

import SwiftUI

//import SwiftUI
//import Foundation

/// Global class that will manage toasts
class ToastPresenter: ObservableObject {
    // This static property probably isn't even needed as you can inject via @EnvironmentObject
    static let shared: ToastPresenter = ToastPresenter()

    private init() {}

    @Published var isPresented: Bool = false
    @State private var workItem: DispatchWorkItem?
    private(set) var toast: FancyToast?
//    private(set) var text: String?
//    private var timer: Timer?

    /// Call this function to present toasts
    func presentToast(toast: FancyToast) {
//        let _ = FancyToast.errorMessage(error.localizedDescription)
        // reset the toast if one is currently being presented.
        isPresented = false
//        self.text = nil
        self.toast = nil
//        timer?.invalidate()
        workItem?.cancel()

//        self.text = text
        self.toast = toast
        isPresented = true
//        timer = Timer(timeInterval: duration, repeats: false) { [weak self] _ in
//            self?.isPresented = false
//        }
        let task = DispatchWorkItem { [weak self] in
            withAnimation {
                self?.isPresented = false
            }

            self?.workItem?.cancel()
            self?.workItem = nil
        }

        workItem = task
        DispatchQueue.main.asyncAfter(deadline: .now() + toast.duration, execute: task)
    }
}


/// The UI for a toast
struct Toast: View {
    @State var toast: FancyToast

    var body: some View {
        FancyToastView(
            type: toast.type,
            title: toast.title,
            message: toast.message,
            onCancelTapped: (toast.duration == 0 ? { dismissToast() } : nil)
        )
            .onTapGesture {
                if toast.tapToDismiss {
                    dismissToast()
                }
            }
            .transition(.move(edge: .bottom))
            .animation(.spring(), value: toast)
//            .id(toast.id.uuidString) // ensure a clean redraw for each new toast
//        Text(text)
//            .padding()
//            .background(Capsule().fill(Color.gray))
//            .shadow(radius: 6)
//            .transition(AnyTransition.opacity.animation(.default))
    }

    private func dismissToast() {
//        withAnimation {
//            toast = nil
//        }

//        workItem?.cancel()
//        workItem = nil
    }
}

extension View {
    /// ViewModifier that will present a toast when its binding changes
    @ViewBuilder func toast(presented: Binding<Bool>, toast: FancyToast?) -> some View {
        ZStack {
            self

            if presented.wrappedValue, let toast {
                Toast(toast: toast)
                    .offset(y: -30)
            }
        }
        .ignoresSafeArea(.all, edges: .all)
    }
}

@main
struct HabitPandaSwiftUIApp: App {
    @StateObject var router = Router.shared
    @StateObject var toastPresenter = ToastPresenter.shared
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
            .toast(presented: $toastPresenter.isPresented, toast: toastPresenter.toast)
            // Inject the toast presenter into the view hierarchy
            .environmentObject(toastPresenter)
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
//                guard let userInfo = data.userInfo, let info = userInfo["UserInfo"] else { return }
//                print("info")
//                print(info)
//            }
        }
    }
}
