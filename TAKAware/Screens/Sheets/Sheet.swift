//
//  Sheet.swift
//  TAKTracker
//
//  Created by Craig Clayton on 1/11/24.
//

import Foundation
import SwiftUI

struct Sheet: View {
    let parentView: AwarenessView
    let type: SheetType
    @Binding var conflictedItems: [MapPointAnnotation]
    @Binding var currentSelectedAnnotation: MapPointAnnotation?
    
    enum SheetType: Identifiable {
        case none
        case emergencySettings
        case settings
        case chat
        case dataPackage
        case channels
        case detail
        case videoPlayer
        case deconflictionView
        
        var id: String {
            switch self {
                case .none: return "none"
                case .emergencySettings: return "emergencysettings"
                case .settings: return "settings"
                case .chat: return "chat"
                case .dataPackage: return "datapackage"
                case .channels: return "channels"
                case .detail: return "detail"
                case .videoPlayer: return "videoPlayer"
                case .deconflictionView: return "deconflictionView"
            }
        }
    }
    
    @ViewBuilder private func make() -> some View {
        switch type {
            case .none: EmptyView()
            case .emergencySettings: AlertSheet()
            case .settings: SettingsSheet()
            case .chat: ChatView() //ChatSheet()
            case .dataPackage: DataPackageSheet()
            case .channels: ChannelSheet()
            case .detail: AnnotationDetailView(currentSelectedAnnotation: $currentSelectedAnnotation, parentView: parentView)
            case .videoPlayer: VideoPlayerView(currentSelectedAnnotation: currentSelectedAnnotation)
            case .deconflictionView: DeconflictionSheet(conflictedItems: $conflictedItems, parentView: parentView)
        }
    }
    
    var body: some View {
        make()
    }
}
