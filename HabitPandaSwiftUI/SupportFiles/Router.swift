//
//  Router.swift
//  HabitPandaSwiftUI
//
//  Created by Tim Nance on 10/18/22.
//

import Foundation
import SwiftUI

class Router: ObservableObject {
    @Published var path = NavigationPath()

    func reset() {
        path = NavigationPath()
    }
}
