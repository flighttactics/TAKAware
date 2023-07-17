//
//  UDPMessage.swift
//  TAKTracker
//
//  Created by Cory Foy on 7/12/23.
//

import Foundation
import Network

class UDPMessage: NSObject, ObservableObject {
    var connection: NWConnection?
    
    var host: NWEndpoint.Host = "239.2.3.1"
    var port: NWEndpoint.Port = 6969
    
    @Published var connected: Bool?
    
    func send(_ payload: Data) {
        NSLog("[UDPMessage]: Sending UDP Data")
        connection!.send(content: payload, completion: .contentProcessed({ sendError in
            if let error = sendError {
                NSLog("[UDPMessage]: Unable to process and send the data: \(error)")
            } else {
                NSLog("[UDPMessage]: Data has been sent")
                self.connection!.receiveMessage { (data, context, isComplete, error) in
                    guard let myData = data else { return }
                    NSLog("[UDPMessage]: Received message: " + String(decoding: myData, as: UTF8.self))
                }
            }
        }))
    }
    
    func connect() {
        NSLog("[UDPMessage]: Connecting to UDP")
        connection = NWConnection(host: host, port: port, using: .udp)
        
        connection!.stateUpdateHandler = { (newState) in
            self.connected = false
            switch (newState) {
            case .preparing:
                NSLog("[UDPMessage]: Entered state: preparing")
            case .ready:
                NSLog("[UDPMessage]: Entered state: ready")
                self.connected = true
            case .setup:
                NSLog("[UDPMessage]: Entered state: setup")
            case .cancelled:
                NSLog("[UDPMessage]: Entered state: cancelled")
            case .waiting:
                NSLog("[UDPMessage]: Entered state: waiting")
            case .failed:
                NSLog("[UDPMessage]: Entered state: failed")
            default:
                NSLog("[UDPMessage]: Entered an unknown state")
            }
        }
        
        connection!.viabilityUpdateHandler = { (isViable) in
            if (isViable) {
                NSLog("[UDPMessage]: Connection is viable")
            } else {
                NSLog("[UDPMessage]: Connection is not viable")
            }
        }
        
        connection!.betterPathUpdateHandler = { (betterPathAvailable) in
            if (betterPathAvailable) {
                NSLog("[UDPMessage]: A better path is availble")
            } else {
                NSLog("[UDPMessage]: No better path is available")
            }
        }
        NSLog("[UDPMessage]: Starting UDP Connection")
        connection!.start(queue: .global())
    }
}
