//
//  TimeWindowShortDisplayView.swift
//  HabitPandaSwiftUI
//
//  Created by Tim Nance on 8/6/25.
//

import SwiftUI

struct TimeWindowShortDisplayView: View {
    let timeWindows: Set<TimeWindow>?

    var body: some View {
        Group {
            if let timeWindows, !timeWindows.isEmpty {
                Text(timeWindows.sorted { $0.order < $1.order }.map { $0.displayEmoji }.joined(separator: ""))
                    .padding(.vertical, 4)
                    .font(.system(size: 16))
                    .minimumScaleFactor(0.2)
                    .allowsTightening(true).lineLimit(1)
            }
            else {
                Text("All Day")
                    .font(.system(size: 14))
                    .minimumScaleFactor(0.2)
                    .allowsTightening(true).lineLimit(1)
                    .foregroundColor(Color(Constants.Colors.labelText))
                    .padding(3)
                    .background(Color(Constants.Colors.tint2))
                    .cornerRadius(4)
            }
        }
    }
}

#Preview {
    let viewContext = PersistenceController.preview.container.viewContext
    let timeWindows = TimeWindow.getAll(context: viewContext)

    VStack(spacing: 20) {
        ForEach(0..<timeWindows.count, id: \.self) { i in
            TimeWindowShortDisplayView(
                timeWindows: NSSet(array: Array(timeWindows[..<i])) as? Set<TimeWindow>
            )
        }
    }
    .environment(\.managedObjectContext, viewContext)
}
