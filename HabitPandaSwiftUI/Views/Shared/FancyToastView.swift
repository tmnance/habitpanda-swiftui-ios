//
//  FancyToastView.swift
//  HabitPandaSwiftUI
//
//  Created by Tim Nance on 11/10/22.
//  (Modified from https://betterprogramming.pub/swiftui-create-a-fancy-toast-component-in-10-minutes-e6bae6021984)
//

import SwiftUI

enum FancyToastStyle {
    case error, warning, success, info
    var themeColor: Color {
        switch self {
        case .error: return Constants.Colors.toastAccentError
        case .warning: return Constants.Colors.toastAccentWarning
        case .info: return Constants.Colors.toastAccentInfo
        case .success: return Constants.Colors.toastAccentSuccess
        }
    }
    var iconFileName: String {
        switch self {
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        }
    }
    var defaultTitle: String {
        switch self {
        case .error: return "Error"
        case .warning: return "Warning"
        case .success: return "Success"
        case .info: return "Info"
        }
    }
}

struct FancyToastView: View {
    var type: FancyToastStyle
    var title: String?
    var message: String
    var onCancelTapped: (() -> Void)?
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                Image(systemName: type.iconFileName)
                    .foregroundColor(type.themeColor)

                VStack(alignment: .leading) {
                    Text(title ?? type.defaultTitle)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Constants.Colors.toastText)
                    Text(message)
                        .font(.system(size: 12))
                        .foregroundColor(Constants.Colors.toastText.opacity(0.6))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if let onCancelTapped {
                    Spacer(minLength: 10)

                    Button {
                        onCancelTapped()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(Constants.Colors.toastText)
                    }
                }
            }
            .padding()
        }
        .background(Constants.Colors.toastBg)
        .overlay(
            Rectangle()
                .fill(type.themeColor)
                .frame(width: 6)
                .clipped()
            , alignment: .leading
        )
        .frame(minWidth: 0, maxWidth: .infinity)
        .cornerRadius(8)
        .shadow(color: Constants.Colors.toastShadow, radius: 4, x: 0, y: 1)
        .padding(.horizontal, 16)
    }
}

struct FancyToastView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ForEach([
                FancyToastStyle.error,
                FancyToastStyle.warning,
                FancyToastStyle.info,
                FancyToastStyle.success
            ], id: \.self) { type in
                FancyToastView(
                    type: type,
                    title: type.defaultTitle,
                    message: "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
                    onCancelTapped: (type == .error ? {} : nil)
                )
            }
        }
    }
}
