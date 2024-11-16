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
    @Binding var currentSelectedAnnotation: MapPointAnnotation?
    @StateObject var settingsStore: SettingsStore = SettingsStore.global

    var body: some View {
        NavigationView {
            List {
                ForEach(conflictedItems, id:\.title) { marker in
                    VStack {
                        HStack {
                            Button {
                                TAKLogger.debug("Setting selected to \(marker.title!)")
                                currentSelectedAnnotation = marker
                            } label: {
                                Text(marker.title!)
                            }
                            
                        }
                    }
                    .padding(.top, 20)
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
