//
//  ChatSheet.swift
//  TAKAware
//
//  Created by Cory Foy on 11/9/24.
//

import Foundation
import SwiftTAK
import SwiftUI

struct ChatSheet: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
                Section(header:
                            Text("Section")
                    .font(.system(size: 14, weight: .medium))
                ) {
                    Text("Hi")
                }
            }
            .navigationBarItems(trailing: Button("Close", action: {
                dismiss()
            }))
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
