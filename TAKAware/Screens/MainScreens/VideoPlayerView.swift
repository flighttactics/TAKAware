//
//  VideoPlayerView.swift
//  TAKAware
//
//  Created by Cory Foy on 8/3/24.
//

import AVKit
import Foundation
import SwiftUI

struct VideoPlayerView: View {
    @Binding var annotation: MapPointAnnotation?
    @State var currentPlayer: AVPlayer = AVPlayer()

    var body: some View {
        VStack(alignment: .leading) {
            if annotation == nil || annotation!.videoURL == nil {
                Text("No Video Source Selected")
            } else {
                VideoPlayer(player: currentPlayer)
                    .cornerRadius(10)
                    .onAppear {
                        print(annotation!.videoURL!)
                        currentPlayer = AVPlayer(url: annotation!.videoURL!)
                        currentPlayer.play()
                    }
            }
        }
        .padding()
        .padding(.top, 20)
    }
}
