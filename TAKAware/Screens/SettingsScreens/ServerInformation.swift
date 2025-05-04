//
//  ServerInformation.swift
//  TAKTracker
//
//  Created by Cory Foy on 9/22/23.
//

import Foundation
import SwiftUI

struct ServerInformation: View {
    @StateObject var settingsStore: SettingsStore = SettingsStore.global
    
    var body: some View {
        Group {
            VStack {
                HStack {
                    Text("Host Name")
                        .foregroundColor(.secondary)
                    TextField("Host Name", text: $settingsStore.takServerUrl)
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .onSubmit {
                            SettingsStore.global.takServerChanged = true
                        }
                }
            }
            
            VStack {
                HStack {
                    Text("Port")
                        .foregroundColor(.secondary)
                    TextField("Server Port", text: $settingsStore.takServerPort)
                        .keyboardType(.numberPad)
                        .onSubmit {
                            SettingsStore.global.takServerChanged = true
                        }
                }
            }
        }
        .multilineTextAlignment(.trailing)
    }
}

struct ServerInformationDisplay: View {
    @StateObject var settingsStore: SettingsStore = SettingsStore.global
    @State var isShowingAlert = false
    @State var isShowingEditBox = false
    @State var currentServerUrl: String = SettingsStore.global.takServerUrl
    @State var currentServerPort: String = SettingsStore.global.takServerPort
    
    var body: some View {
        Group {
            VStack {
                HStack {
                    Text("Host Name")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(settingsStore.takServerUrl)
                }
            }
            .swipeActions(allowsFullSwipe: false) {
                Button(role: .destructive) {
                    SettingsStore.global.clearConnection()
                    isShowingAlert = true
                } label: {
                    Image(systemName: "trash")
                }
                Button {
                    isShowingEditBox = true
                } label: {
                    Image(systemName: "pencil")
                }
            }
        }
        .multilineTextAlignment(.trailing)
        .alert(isPresented: $isShowingAlert) {
            Alert(title: Text("Server Connection"), message: Text("The TAK Server Connection has been removed"), dismissButton: .default(Text("OK")))
        }
        .alert("Update Server Info", isPresented: $isShowingEditBox, actions: {
            TextField("Host", text: $currentServerUrl)
                .foregroundColor(.black)
                .background(.white)
            TextField("Port", text: $currentServerPort)
                .foregroundColor(.black)
                .background(.white)
            Button("Update", action: { updateServer() })
            Button("Cancel", role: .cancel, action: {
                currentServerUrl = settingsStore.takServerUrl
                currentServerPort = settingsStore.takServerPort
                isShowingEditBox = false
            })
        }, message: {
            Text("Update Server Connection")
        })
    }
    
    func updateServer() {
        var didUpdate = false
        if !currentServerUrl.isEmpty {
            didUpdate = true
            settingsStore.takServerUrl = currentServerUrl
        }
        if !currentServerPort.isEmpty {
            didUpdate = true
            settingsStore.takServerPort = currentServerPort
        }
        settingsStore.takServerChanged = didUpdate
    }
}
