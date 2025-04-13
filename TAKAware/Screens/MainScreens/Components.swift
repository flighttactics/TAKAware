//
//  Components.swift
//  TAKTracker
//
//  Created by Cory Foy on 6/22/24.
//

import SwiftUI
import MapKit

// Our custom view modifier to track rotation and
// call our action
struct DeviceRotationViewModifier: ViewModifier {
    let action: (UIDeviceOrientation) -> Void

    func body(content: Content) -> some View {
        content
            .onAppear()
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                action(UIDevice.current.orientation)
                
            }
    }
}

struct DisplayUIState {
    var currentLocationUnit = LocationUnit.DMS
    var currentSpeedUnit = SpeedUnit.MetersPerSecond
    var currentCompassUnit = DirectionUnit.MN
    var currentHeadingUnit = DirectionUnit.TN
    var currentDistanceUnit = DistanceUnit.Metric
    
    mutating func nextHeadingUnit() {
        currentHeadingUnit = UnitOrder.nextDirectionUnit(unit: currentHeadingUnit)
    }
    
    mutating func nextCompassUnit() {
        currentCompassUnit = UnitOrder.nextDirectionUnit(unit: currentCompassUnit)
    }
    
    mutating func nextSpeedUnit() {
        currentSpeedUnit = UnitOrder.nextSpeedUnit(unit: currentSpeedUnit)
    }
    
    mutating func nextLocationUnit() {
        currentLocationUnit = UnitOrder.nextLocationUnit(unit: currentLocationUnit)
    }
    
    mutating func nextDistanceUnit() {
        currentDistanceUnit = UnitOrder.nextDistanceUnit(unit: currentDistanceUnit)
    }
    
    func headingText(unit:DirectionUnit) -> String {
        if(unit == DirectionUnit.TN) {
            return "°" + "TN"
        } else {
            return "°" + "MN"
        }
    }
    
    func headingValue(unit:DirectionUnit, heading: CLHeading?) -> String {
        guard let locationHeading = heading else {
            #if targetEnvironment(simulator)
            if(unit == DirectionUnit.TN) {
                return "24"
            } else {
                return "18"
            }
            #else
            return "--"
            #endif
        }
        if(unit == DirectionUnit.TN) {
            return headingValue(heading: locationHeading.trueHeading)
        } else {
            return headingValue(heading: locationHeading.magneticHeading)
        }
    }
    
    func headingValue(heading: Double?) -> String {
        guard let locationHeading = heading else {
            return "--"
        }
        return Converter.formatOrZero(item: locationHeading) + "°"
    }
    
    func speedText() -> String {
        switch(currentSpeedUnit) {
            case .MetersPerSecond: return "m/s"
            case .KmPerHour: return "kph"
            case .FeetPerSecond: return "fps"
            case .MilesPerHour: return "mph"
        }
    }
    
    func speedValue(location: CLLocation?) -> String {
        guard let location = location else {
            return "--"
        }
        return Converter.convertToSpeedUnit(unit: currentSpeedUnit, location: location)
    }
    
    func speedValue(metersPerSecond: Double?) -> String {
        guard let metersPerSecond = metersPerSecond else {
            return "--"
        }
        return Converter.convertToSpeedUnit(unit: currentSpeedUnit, metersPerSecond: metersPerSecond)
    }
    
    func distanceValue(distanceMeters: Double) -> String {
        return Converter.convertToDistanceUnit(unit: currentDistanceUnit, distanceMeters: distanceMeters)
    }
    
    func coordinateText() -> String {
        switch(currentLocationUnit) {
            case .DMS: return "DMS"
            case .Decimal: return "Decimal"
            case .MGRS: return "MGRS"
        }
    }
    
    func coordinateValue(location: CLLocationCoordinate2D?) -> CoordinateDisplay {
        var display = CoordinateDisplay()
        guard let location = location else {
            display.addLine(line: CoordinateDisplayLine(
                lineContents: "---"
            ))
            return display
        }
        
        switch(currentLocationUnit) {
        case .DMS:
            let latDMS = Converter.LatLonToDMS(latitude: location.latitude).components(separatedBy: "  ")
            let longDMS = Converter.LatLonToDMS(longitude: location.longitude).components(separatedBy: "  ")
            display.addLine(line: CoordinateDisplayLine(
                lineTitle: latDMS.first!,
                lineContents: latDMS.last!
            ))
            display.addLine(line: CoordinateDisplayLine(
                lineTitle: longDMS.first!,
                lineContents: longDMS.last!
            ))
        case .Decimal:
            display.addLine(line: CoordinateDisplayLine(
                lineTitle: "Lat",
                lineContents: Converter.LatLonToDecimal(latitude: location.latitude)
            ))
            display.addLine(line: CoordinateDisplayLine(
                lineTitle: "Lon",
                lineContents: Converter.LatLonToDecimal(latitude: location.longitude)
            ))
        case .MGRS:
            let mgrsString = Converter.LatLongToMGRS(latitude: location.latitude, longitude: location.longitude)
            display.addLine(line: CoordinateDisplayLine(
                lineContents: mgrsString
            ))

        }
        
        return display
    }
    
    func coordinateValue(location: CLLocation?) -> CoordinateDisplay {
        var display = CoordinateDisplay()
        guard let location = location else {
            display.addLine(line: CoordinateDisplayLine(
                lineContents: "---"
            ))
            return display
        }
        
        return coordinateValue(location: location.coordinate)
    }
}

struct CoordinateDisplay {
    var lines:[CoordinateDisplayLine] = []
    
    mutating func addLine(line:CoordinateDisplayLine) {
        lines.append(line)
    }
}

struct CoordinateDisplayLine {
    var id = UUID()
    var lineTitle:String = ""
    var lineContents:String = ""
    
    func hasLineTitle() -> Bool {
        !lineTitle.isEmpty
    }
}

struct BatteryStatusIcon: View {
    var battery: Double?
    
    var body: some View {
        Group {
            if let battery = battery {
                if battery > 90.0 {
                    Image(systemName: "battery.100percent")
                        .foregroundColor(Color(.label))
                } else if battery > 75.0 {
                    Image(systemName: "battery.75percent")
                        .foregroundColor(Color(.label))
                } else if battery > 40.0 {
                    Image(systemName: "battery.50percent")
                        .foregroundColor(Color(.label))
                } else if battery > 25.0 {
                    Image(systemName: "battery.25percent")
                        .foregroundColor(Color(.systemYellow))
                } else if battery > 0.0 {
                    Image(systemName: "battery.0percent")
                        .foregroundColor(Color(.systemRed))
                }
            }
        }
    }
}
