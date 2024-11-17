//
//  AnnotationDetailView.swift
//  TAKAware
//
//  Created by Cory Foy on 7/27/24.
//

import Foundation
import SwiftUI

struct AnnotationDetailView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var annotation: MapPointAnnotation?
    
    func iconImage() -> UIImage {
        let icon = IconData.iconFor(type2525: annotation?.cotType ?? "", iconsetPath: annotation?.icon ?? "")
        return icon.icon
    }

    var body: some View {
        NavigationView {
            List {
                if annotation == nil {
                    Text("No Map Item Selected")
                } else {
                    HStack(alignment: .top) {
                        VStack {
                            Group {
                                Text(annotation!.title ?? "")
                                Text(annotation!.remarks ?? "")
                                Text("Type: \(annotation!.cotType ?? "")")
                                Text("Latitude: \(annotation!.coordinate.latitude.description)")
                                Text("Longitude: \(annotation!.coordinate.longitude.description)")
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        Image(uiImage: iconImage())
                    }
                }
            }
            .navigationBarItems(trailing: Button("Close", action: {
                dismiss()
            }))
            .navigationTitle(annotation?.title ?? "Item Detail")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
