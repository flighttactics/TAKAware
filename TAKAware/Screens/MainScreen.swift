//
//  ContentView.swift
//  TAK Spike
//
//  Created by Cory Foy on 7/3/23.
//

import SwiftUI
import MapKit

let navBarAppearance = UINavigationBarAppearance()

// A View wrapper to make the modifier easier to use
extension View {
    func onRotate(perform action: @escaping (UIDeviceOrientation) -> Void) -> some View {
        self.modifier(DeviceRotationViewModifier(action: action))
    }
}

struct MainScreen: View {
    @EnvironmentObject var takManager: TAKManager
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var settingsStore: SettingsStore
    
    @StateObject var dataSyncManager: DataSyncManager = DataSyncManager(shouldListenForUpdates: true)
    @State private var displayUIState = DisplayUIState()
    @State private var migrator = Migrator()
    @State var isShowingAlert = false
    
    var body: some View {
        Group {
            AwarenessView(displayUIState: $displayUIState)
        }
        .onAppear {
            if(AppConstants.getAppReleaseVersion() != SettingsStore.global.lastAppVersionRun) {
                TAKLogger.debug("[MainScreen]: App Requires Migration, attempting to migrate")
                migrator.migrate(from: settingsStore.lastAppVersionRun)
                settingsStore.lastAppVersionRun = AppConstants.getAppReleaseVersion()
                isShowingAlert = !migrator.migrationSucceeded
            }
            broadcastLocation()
            Timer.scheduledTimer(withTimeInterval: settingsStore.broadcastIntervalSeconds, repeats: true) { timer in
                broadcastLocation()
            }
        }
        .onRotate { newOrientation in
            locationManager.deviceUpdatedOrientation(orientation: newOrientation)
        }
        .alert(isPresented: $isShowingAlert) {
            Alert(
                title: Text("App Migration"),
                message: Text("This version of TAK Aware requires the use of server certificates. We attempted to migrate your existing connection but were unable to. Please reconnect or upload your data package again to connect to your TAK server"),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    func broadcastLocation() {
        takManager.broadcastLocation(locationManager: locationManager)
    }
}
