//
//  DataPackages.swift
//  TAKAware
//
//  Created by Cory Foy on 7/26/24.
//

import Foundation
import SwiftUI
import CoreData

struct DataSyncSubscribedMissionDetail: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var dataContext
    @StateObject var dataSyncManager: DataSyncManager = DataSyncManager()
    @State private var storedMissionItems: [DataSyncMissionItem] = []
    @State private var storedMission: DataSyncMission? = nil
    @State private var presentAlert = false
    @State private var password: String = ""

    let mission: DataSyncDataPackage

    var retrievedMission: DataSyncDataPackage? {
        dataSyncManager.dataPackages.first
    }
    
    func loadMission() {
        dataSyncManager.retrieveMission(missionName: mission.name, password: password)
        
        dataContext.perform {
            let fetchMission: NSFetchRequest<DataSyncMission> = DataSyncMission.fetchRequest()
            fetchMission.predicate = NSPredicate(format: "name = %@", mission.name)
            let missionResults = try? dataContext.fetch(fetchMission)
            if missionResults?.count != 0 {
                storedMission = missionResults!.first
                
                let fetchMissionItems: NSFetchRequest<DataSyncMissionItem> = DataSyncMissionItem.fetchRequest()
                fetchMissionItems.predicate = NSPredicate(format: "missionUUID = %@", storedMission!.id! as CVarArg)
                let results = try? dataContext.fetch(fetchMissionItems)
                if results != nil {
                    storedMissionItems = results!
                }
            }
        }
    }
    
    func unsubscribeFromMission() {
        dataSyncManager.unsubscribeFromMission(missionName: retrievedMission!.name)
        dataSyncManager.retrieveMission(missionName: mission.name)
    }
    
    var missionCotCount: Int {
        if retrievedMission?.dbUid == nil {
            retrievedMission!.uids.count
        } else {
            storedMissionItems.count(where: { $0.isCOT })
        }
    }
    
    var missionAttachmentCount: Int {
        if retrievedMission?.dbUid == nil {
            retrievedMission!.contents.count
        } else {
            storedMissionItems.count(where: { !$0.isCOT })
        }
    }

    var body: some View {
        List {
            if(dataSyncManager.isLoadingMission || dataSyncManager.isUnsubscribingFromMission) {
                HStack {
                    Text("Retrieving mission details")
                    ProgressView()
                }
            } else {
                if (dataSyncManager.dataPackages.isEmpty) {
                    Text("No Mission Details Found")
                } else {
                    Text("Name: \(retrievedMission!.name)")
                    Text("Creator: \(retrievedMission!.creatorUid)")
                    Text("Number UIDs: \(missionCotCount)")
                    Text("Number Attachments: \(missionAttachmentCount)")
                    HStack {
                        Spacer()
                        Group {
                            Button(action: { dataSyncManager.downloadMission(mission: retrievedMission!) }) {
                                HStack {
                                    if retrievedMission?.dbUid != nil {
                                        Text("Force Sync")
                                    } else {
                                        Text("Manually Download")
                                    }
                                    
                                    if(dataSyncManager.isDownloadingMission) {
                                        ProgressView()
                                    } else {
                                        Image(systemName: "square.and.arrow.down")
                                    }
                                }
                            }

                            if retrievedMission?.dbUid != nil {
                                Button(role: .destructive, action: { unsubscribeFromMission() }) {
                                    HStack {
                                        Text("Unsubscribe")
                                        if(dataSyncManager.isSubscribingToMission) {
                                            ProgressView()
                                        } else {
                                            Image(systemName: "trash.fill")
                                        }
                                    }
                                }
                            } else {
                                Button(action: { dataSyncManager.subscribeToMission(missionName: retrievedMission!.name, password: password) }) {
                                    HStack {
                                        Text("Download and Subscribe")
                                        if(dataSyncManager.isSubscribingToMission) {
                                            ProgressView()
                                        } else {
                                            Image(systemName: "arrow.triangle.2.circlepath.circle")
                                        }
                                    }
                                }
                            }
                            
                        }
                        .buttonStyle(BorderedProminentButtonStyle())
                    }
                }
            }
        }
        .navigationTitle(mission.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if mission.passwordProtected {
                presentAlert = true
            } else {
                loadMission()
            }
        }
        .alert("Login", isPresented: $presentAlert, actions: {
            SecureField("Password", text: $password)
                .foregroundColor(.black)
            Button("Login", action: { loadMission() })
            Button("Cancel", role: .cancel, action: { dismiss() })
        }, message: {
            Text("Please enter the mission password")
        })
        .alert("Mission Sync Completed", isPresented: $dataSyncManager.missionDownloadCompleted) {
            Button("OK", role: .cancel) { }
        }
    }
}

struct DataSyncMissionDetail: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var settingsStore: SettingsStore = SettingsStore.global
    @StateObject var dataSyncManager: DataSyncManager = DataSyncManager()
    @State var dataPackageState = true
    
    var body: some View {
        List {
            if(dataSyncManager.isLoadingMissionList) {
                HStack {
                    Text("Retrieving available missions")
                    ProgressView()
                }
            } else if(dataSyncManager.dataPackages.isEmpty) {
                Text("No Data Sync Missions Available for \(settingsStore.takServerUrl)")
            } else {
                ForEach(dataSyncManager.dataPackages, id:\.name) { dataPackage in
                    NavigationLink {
                        DataSyncSubscribedMissionDetail(mission: dataPackage)
                    } label: {
                        HStack {
                            if dataPackage.dbUid != nil {
                                Image(systemName: "checkmark.icloud")
                            } else if dataPackage.passwordProtected {
                                Image(systemName: "lock.icloud")
                            } else {
                                Image(systemName: "icloud")
                            }
                            
                            VStack(alignment: .leading) {
                                Text(dataPackage.name)
                                    .fontWeight(.bold)
                                Text("\(dataPackage.creatorUid)")
                                    .font(.system(size: 8))
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            dataSyncManager.retrieveMissions()
        }
        .navigationTitle("Data Sync")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Dismiss") {
                    dismiss()
                }
            }
        }
    }
}

struct DataSyncMissionOptions: View {
    var body: some View {
        NavigationLink(destination: DataSyncMissionDetail()) {
            Text("Data Sync")
        }
    }
}
