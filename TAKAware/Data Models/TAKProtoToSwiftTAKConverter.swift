//
//  TAKProtoToSwiftTAKConverter.swift
//  TAKAware
//
//  Created by Cory Foy on 5/11/25.
//
// This is a bridging class for converting TAK protobuf
// into the matching SwiftTAK object structure.

import SwiftTAK
import Foundation

struct TAKProtoToSwiftTAKConverter {
    let protobufMessage: Atakmap_Commoncommo_Protobuf_V1_TakMessage
    
    func convertToSwiftTAK() -> COTEvent {
        let decodedCotEvent = protobufMessage.cotEvent
        let cotPoint: COTPoint? = buildCotPoint(decodedCotEvent: decodedCotEvent)
        let cotDetail: COTDetail? = buildCotDetail(decodedCotEvent: decodedCotEvent)
        let eventChildNodes: [COTNode?] = [cotPoint, cotDetail]
        let flattenedChildNodes = eventChildNodes.compactMap { $0 }
        
        let cotEvent = COTEvent(version: "1", uid: decodedCotEvent.uid, type: decodedCotEvent.type, how: decodedCotEvent.how, time: Date(timeIntervalSince1970: TimeInterval(decodedCotEvent.sendTime)), start: Date(timeIntervalSince1970: TimeInterval(decodedCotEvent.startTime)), stale: Date(timeIntervalSince1970: TimeInterval(decodedCotEvent.staleTime)), childNodes: flattenedChildNodes)
        return cotEvent
    }
    
    private func buildCotPoint(decodedCotEvent: Atakmap_Commoncommo_Protobuf_V1_CotEvent) -> COTPoint? {
        return COTPoint(lat: decodedCotEvent.lat.description, lon: decodedCotEvent.lon.description, hae: decodedCotEvent.hae.description, ce: decodedCotEvent.ce.description, le: decodedCotEvent.le.description)
    }
    
    private func buildCotDetail(decodedCotEvent: Atakmap_Commoncommo_Protobuf_V1_CotEvent) -> COTDetail? {
        guard decodedCotEvent.hasDetail else { return nil }
        
        //hasContact, hasGroup, hasPrecisionLocation, hasTakV, hasTrack, hasStatus
        // let cotPrecisionLocation: COTPrecisionLocation? = nil //TODO: Add this
        let decodedCotDetail = decodedCotEvent.detail
        let cotContact: COTContact? = buildCotContact(decodedCotDetail: decodedCotDetail)
        let cotGroup: COTGroup? = buildCotGroup(decodedCotDetail: decodedCotDetail)
        let cotTakV: COTTakV? = buildCotTakV(decodedCotDetail: decodedCotDetail)
        let cotTrack: COTTrack? = buildCotTrack(decodedCotDetail: decodedCotDetail)
        let cotStatus: COTStatus? = buildCotStatus(decodedCotDetail: decodedCotDetail)
        // let xmlDetail: String = decodedCotDetail.xmlDetail //TODO: Add this too
        
        let detailChildNodes: [COTNode?] = [cotContact, cotGroup, cotTakV, cotTrack, cotStatus]
        let flattenedChildNodes = detailChildNodes.compactMap { $0 }
        
        return COTDetail(childNodes: flattenedChildNodes)
    }
    
    private func buildCotContact(decodedCotDetail: Atakmap_Commoncommo_Protobuf_V1_Detail) -> COTContact? {
        guard decodedCotDetail.hasContact else { return nil }
        let decodedContact = decodedCotDetail.contact
        // TODO: Protobuf doesn't seem to have phone here
        return COTContact(endpoint: decodedContact.endpoint, callsign: decodedContact.callsign)
    }
    
    private func buildCotGroup(decodedCotDetail: Atakmap_Commoncommo_Protobuf_V1_Detail) -> COTGroup? {
        guard decodedCotDetail.hasGroup else { return nil }
        let decodedGroup = decodedCotDetail.group
        // TODO: Protobuf doesn't seem to have extended group / role attributes here
        return COTGroup(name: decodedGroup.name, role: decodedGroup.role)
    }
    
    private func buildCotTakV(decodedCotDetail: Atakmap_Commoncommo_Protobuf_V1_Detail) -> COTTakV? {
        guard decodedCotDetail.hasTakv else { return nil }
        let decodedTakV = decodedCotDetail.takv
        return COTTakV(device: decodedTakV.device, platform: decodedTakV.platform, os: decodedTakV.os, version: decodedTakV.version)
    }
    
    private func buildCotTrack(decodedCotDetail: Atakmap_Commoncommo_Protobuf_V1_Detail) -> COTTrack? {
        guard decodedCotDetail.hasTrack else { return nil }
        let decodedTrack = decodedCotDetail.track
        return COTTrack(speed: decodedTrack.speed.description, course: decodedTrack.course.description)
    }
    
    private func buildCotStatus(decodedCotDetail: Atakmap_Commoncommo_Protobuf_V1_Detail) -> COTStatus? {
        guard decodedCotDetail.hasStatus else { return nil }
        let decodedStatus = decodedCotDetail.status
        return COTStatus(battery: decodedStatus.battery.description)
    }
    
//    private func buildCotPrecisionLocation(decodedCotDetail: Atakmap_Commoncommo_Protobuf_V1_Detail) -> COTPrecisionLocation? {
//        return nil
//    }
}
