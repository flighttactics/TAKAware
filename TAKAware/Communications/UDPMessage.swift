//
//  UDPMessage.swift
//  TAKTracker
//
//  This class handles sending and receiving via UDP.
//
//  Created by Cory Foy on 7/12/23.
//

import Foundation
import Network

class UDPMessage: NSObject, ObservableObject {
    private var connectionGroup: NWConnectionGroup?
    // TODO: Make these configurable via Settings
    private let multicastGroup = "239.2.3.1"
    private var port: NWEndpoint.Port = 6969
    
    let parser = StreamParser()
    
    @Published var connected: Bool = false
    
    override init() {
        // Define multicast group endpoint
        let multicastEndpoint = NWEndpoint.hostPort(host: NWEndpoint.Host(multicastGroup), port: port)
        var multicastGroup: NWMulticastGroup?
        do {
            multicastGroup = try NWMulticastGroup(for: [multicastEndpoint])
        } catch {
            TAKLogger.error("Could not join group: \(error)")
        }
        
        // Set up UDP parameters with local endpoint reuse (needed for multicast)
        let params = NWParameters.udp
        params.allowLocalEndpointReuse = true
        params.requiredInterfaceType = .wifi  // Optional: Restrict to Wi-Fi
        
        // Create a multicast connection group,
        connectionGroup = NWConnectionGroup(with: multicastGroup!, using: params)
        
    }
    
    func send(_ payload: Data) {
        TAKLogger.debug("[UDPMessage]: Sending UDP Data")
        connectionGroup!.send(content: payload, completion: { sendError in
            if let error = sendError {
                TAKLogger.debug("[UDPMessage]: Unable to process and send the data: \(error)")
            } else {
                TAKLogger.debug("[UDPMessage]: Data has been sent")
            }
        })
    }
    
    func connect() {
        TAKLogger.debug("[UDPMessage]: Connecting to UDP")
        
        // Handle incoming messages
        connectionGroup?.setReceiveHandler { message, content, isComplete in
            if isComplete {
                if let data = content, !data.isEmpty {
                    self.parser.parseCoTStream(dataStream: data)
                    TAKLogger.debug("Attempting to process CoT event")
                } else {
                    TAKLogger.info("Empty message")
                }
            }
        }
        
        TAKLogger.debug("[UDPMessage]: Starting UDP Connection")
        connectionGroup?.start(queue: .global())
    }

}
