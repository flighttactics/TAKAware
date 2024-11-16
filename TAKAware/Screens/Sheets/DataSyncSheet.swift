//
//  DataSyncSheet.swift
//  TAKAware
//
//  Created by Cory Foy on 11/9/24.
//

import Foundation
import SwiftTAK
import SwiftUI

struct DataSyncSheet: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var settingsStore: SettingsStore = SettingsStore.global
    @StateObject var dataSyncManager: DataSyncManager = DataSyncManager()
    @State private var isRotating = 0.0
    @State var dataPackageState = true

    var body: some View {
        NavigationView {
            List {
                Text("Data Sync Missions")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.secondary)
                if(dataSyncManager.isLoading) {
                    HStack {
                        Text("Retrieving available missions")
                        Image(systemName: "arrowshape.turn.up.right.circle")
                        .rotationEffect(.degrees(isRotating))
                        .onAppear {
                            withAnimation(.linear(duration: 1)
                                    .speed(0.3).repeatForever(autoreverses: false)) {
                                isRotating = 360.0
                            }
                        }
                    }
                } else if(dataSyncManager.dataPackages.isEmpty) {
                    Text("No Data Sync Missions Available for \(settingsStore.takServerUrl)")
                } else {
                    ForEach(dataSyncManager.dataPackages, id:\.name) { dataPackage in
                        VStack {
                            HStack {
                                Text(dataPackage.name)
                                    .bold()
                                Spacer()
                                Text("Size")
                                    .font(.system(size: 12))
                            }
                            HStack {
                                Text(dataPackage.creatorUid)
                                Spacer()
                                Text(dataPackage.createTime)
                            }
                            .font(.system(size: 12))
                        }
                        .padding(.top, 20)
                    }
                }
            }
            .onAppear {
                dataSyncManager.retrieveMissions()
            }
            .navigationBarItems(trailing: Button("Close", action: {
                dismiss()
            }))
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
