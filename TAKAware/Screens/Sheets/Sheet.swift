//
//  Sheet.swift
//  TAKTracker
//
//  Created by Craig Clayton on 1/11/24.
//

import Foundation
import SwiftUI

struct Sheet: View {
    let type: SheetType
    
    enum SheetType: Identifiable {
        case none
        case emergencySettings
        case settings
        case chat
        case dataSync
        case channels
        
        var id: String {
            switch self {
                case .none: return "none"
                case .emergencySettings: return "emergencysettings"
                case .settings: return "settings"
                case .chat: return "chat"
                case .dataSync: return "datapackage"
                case .channels: return "channels"
            }
        }
    }
    
    @ViewBuilder private func make() -> some View {
        switch type {
            case .none: EmptyView()
            case .emergencySettings: AlertSheet()
        case .settings: SettingsSheet()
            case .chat: ChatView() //ChatSheet()
            case .dataSync: DataSyncSheet()
            case .channels: ChannelSheet()
        }
    }
    
    var body: some View {
        make()
    }
}