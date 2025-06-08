//
//  IconImage.swift
//  TAKAware
//
//  Created by Cory Foy on 2/17/25.
//

import Foundation
import SwiftTAK
import SwiftUI

struct RoleImage: View {
    let role: String
    @State var icon: UIImage?
    var frameSize: Double = 30.0

    func loadImage() {
        let loadedIcon = IconData.iconFor(role: role)
        var pointIcon: UIImage = loadedIcon.icon
        icon = pointIcon
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
        .onAppear {
            loadImage()
        }
    }
}

struct TeamImage: View {
    let team: String
    @State var icon: UIImage?
    var frameSize: Double = 30.0

    func loadImage() {
        let loadedIcon = IconData.iconFor(role: TeamRole.TeamMember.rawValue)
        var pointIcon: UIImage = loadedIcon.icon
        let pointColor = IconData.colorForTeam(team)
        if loadedIcon.isCircularImage {
            pointIcon = pointIcon.maskCircularImage(with: pointColor)
        } else if pointIcon.isSymbolImage {
            pointIcon = pointIcon.maskSymbol(with: pointColor)
        } else {
            pointIcon = pointIcon.maskImage(with: pointColor)
        }
        icon = pointIcon
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
        .onAppear {
            loadImage()
        }
    }
}

struct IconImage: View {
    var annotation: MapPointAnnotation? = nil
    var iconPath: String? = nil
    var frameSize: Double = 30.0
    @State var icon: UIImage?

    // Note: This code is somewhat duplicated in MapView
    func loadImage() async {
        if annotation != nil && annotation!.isShape {
            icon = UIImage(named: "nav_draw")!
        } else if annotation == nil && iconPath != nil {
            let loadedIcon = await IconData.iconFor(type2525: "", iconsetPath: iconPath!)
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
