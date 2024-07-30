//
//  ChannelOptions.swift
//  TAKTracker
//
//  Created by Cory Foy on 7/10/24.
//

import Foundation
import MapKit
import SwiftUI

struct ChannelOptionsDetail: View {
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
        List {
            if(channelManager.isLoading) {
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

struct ChannelOptions: View {
    var body: some View {
        NavigationLink(destination: ChannelOptionsDetail()) {
            Text("Channel Options")
        }
    }
}
