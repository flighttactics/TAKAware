//
//  VideoPlayerView.swift
//  TAKAware
//
//  Created by Cory Foy on 8/3/24.
//

import AVKit
import Foundation
import SwiftUI
import MobileVLCKit

struct VideoView: UIViewRepresentable {
    @Binding var currentSelectedAnnotation: MapPointAnnotation?
    @State var mediaPlayer = VLCMediaPlayer()

    typealias UIViewType = UIView

    func makeUIView(context: Context) -> UIView {
        let uiView = UIView()
        mediaPlayer.drawable = uiView
        return uiView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let url = currentSelectedAnnotation?.videoURL {
            TAKLogger.debug("[VideoView] Attempting to play \(url)")
            mediaPlayer.media = VLCMedia(url: url)
            mediaPlayer.play()
        }
        else {
            mediaPlayer.stop()
        }
    }
}

struct PlayerView: UIViewRepresentable {
    public var url: String
    let mediaPlayer = VLCMediaPlayer()
    func makeUIView(context: Context) -> UIView {
        TAKLogger.debug("[PlayerView] Attempting to play \(url)")
        let controller = UIView()
        mediaPlayer.drawable = controller
        let uri = URL(string: self.url)
        let media = VLCMedia(url: uri!)
        mediaPlayer.media = media
        mediaPlayer.play()
        return controller
    }

    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<PlayerView>) {
    }
}

struct VideoPlayerView: View {
    @Environment(\.dismiss) var dismiss
    @State var currentPlayer: VLCMediaPlayer = VLCMediaPlayer()
    @Binding var currentSelectedAnnotation: MapPointAnnotation?
    
    var annotation: MapPointAnnotation? {
        currentSelectedAnnotation
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                if annotation == nil || annotation!.videoURL == nil {
                    Text("No Video Source Selected")
                } else {
                    VideoView(currentSelectedAnnotation: $currentSelectedAnnotation)
                        .cornerRadius(10)
                }
            }
            .navigationBarItems(trailing: Button("Close", action: {
                dismiss()
            }))
            .navigationTitle(annotation?.title ?? "Video Player")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
