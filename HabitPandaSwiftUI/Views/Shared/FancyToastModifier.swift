//
//  FancyToastModifier.swift
//  HabitPandaSwiftUI
//
//  Created by Tim Nance on 11/10/22.
//  (Modified from https://betterprogramming.pub/swiftui-create-a-fancy-toast-component-in-10-minutes-e6bae6021984)
//

import SwiftUI

struct FancyToast: Equatable {
    let id = UUID()
    var type: FancyToastStyle
    var title: String?
    var message: String
    var duration: Double = 3
    var tapToDismiss: Bool = false
    static func errorMessage(_ message: String) -> FancyToast {
        return FancyToast(
            type: .error,
            message: message,
            duration: 0
        )
    }
}

extension View {
    func toastView(toast: Binding<FancyToast?>) -> some View {
        self.modifier(FancyToastModifier(toast: toast))
    }
}

struct FancyToastModifier: ViewModifier {
    @Binding var toast: FancyToast?
    @State private var workItem: DispatchWorkItem?

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(
                ZStack {
                    mainToastView()
                        .offset(y: -30)
                }
                .animation(.spring(), value: toast)
            )
            .onChange(of: toast) {
                showToast()
            }
    }

    @ViewBuilder func mainToastView() -> some View {
        if let toast {
            VStack {
                Spacer()
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
            }
            .transition(.move(edge: .bottom))
            .id(toast.id.uuidString) // ensure a clean redraw for each new toast
        }
    }

    private func showToast() {
        guard let toast else { return }

        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        if toast.duration > 0 {
            workItem?.cancel()

            let task = DispatchWorkItem {
               dismissToast()
            }

            workItem = task
            DispatchQueue.main.asyncAfter(deadline: .now() + toast.duration, execute: task)
        }
    }

    private func dismissToast() {
        withAnimation {
            toast = nil
        }

        workItem?.cancel()
        workItem = nil
    }
}
