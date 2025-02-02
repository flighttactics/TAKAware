//
//  ChannelSheet.swift
//  TAKAware
//
//  Created by Cory Foy on 11/9/24.
//

import Foundation
import SwiftTAK
import SwiftUI

struct ChannelOptions: View {
    var body: some View {
        NavigationLink(destination: ChannelOptionsDetail()) {
            Text("Channel Options")
        }
    }
}

struct ChannelOptionsDetail: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var settingsStore: SettingsStore = SettingsStore.global
    @StateObject var channelManager: ChannelManager = ChannelManager()
    @State var channelState = true
    
    var body: some View {
        List {
            if(settingsStore.takServerUrl.isEmpty) {
                Text("Not connected to a server")
            } else if(channelManager.isLoading) {
                HStack {
                    Text("Retrieving Channels")
                    ProgressView()
                }
            } else if(channelManager.activeChannels.isEmpty) {
                Text("No Channels Available for \(settingsStore.takServerUrl)")
            } else {
                ForEach(channelManager.activeChannels, id:\.name) { channel in
                    VStack {
                        HStack {
                            Button {
                                channelManager.toggleChannel(channel: channel)
                            } label: {
                                if(channelManager.isSendingUpdate) {
                                    ProgressView()
                                        .padding(.trailing, 5)
                                } else if(channel.active) {
                                    Image(systemName: "eye.fill")
                                } else {
                                    Image(systemName: "eye.slash")
                                }
                                
                            }
                            Text(channel.name)
                        }
                    }
                    .padding(.top, 20)
                }
            }
        }
        .onAppear {
            channelManager.retrieveChannels()
        }
        .navigationTitle("Channel Options")
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

struct ChannelSheet: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var settingsStore: SettingsStore = SettingsStore.global
    @StateObject var channelManager: ChannelManager = ChannelManager()
    @State var channelState = true

    var body: some View {
        NavigationView {
            List {
                if(settingsStore.takServerUrl.isEmpty) {
                    Text("Not connected to a server")
                } else if(channelManager.isLoading) {
                    HStack {
                        Text("Retrieving Channels")
                        ProgressView()
                    }
                } else if(channelManager.activeChannels.isEmpty) {
                    Text("No Channels Available for \(settingsStore.takServerUrl)")
                } else {
                    ForEach(channelManager.activeChannels, id:\.name) { channel in
                        VStack {
                            HStack {
                                Button {
                                    channelManager.toggleChannel(channel: channel)
                                } label: {
                                    if(channelManager.isSendingUpdate) {
                                        ProgressView()
                                            .padding(.trailing, 5)
                                    } else if(channel.active) {
                                        Image(systemName: "eye.fill")
                                    } else {
                                        Image(systemName: "eye.slash")
                                    }
                                    
                                }
                                Text(channel.name)
                            }
                        }
                        .padding(.top, 20)
                    }
                }
            }
            .onAppear {
                channelManager.retrieveChannels()
            }
            .navigationBarItems(trailing: Button("Close", action: {
                dismiss()
            }))
            .navigationTitle("Channel List")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
