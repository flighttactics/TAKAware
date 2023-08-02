//
//  TAK_SpikeApp.swift
//  TAK Spike
//
//  Created by Cory Foy on 7/3/23.
//

import SwiftUI

@main
struct TAKTrackerApp: App {
    @Environment(\.scenePhase) var scenePhase

    var body: some Scene {
        WindowGroup {
            MainScreen(manager: LocationManager())
                .onAppear {
                    UIApplication.shared.isIdleTimerDisabled = SettingsStore.global.disableScreenSleep
                    SettingsStore.global.isConnectedToServer = false
                    SettingsStore.global.shouldTryReconnect = true
                }
                .onChange(of: scenePhase) { newPhase in
                                if newPhase == .inactive {
                                    TAKLogger.debug("[ScenePhase] Moving to inactive")
                                    SettingsStore.global.shouldTryReconnect = true
                                } else if newPhase == .active {
                                    TAKLogger.debug("[ScenePhase] Moving to active")
                                    SettingsStore.global.shouldTryReconnect = true
                                } else if newPhase == .background {
                                    TAKLogger.debug("[ScenePhase] Moving to background")
                                    SettingsStore.global.shouldTryReconnect = true
                                }
                            }
        }
    }
}