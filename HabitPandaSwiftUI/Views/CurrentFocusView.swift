//
//  CurrentFocusView.swift
//  HabitPandaSwiftUI
//
//  Created by Tim Nance on 2/11/25.
//

import SwiftUI

struct CurrentFocusView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @StateObject var router = Router.shared

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \TimeWindow.order, ascending: true)],
        animation: .none)
    private var timeWindows: FetchedResults<TimeWindow>

    var body: some View {
        NavigationStack(path: $router.path) {
            VStack {
                if timeWindows.isEmpty {
                    Text("🥺")
                    Text("No time windows found").font(.title2)
                    Spacer()
                } else {
                    ForEach(timeWindows, id: \.self) { timeWindow in
                        Text("\(timeWindow.displayEmoji) \(timeWindow.displayName) (\(timeWindow.order))")
                    }
                }
            }
            .navigationTitle("Current Focus")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct CurrentFocusView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            CurrentFocusView()
        }
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
