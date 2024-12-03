//
//  AdvancedOptions.swift
//  TAKTracker
//
//  Created by Cory Foy on 3/25/24.
//

import Foundation
import SwiftUI

struct AdvancedOptions: View {
    var body: some View {
        NavigationLink(destination: AdvancedOptionsScreen()) {
            Text("Advanced Options")
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AdvancedOptionsScreen: View {
    var body: some View {
        List {
            DeviceOptions()
            TAKOptions()
            Section(header: Text("Destructive Options")) {
                Button(role: .destructive) {
                    DataController.shared.clearAllMarkers()
                } label: {
                    Text("Clear All Markers")
                }
            }
        }
        .navigationTitle("Advanced Options")
    }
}
