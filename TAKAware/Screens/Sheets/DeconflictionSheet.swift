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
    @Binding var viewModel: MapViewModel
    @StateObject var settingsStore: SettingsStore = SettingsStore.global
    
    func iconImage(_ annotation: MapPointAnnotation) -> UIImage {
        let icon = IconData.iconFor(type2525: annotation.cotType ?? "", iconsetPath: annotation.icon ?? "")
        return icon.icon
    }

    var body: some View {
        NavigationView {
            List {
                if(viewModel.conflictedItems.isEmpty) {
                    Text("No Markers Selected")
                } else {
                    ForEach(viewModel.conflictedItems, id:\.title) { marker in
                        VStack {
                            HStack {
                                Image(uiImage: iconImage(marker))
                                Button {
                                    viewModel.didSelectAnnotation(marker)
                                } label: {
                                    Text(marker.title!)
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
