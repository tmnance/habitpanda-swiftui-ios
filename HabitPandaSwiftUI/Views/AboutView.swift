//
//  AboutView.swift
//  HabitPandaSwiftUI
//
//  Created by Tim Nance on 11/5/22.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        ZStack {
            List {
                Section(header: Spacer(minLength: 0)) {
                    aboutRow {
                        Link("Website", destination: URL(string: "https://habitpanda.app")!)
                    }
                    aboutRow {
                        Link("Privacy Policy", destination: URL(string: "https://habitpanda.app/privacy")!)
                    }
                    aboutRow {
                        Link("Contact Us", destination: URL(string: "https://habitpanda.app")!)
                    }
                }
                #if DEBUG
                Section() {
                    ZStack {
                        NavigationLink("Admin") {
                            AdminView()
                        }
                        .opacity(0)
                        aboutRow {
                            Text("Admin")
                        }
                    }
                }
                #endif
            }
            .listStyle(.insetGrouped)
            .foregroundColor(Color(Constants.Colors.label))
//            .scrollContentBackground(.hidden)
            Text(getVersionText())
                .font(.system(size: 17.0))
                .foregroundColor(Color(Constants.Colors.subText))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(20)
        }
//        .background(Color(UIColor.secondarySystemBackground))
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder func aboutRow<V: View>(content: () -> V) -> some View {
        HStack {
            content()
            Spacer()
            Image(systemName: "chevron.forward")
                .font(.system(size: 14.0, weight: .bold))
                .opacity(0.25)
        }
    }

    func getVersionText() -> String {
        let dictionary = Bundle.main.infoDictionary!
        let version = dictionary["CFBundleShortVersionString"] as! String

        return "v\(version)"
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AboutView()
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        }
    }
}
