//
//  HabitRemindersTabView.swift
//  HabitPandaSwiftUI
//
//  Created by Tim Nance on 10/11/22.
//

import SwiftUI

struct HabitRemindersTabView: View {
    var body: some View {
        VStack {
            Text("Reminders tab!")
            Color(red: .random(in: 0...1), green: .random(in: 0...1), blue: .random(in: 0...1))
                .frame(width: 50, height: 50)
        }
    }
}

struct HabitRemindersTabView_Previews: PreviewProvider {
    static var previews: some View {
        HabitRemindersTabView()
    }
}
