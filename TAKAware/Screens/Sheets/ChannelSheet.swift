//
//  ChannelSheet.swift
//  TAKAware
//
//  Created by Cory Foy on 11/9/24.
//

import Foundation
import SwiftTAK
import SwiftUI

struct ChannelSheet: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var settingsStore: SettingsStore = SettingsStore.global
    @StateObject var channelManager: ChannelManager = ChannelManager()
    @State private var isRotating = 0.0
    @State var channelState = true
    
    var loader: some View {
        return Image(systemName: "arrowshape.turn.up.right.circle")
            .rotationEffect(.degrees(isRotating))
            .onAppear {
                withAnimation(.linear(duration: 1)
                        .speed(0.1).repeatForever(autoreverses: false)) {
                    isRotating = 360.0
                }
            }
    }

    var body: some View {
        NavigationView {
            List {
                if(settingsStore.takServerUrl.isEmpty) {
                    Text("Not connected to a server")
                } else if(channelManager.isLoading) {
                    HStack {
                        Text("Retrieving Channels")
                        loader
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
                                        loader
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
