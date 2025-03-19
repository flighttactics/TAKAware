//
//  IconImage.swift
//  TAKAware
//
//  Created by Cory Foy on 2/17/25.
//

import Foundation
import SwiftUI

struct IconImage: View {
    let annotation: MapPointAnnotation?
    var frameSize: Double = 30.0
    @State var icon: UIImage?

    // Note: This code is somewhat duplicated in MapView
    func loadImage() async {
        if annotation != nil && annotation!.isShape {
            icon = UIImage(named: "nav_draw")!
        } else {
            let loadedIcon = await IconData.iconFor(annotation: annotation)
            var pointIcon: UIImage = loadedIcon.icon
            if annotation != nil, let pointColor = annotation!.color {
                if loadedIcon.isCircularImage {
                    pointIcon = pointIcon.maskCircularImage(with: pointColor)
                } else if pointIcon.isSymbolImage {
                    pointIcon = pointIcon.maskSymbol(with: pointColor)
                } else {
                    pointIcon = pointIcon.maskImage(with: pointColor)
                }
            }
            icon = pointIcon
        }
    }

    var body: some View {
        Group {
            if icon != nil {
                Image(uiImage: icon!)
                    .resizable()
            } else {
                ProgressView()
            }
        }
        .frame(width: frameSize, height: frameSize)
        .task {
            await loadImage()
        }
    }
}
