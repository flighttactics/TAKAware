//
//  DeconflictionSheet.swift
//  TAKAware
//
//  Created by Cory Foy on 11/11/24.
//

import Foundation
import SwiftTAK
import SwiftUI

struct DeconflictionSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var conflictedItems: [MapPointAnnotation]
    @StateObject var settingsStore: SettingsStore = SettingsStore.global
    @State private var selection = Set<MapPointAnnotation>()
    @State private var editMode = EditMode.inactive
    let parentView: AwarenessView
    
    private func deleteSelectedCots() {
        parentView.annotationsDeletedCallback(Array(selection))
        selection.removeAll()
        editMode = EditMode.inactive
    }

    var body: some View {
        NavigationView {
            Group {
                if conflictedItems.isEmpty {
                    Text("No items selected")
                } else {
                    List(conflictedItems, id:\.self, selection: $selection) { item in
                        HStack {
                            IconImage(annotation: item)
                            Button {
                                parentView.didSelectAnnotation(item)
                            } label: {
                                Text(item.title!)
                            }
                        }
                        .padding(.top, 20)
                    }
                }
                if !selection.isEmpty {
                    HStack {
                        Button { editMode = EditMode.inactive } label: {
                            Text("Cancel")
                        }
                        Spacer()
                        Button(role: .destructive) { deleteSelectedCots() } label: {
                            Text("Delete ^[\(selection.count) items](inflect: true)")
                        }
                        .buttonStyle(BorderedProminentButtonStyle())
                    }
                    .padding()
                }
            }
            .navigationBarItems(leading: EditButton(), trailing: Button("Close", action: {
                dismiss()
            }))
            .navigationTitle("Select Item")
            .navigationBarTitleDisplayMode(.inline)
            .environment(\.editMode, $editMode)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
