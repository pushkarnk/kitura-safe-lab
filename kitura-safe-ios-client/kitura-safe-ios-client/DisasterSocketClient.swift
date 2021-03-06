//
//  WebsocketClient.swift
//  kitura-safe-lab-dashboard
//
//  Created by David Okun on 5/30/19.
//  Copyright © 2019 David Okun. All rights reserved.
//

import Foundation
import Starscream

protocol DisasterSocketClientDelegate: class {
    func statusReported(client: DisasterSocketClient, person: Person)
    func clientConnected(client: DisasterSocketClient)
    func clientDisconnected(client: DisasterSocketClient)
    func clientErrorOccurred(client: DisasterSocketClient, error: Error)
    func clientReceivedID(client: DisasterSocketClient, id: String)
}

enum DisasterSocketError: Error {
    case badConnection
}

class DisasterSocketClient: WebSocketDelegate {
    func websocketDidConnect(socket: WebSocketClient) {
        delegate?.clientConnected(client: self)
    }
    
    func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        delegate?.clientDisconnected(client: self)
    }
    
    func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        print("websocket message received: \(text)")
        parse(text)
    }
    
    func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        print("websocket message received: \(String(describing: String(data: data, encoding: .utf8)))")
    }
    
    private func parse(_ message: String) {
        let components = message.components(separatedBy: "=")
        if components.first == "ID" {
            guard let id = components.last else {
                return
            }
            delegate?.clientReceivedID(client: self, id: id)
        }
    }
    
    weak var delegate: DisasterSocketClientDelegate?
    var address: String
    var person: Person?
    public var disasterSocket: WebSocket?
    
    init(address: String) {
        self.address = address
    }
    
    public func confirmPhone(with person: Person) {
        do {
            try disasterSocket?.write(data: JSONEncoder().encode(person))
        } catch let error {
            delegate?.clientErrorOccurred(client: self, error: error)
        }
    }
    
    public func simulateDisaster(_ disaster: Disaster) {
        do {
            try disasterSocket?.write(data: JSONEncoder().encode(disaster))
        } catch let error {
            delegate?.clientErrorOccurred(client: self, error: error)
        }
    }
    
    public func disconnect() {
        disasterSocket?.disconnect()
    }
    
    public func attemptConnection() {
        guard let url = URL(string: "ws://\(self.address)/disaster") else {
            delegate?.clientErrorOccurred(client: self, error: DisasterSocketError.badConnection)
            return
        }
        let socket = WebSocket(url: url)
        socket.delegate = self
        disasterSocket = socket
        disasterSocket?.connect()
    }
}
