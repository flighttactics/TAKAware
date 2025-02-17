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
    let parentView: AwarenessView
    @StateObject var settingsStore: SettingsStore = SettingsStore.global

    var body: some View {
        NavigationView {
            List {
                if(conflictedItems.isEmpty) {
                    Text("No Markers Selected")
                } else {
                    ForEach(conflictedItems, id:\.title) { item in
                        VStack {
                            HStack {
                                IconImage(annotation: item)
                                Button {
                                    parentView.didSelectAnnotation(item)
                                } label: {
                                    Text(item.title!)
                                }
                            }
                        }
                        .padding(.top, 20)
                    }
                }
            }
            .navigationBarItems(trailing: Button("Close", action: {
                dismiss()
            }))
            .navigationTitle("Select Item")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
