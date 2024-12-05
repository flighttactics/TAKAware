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
    @Binding var viewModel: MapViewModel
    @State var currentPlayer: VLCMediaPlayer = VLCMediaPlayer()
    
    var annotation: MapPointAnnotation? {
        viewModel.currentSelectedAnnotation
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                if annotation == nil || annotation!.videoURL == nil {
                    Text("No Video Source Selected")
                } else {
                    PlayerView(url: annotation!.videoURL!.absoluteString)
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
