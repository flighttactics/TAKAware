//
//  SettingsSheet.swift
//  TAKAware
//
//  Created by Cory Foy on 11/9/24.
//

import Foundation
import MapKit
import SwiftTAK
import SwiftUI

struct SettingsSheet: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var settingsStore: SettingsStore = SettingsStore.global
    let defaultBackgroundColor = Color(UIColor.systemBackground)
    @State var isProcessingDataPackage: Bool = false

    var body: some View {
        NavigationView {
            List {
                Section(header:
                            Text("User Information")
                    .font(.system(size: 14, weight: .medium))
                ) {
                    UserInformation()
                }
                Section(header:
                            Text("Server Information")
                    .font(.system(size: 14, weight: .medium)), footer: Text("Swipe server to manage")
                ) {
                    ConnectionOptions(isProcessingDataPackage: $isProcessingDataPackage)
                }
                Section {
                    SituationalAwarenessOptions()
                    AdvancedOptions()
                    ChannelOptions()
                    DataPackageOptions()
                    KMLOptions()
                    DataSyncMissionOptions()
                    AboutInformation()
                }
            }
            .navigationBarItems(trailing: Button("Close", action: {
                dismiss()
            }))
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
