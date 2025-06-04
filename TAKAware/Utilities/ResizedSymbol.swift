//
//  ResizedSymbol.swift
//  TAKAware
//
//  Created by Cory Foy on 6/3/25.
//  Adapted from https://stackoverflow.com/questions/79198492/how-do-i-customise-the-button-image-in-a-menu-item/79198934#79198934
//

import Foundation
import SwiftUI

struct ResizedImage: View {
    let name: String
    var targetSize: CGFloat = 20

    var body: some View {
        let size = CGSize(width: targetSize, height: targetSize)
        let image = Image(name)
        return Image(size: size) { ctx in
            let resolvedImage = ctx.resolve(image)
            let imageSize = resolvedImage.size
            let maxDimension = min(imageSize.width, imageSize.height)
            let w = targetSize * imageSize.width / max(1, maxDimension)
            let h = targetSize * imageSize.height / max(1, maxDimension)
            let x = (targetSize - w) / 2
            let y = (targetSize - h) / 2
            ctx.draw(resolvedImage, in: CGRect(x: x, y: y, width: w, height: h))
        }
    }
}

struct ResizedSystemImage: View {
    let systemName: String
    var targetSize: CGFloat = 20

    var body: some View {
        let size = CGSize(width: targetSize, height: targetSize)
        let image = Image(systemName: systemName)
        return Image(size: size) { ctx in
            let resolvedImage = ctx.resolve(image)
            let imageSize = resolvedImage.size
            let maxDimension = min(imageSize.width, imageSize.height)
            let w = targetSize * imageSize.width / max(1, maxDimension)
            let h = targetSize * imageSize.height / max(1, maxDimension)
            let x = (targetSize - w) / 2
            let y = (targetSize - h) / 2
            ctx.draw(resolvedImage, in: CGRect(x: x, y: y, width: w, height: h))
        }
    }
}
