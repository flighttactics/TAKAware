//
//  TAKManager.swift
//  TAK Spike
//
//  Created by Cory Foy on 7/4/23.
//

import Foundation
import MapKit
import Network
import SwiftTAK
import UIKit

class TAKManager: NSObject, URLSessionDelegate, ObservableObject {
    private let udpMessage = UDPMessage()
    private let tcpMessage = TCPMessage()
    private let cotMessage : COTMessage
    
    @Published var isConnectedToServer = false
    
    override init() {
        cotMessage = COTMessage(staleTimeMinutes: SettingsStore.global.staleTimeMinutes, deviceID: UIDevice.current.identifierForVendor!.uuidString, phoneModel: AppConstants.getPhoneModel(), phoneOS: AppConstants.getPhoneOS(), appPlatform: AppConstants.TAK_PLATFORM, appVersion: AppConstants.getAppReleaseAndBuildVersion())
        super.init()
        udpMessage.connect()
        TAKLogger.debug("[TAKManager]: establishing TCP Message Connect")
        tcpMessage.connect()
    }
    
    private func sendToUDP(message: String) {
        let messageContent = Data(message.utf8)
        udpMessage.send(messageContent)
    }
    
    private func sendToTCP(message: String) {
        let messageContent = Data(message.utf8)
        tcpMessage.send(messageContent)
    }
    
    func generatePositionInfo(location: CLLocation?, heading: CLHeading? = nil) -> COTPositionInformation {
        var positionInfo = COTPositionInformation()
        
        if(location != nil) {
            positionInfo.heightAboveElipsoid = location!.altitude
            positionInfo.latitude = location!.coordinate.latitude
            positionInfo.longitude = location!.coordinate.longitude
            positionInfo.speed = location!.speed
        }
        
        if(heading != nil) {
            positionInfo.course = heading!.magneticHeading
        }

        return positionInfo
    }
    
    func broadcastPoint(annotation: MapPointAnnotation) {
        var cotEvent = COTEvent(version: COTMessage.COT_EVENT_VERSION, uid: annotation.id, type: annotation.cotType!, how: HowType.HumanGIGO.rawValue, time: Date(), start: Date(), stale: Date().addingTimeInterval(10.0))
        
        let cotPoint = COTPoint(lat: annotation.coordinate.latitude.description, lon: annotation.coordinate.longitude.description, hae: COTPoint.DEFAULT_ERROR_VALUE.description, ce: COTPoint.DEFAULT_ERROR_VALUE.description, le: COTPoint.DEFAULT_ERROR_VALUE.description)
        
        cotEvent.childNodes.append(cotPoint)
        
        var cotDetail = COTDetail()
        cotDetail.childNodes.append(COTContact(callsign: annotation.title ?? "Unknown"))
        cotDetail.childNodes.append(COTArchive())
        cotDetail.childNodes.append(COTRemarks(message: annotation.remarks ?? ""))
        if annotation.icon != nil {
            cotDetail.childNodes.append(COTUserIcon(iconsetPath: annotation.icon!))
        }
        
        if annotation.isShape && annotation.shape != nil {
            let shape = annotation.shape!
            switch shape {
            case let shape as COTMapCircle:
                let cotEllipse = COTEllipse(major: shape.major, minor: shape.minor, angle: shape.angle)
                cotDetail.childNodes.append(COTShape(childNodes: [cotEllipse]))
                cotDetail.childNodes.append(COTStrokeColor(value: shape.strokeColor))
                cotDetail.childNodes.append(COTStrokeWeight(value: shape.strokeWeight))
                cotDetail.childNodes.append(COTFillColor(value: shape.fillColor))
                cotDetail.childNodes.append(COTLabelsOn(value: shape.labelsOn))
            case let shape as COTMapEllipse:
                let cotEllipse = COTEllipse(major: shape.major, minor: shape.minor, angle: shape.angle)
                cotDetail.childNodes.append(COTShape(childNodes: [cotEllipse]))
                cotDetail.childNodes.append(COTStrokeColor(value: shape.strokeColor))
                cotDetail.childNodes.append(COTStrokeWeight(value: shape.strokeWeight))
                cotDetail.childNodes.append(COTFillColor(value: shape.fillColor))
                cotDetail.childNodes.append(COTLabelsOn(value: shape.labelsOn))
            case let shape as COTMapPolygon:
                for point in UnsafeBufferPointer(start: shape.points(), count: shape.pointCount) {
                    let linkPoint = "\(point.coordinate.latitude),\(point.coordinate.longitude)"
                    cotDetail.childNodes.append(COTLink(point: linkPoint))
                }
                cotDetail.childNodes.append(COTStrokeColor(value: shape.strokeColor))
                cotDetail.childNodes.append(COTStrokeWeight(value: shape.strokeWeight))
                cotDetail.childNodes.append(COTFillColor(value: shape.fillColor))
                cotDetail.childNodes.append(COTLabelsOn(value: shape.labelsOn))
            case let shape as COTMapPolyline:
                for point in UnsafeBufferPointer(start: shape.points(), count: shape.pointCount) {
                    let linkPoint = "\(point.coordinate.latitude),\(point.coordinate.longitude)"
                    cotDetail.childNodes.append(COTLink(point: linkPoint))
                }
                cotDetail.childNodes.append(COTStrokeColor(value: shape.strokeColor))
                cotDetail.childNodes.append(COTStrokeWeight(value: shape.strokeWeight))
                cotDetail.childNodes.append(COTFillColor(value: shape.fillColor))
                cotDetail.childNodes.append(COTLabelsOn(value: shape.labelsOn))
            default:
                TAKLogger.debug("[TAKManager] Unknown shape annotation type \(shape.description)")
            }
        }
        
        cotEvent.childNodes.append(cotDetail)
        
        let message = cotEvent.toXml()
        TAKLogger.debug("[TAKManager]: Getting ready to broadcast marker CoT")
        TAKLogger.debug(message)
        self.sendToUDP(message: message)
        self.sendToTCP(message: message)
        TAKLogger.debug("[TAKManager]: Done broadcasting marker CoT")
    }
    
    func broadcastLocation(locationManager: LocationManager) {
        DispatchQueue.global(qos: .background).async {
            var location: CLLocation? = nil
            var heading: CLHeading? = nil
            
            if(locationManager.lastLocation != nil) {
                location = locationManager.lastLocation
            }
            
            if(locationManager.lastHeading != nil) {
                heading = locationManager.lastHeading
            }
            
            let positionInfo = self.generatePositionInfo(location: location, heading: heading)
            
            let message = self.cotMessage.generateCOTXml(positionInfo: positionInfo, callSign: SettingsStore.global.callSign, group: SettingsStore.global.team, role: SettingsStore.global.role, phoneBatteryStatus: AppConstants.getPhoneBatteryStatus().description)

            TAKLogger.debug("[TAKManager]: Getting ready to broadcast location CoT")
            TAKLogger.debug(message)
            self.sendToUDP(message: message)
            self.sendToTCP(message: message)
            TAKLogger.debug("[TAKManager]: Done broadcasting")
        }
    }
    
    func initiateEmergencyAlert(location: CLLocation?) {
        let alertType = EmergencyType(rawValue: SettingsStore.global.activeAlertType)!
        
        let alert = cotMessage.generateEmergencyCOTXml(positionInfo: generatePositionInfo(location: location), callSign: SettingsStore.global.callSign, emergencyType: alertType, isCancelled: false)

        TAKLogger.debug("[TAKManager]: Getting ready to broadcast emergency alert CoT")
        TAKLogger.debug(alert)
        sendToUDP(message: alert)
        sendToTCP(message: alert)
        TAKLogger.debug("[TAKManager]: Done broadcasting emergency alert")
    }
    
    func cancelEmergencyAlert(location: CLLocation?) {
        SettingsStore.global.activeAlertType = ""
        SettingsStore.global.isAlertActivated = false
        
        let alertType = EmergencyType.Cancel
        
        let alert = cotMessage.generateEmergencyCOTXml(positionInfo: generatePositionInfo(location: location), callSign: SettingsStore.global.callSign, emergencyType: alertType, isCancelled: true)

        TAKLogger.debug("[TAKManager]: Getting ready to broadcast emergency alert cancellation CoT")
        TAKLogger.debug(alert)
        sendToUDP(message: alert)
        sendToTCP(message: alert)
        TAKLogger.debug("[TAKManager]: Done broadcasting emergency alert cancellation")
    }
}
