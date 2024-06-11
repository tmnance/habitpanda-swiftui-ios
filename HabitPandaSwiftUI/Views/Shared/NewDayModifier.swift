//
//  NewDayModifier.swift
//  HabitPandaSwiftUI
//
//  Created by Tim Nance on 11/15/22.
//

import SwiftUI

extension View {
    func onNewDay(perform action: (() -> Void)? = nil) -> some View {
        self.modifier(NewDayModifier(callback: action))
    }
}

struct NewDayModifier: ViewModifier {
    @Environment(\.scenePhase) private var scenePhase

    @State private var currentDate = Date().stripTime()
    let callback: (() -> Void)?

    func body(content: Content) -> some View {
        // TODO: add (optional?) ability to detect new day when view when user has view active during the day turnover
        content
            .onAppear {
                checkIfNewDay()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    checkIfNewDay()
                }
            }
    }

    private func checkIfNewDay() {
        // only trigger when different day
        if currentDate != Date().stripTime() {
            currentDate = Date().stripTime()
            callback?()
        }
    }
}
