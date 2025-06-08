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

struct VideoList: View {
    @FetchRequest(sortDescriptors: [SortDescriptor(\.callsign)], predicate: NSPredicate(format: "videoURL != NULL"))
    private var videos: FetchedResults<COTData>
    
    @State var nullAnnotation: MapPointAnnotation? = nil
    
    var body: some View {
        List {
            ForEach(videos) { video in
                NavigationLink {
                    VideoView(currentSelectedAnnotation: $nullAnnotation, nonBindingAnnotation: MapPointAnnotation(mapPoint: video))
                } label: {
                    HStack {
                        IconImage(annotation: MapPointAnnotation(mapPoint: video))
                        Text(video.callsign ?? "No Callsign")
                    }
                }
            }
        }
    }
}

struct VideoView: UIViewRepresentable {
    @Binding var currentSelectedAnnotation: MapPointAnnotation?
    var nonBindingAnnotation: MapPointAnnotation? = nil
    @State var mediaPlayer = VLCMediaPlayer()

    typealias UIViewType = UIView

    func makeUIView(context: Context) -> UIView {
        let uiView = UIView()
        mediaPlayer.drawable = uiView
        return uiView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let url = currentSelectedAnnotation?.videoURL {
            if mediaPlayer.media == nil {
                TAKLogger.debug("[VideoView] Attempting to play \(url)")
                mediaPlayer.media = VLCMedia(url: url)
                mediaPlayer.play()
            } else if mediaPlayer.media.url != url {
                TAKLogger.debug("[VideoView] Attempting to play updated \(url)")
                mediaPlayer.media = VLCMedia(url: url)
                mediaPlayer.play()
            }
        } else if let url = nonBindingAnnotation?.videoURL {
            if mediaPlayer.media == nil {
                TAKLogger.debug("[VideoView] Attempting to play \(url)")
                mediaPlayer.media = VLCMedia(url: url)
                mediaPlayer.play()
            } else if mediaPlayer.media.url != url {
                TAKLogger.debug("[VideoView] Attempting to play updated \(url)")
                mediaPlayer.media = VLCMedia(url: url)
                mediaPlayer.play()
            }
        } else {
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
    @Binding var currentSelectedAnnotation : MapPointAnnotation?
    @State var viewPresent: Bool = true
    @State var cachedAnnotation: MapPointAnnotation?
    
    var annotation: MapPointAnnotation? {
        return currentSelectedAnnotation
//        if cachedAnnotation != nil { return cachedAnnotation }
//        if currentSelectedAnnotation != nil {
//            DispatchQueue.main.async {
//                cachedAnnotation = currentSelectedAnnotation
//            }
//        }
//        return cachedAnnotation
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                if currentSelectedAnnotation == nil || currentSelectedAnnotation!.videoURL == nil {
                    Text("No Video Source Selected")
                } else {
                    VLCKitPlayer(currentSelectedAnnotation: currentSelectedAnnotation, present: $viewPresent)
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

// ******************************************************************
// VLC Sample Code follows
// ******************************************************************

struct VideoPlayerView2: UIViewRepresentable {
    @ObservedObject var playerWrapper: VLCPlayerWrapper
    
    ///Method to create the UIKit view that is to be represented in SwiftUI
    func makeUIView(context: Context) -> UIView {
        let playerView = UIView()
        return playerView
    }
    
    ///Method to update the UIKit view that is being used in SwiftUI
    func updateUIView(_ uiView: UIView, context: Context) {
        if let player = playerWrapper.mediaPlayer {
            player.drawable = uiView
        }
    }
}

class VLCPlayerWrapper: NSObject, ObservableObject {
    var mediaPlayer: VLCMediaPlayer?
    
    @Published var isPlaying: Bool = false
    @Published var isBuffering: Bool = false
    var videoLength: Double = 0.0
    var progress: Double = 0.0
    var remaining: Double = 0.0
   // var duration:
    
    override init() {
        super.init()
        mediaPlayer = VLCMediaPlayer(options: ["--network-caching=5000"]) // change your media player related options
        mediaPlayer?.delegate = self
    }
    
    ///Method to begin playing the specified URL
    func play(url: URL) {
        let media = VLCMedia(url: url)
        mediaPlayer?.media = media
        mediaPlayer?.play()
    }
    
    ///Method to stop playing the currently playing video
    func stop() {
        mediaPlayer?.stop()
        isPlaying = false
    }

    func pause() {
        if isPlaying && (mediaPlayer?.canPause ?? false) {
           mediaPlayer?.pause()
           isPlaying = false
        } else {
           mediaPlayer?.play()
           isPlaying = true
        }
    }
    
    func moveTo(position: Double) {
        if mediaPlayer?.isSeekable ?? false {
            mediaPlayer?.time = VLCTime(int: Int32(position))
        }
    }
}

extension VLCPlayerWrapper: VLCMediaPlayerDelegate {
    
    // TODO: Nothing other than buffering is called due to a VLC bug
    func mediaPlayerStateChanged(_ aNotification: Notification) {
        if let player = mediaPlayer {
            if player.state == .stopped {
                isPlaying = false
                isBuffering = false
            } else if player.state == .playing {
                isPlaying = true
                isBuffering = false
                videoLength = Double(mediaPlayer?.media.length.intValue ?? Int32(0.0))
            } else if player.state == .opening {
                isBuffering = true
            } else if player.state == .error {
                isBuffering = false
                stop()
            } else if player.state == .buffering {
                isBuffering = true
            } else if player.state == .paused {
                isPlaying = false
                isBuffering = false
            } else if player.state == .ended {
                isPlaying = false
                isBuffering = false
            } else {
                TAKLogger.debug("[VideoPlayer] Unknown VLC state \(player.state)")
                isBuffering = false
            }
        }
    }
    
    // TODO: Because state changes aren't working, we rely on this changing to update state
    func mediaPlayerTimeChanged(_ aNotification: Notification!) {
        isPlaying = true
        isBuffering = false
        progress = Double(mediaPlayer?.time.intValue ?? Int32(0.0))
        remaining = Double(mediaPlayer?.remainingTime.intValue ?? Int32(0.0))
    }
}

extension VLCKitPlayer {
    final class ViewModel {
        var showControllers: Bool = false
        var editing: Bool = false
        var timer: Timer? = nil
    }
}

struct VLCKitPlayer: View {
    @StateObject private var playerWrapper: VLCPlayerWrapper = VLCPlayerWrapper()
    @State private var viewModel = ViewModel()
    @State var selectedUrl: String?
    var currentSelectedAnnotation: MapPointAnnotation?
    @Binding var present: Bool
    
    func fixedUpUrl(_ sourceUrl: String?) -> String? {
        guard let urlToCheck = sourceUrl else { return nil }
        if urlToCheck.hasPrefix("raw://") {
            // Example: raw://https//strmr5.sha.maryland.gov/rtplive/5e0089a0025c0075004d823633235daa/playlist.m3u8:80
            var fixedUrl = urlToCheck.replacingOccurrences(of: "raw://", with: "")
            fixedUrl = fixedUrl.replacingOccurrences(of: "http//", with: "http://")
            if fixedUrl.contains("https") {
                fixedUrl = fixedUrl.replacingOccurrences(of: "https//", with: "https://")
                // Some cameras include a port 80 prefix for https, which won't work
                // But if it's any other port, it's likely intentional
                fixedUrl = fixedUrl.replacingOccurrences(of: ":80$", with: "", options: .regularExpression)
            }
            TAKLogger.debug("[VideoPlayer] Fixing up URL from \(urlToCheck) to \(fixedUrl)")
            return fixedUrl
            
        } else {
            return urlToCheck
        }
    }
    
    init(currentSelectedAnnotation: MapPointAnnotation?, present: Binding<Bool>) {
        self.currentSelectedAnnotation = currentSelectedAnnotation
        _present = present
        let fixedUrl = fixedUpUrl(currentSelectedAnnotation?.videoURL?.absoluteString)
        _selectedUrl = State(wrappedValue: fixedUrl)
    }
    
    
    public var body: some View {
        ZStack(alignment: .topTrailing) {
            if selectedUrl != nil {
                VideoPlayerView2(playerWrapper: playerWrapper)
                    .onAppear {
                        if let stringUrl = selectedUrl, let url = URL(string: stringUrl) {
                            playerWrapper.play(url: url)
                        }
                    }
                    .onTapGesture {
                        if !viewModel.showControllers {
                            viewModel.timer?.invalidate()
                            viewModel.timer =  Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { timer in
                                if viewModel.showControllers && !viewModel.editing {
                                    withAnimation {
                                        viewModel.showControllers.toggle()
                                    }
                                }
                            }
                        }
                        withAnimation {
                            viewModel.showControllers.toggle()
                        }
                        
                    }
                    .overlay {
                        if playerWrapper.isBuffering {
                            ProgressView()
                        }
                    }
                if viewModel.showControllers {
                    Button {
                        playerWrapper.stop()
                        withAnimation {
                            selectedUrl = nil
                            present = false
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .padding()
                            .zIndex(15.0)
                    }
                }
            } else {
                VStack {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                        .scaleEffect(1.5)
                }.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                
            }
        }
        .padding()
        .padding(.vertical, 16)
        .background(.black)
        .ignoresSafeArea()
    }
    
    @ViewBuilder private func Overlay() -> some View {
        if viewModel.showControllers && playerWrapper.mediaPlayer != nil  {
            VStack {
                Spacer()
                Button {
                    playerWrapper.pause()
                } label: {
                    Image(systemName: "play.fill")
                        .font(.title)
                        .scaleEffect(1.4)
                }
                Spacer()
                if playerWrapper.videoLength > 0.0 {
                    Slider(value: $playerWrapper.progress,
                           in: 0.0...playerWrapper.videoLength,
                           step: 0.5) { editing in
                        viewModel.editing = editing
                        if editing {
                            if playerWrapper.mediaPlayer  != nil {
                                playerWrapper.pause()
                            }
                        } else {
                            playerWrapper.moveTo(position: playerWrapper.progress)
                            playerWrapper.pause()
                            if viewModel.showControllers {
                                Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { timer in
                                    withAnimation {
                                        viewModel.showControllers.toggle()
                                    }
                                }
                            }
                        }
                    }
                    
                    HStack {
                        Text("\(VLCTime(int: Int32(playerWrapper.progress)))")
                        Spacer()
                        Text("\(VLCTime(int: Int32(playerWrapper.remaining)))")
                    }
                }
                
            }
            .zIndex(2.0)
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            .foregroundStyle(.white)
            .background(.black.opacity(0.4))
            .onTapGesture {
                withAnimation {
                    viewModel.showControllers.toggle()
                }
            }
        }
        
    }
}
