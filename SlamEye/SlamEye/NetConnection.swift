//
//  NetConnection.swift
//  BonjourTest
//
//  Created by Jeremy Jones on 5/7/19.
//  Copyright © 2019 Apple Inc. All rights reserved.
//

import Foundation

protocol NetConnectionDelegate {
    func netConnection(_ sender: NetConnection, receivedData data: Data)
    func netConnectionConnected(_ sender: NetConnection)
    func netConnectionClosed(_ sender: NetConnection)
}

protocol NetConnection {
    var delegate: NetConnectionDelegate? { get set }
    func send(_ data: Data)
}

class MockNetConnection: NSObject, NetConnection, Loggable {
    var name: String?
    var peer: MockNetConnection!
    var delegate: NetConnectionDelegate?
    var simulatedNetworkLatency: Double = 0.05
    
    func send(_ data: Data) {
        log()
        DispatchQueue.main.asyncAfter(deadline: .now() + simulatedNetworkLatency) {
            self.peer.receivedData(data)
        }
    }
    
    func receivedData(_ data: Data) {
        log()
        delegate?.netConnection(self, receivedData: data)
    }
}

class StreamNetConnection: NSObject, NetConnection, StreamDelegate, Loggable {
    var name: String?
    private var inputStream: InputStream
    private var outputStream: OutputStream
    private var outputData: [Data] = []
    private var written: size_t = 0
    var delegate: NetConnectionDelegate?
    var connected = false
    
    private func logStream(_ stream: Stream, _ s: String = "", _ function: String = #function) {
        assert(stream == inputStream || stream == outputStream)
        log("\(stream == inputStream ? "[Input]" : "[Output]"): \(s)", function)
    }
    
    init(inputStream: InputStream, outputStream: OutputStream, name: String = "NetConnection") {
        self.name = name
        self.inputStream = inputStream
        self.outputStream = outputStream
        
        super.init()
        
        inputStream.delegate = self
        outputStream.delegate = self
        
        inputStream.schedule(in: RunLoop.main, forMode: .common)
        outputStream.schedule(in: RunLoop.main, forMode: .common)
        
        inputStream.open()
        outputStream.open()
    }
    
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case .openCompleted:
            logStream(aStream, ".openCompleted")
            if inputStream.streamStatus.rawValue >= Stream.Status.open.rawValue && outputStream.streamStatus.rawValue >= Stream.Status.open.rawValue {
                connected = true;
                delegate?.netConnectionConnected(self)
            }
        case .hasBytesAvailable:
            logStream(aStream, ".hasBytesAvailable")
            readInput()
        case .hasSpaceAvailable:
            logStream(aStream, ".hasSpaceAvailable")
            writePendingData()
        case .errorOccurred:
            logStream(aStream, ".errorOccurred")
        case .endEncountered:
            logStream(aStream, ".endEncountered")
        default:
            fatalError()
        }
    }
    
    private func readInput() {
        var readBuffer = Data(count: 1024)
        var data = Data()
        while inputStream.hasBytesAvailable {
            let bufferSize = readBuffer.count
            let _ = readBuffer.withUnsafeMutableBytes { (bufferPointer) -> NSInteger in
                let pointer = bufferPointer.bindMemory(to: UInt8.self).baseAddress!
                let length = inputStream.read(pointer, maxLength: bufferSize)
                data.append(pointer, count: length)
                return length
            }
        }
        delegate?.netConnection(self, receivedData: data)
    }
    
    func send(_ data: Data) {
        let delay: Double = 0.25
        if (delay > 0) {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.outputData.append(data)
                if self.outputStream.hasSpaceAvailable {
                    self.writePendingData()
                }
            }
        } else {
            outputData.append(data)
            if outputStream.hasSpaceAvailable {
                writePendingData()
            }
        }
    }
    
    private func writePendingData() {
        while (outputStream.hasSpaceAvailable && outputData.count != 0) {
            let data = outputData[0]
            let justWritten = data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> Int in
                let pointer = bytes.bindMemory(to: UInt8.self).baseAddress!
                return outputStream.write(pointer + written, maxLength: data.count - written)
            }
            written += justWritten
            if written >= data.count {
                written = 0
                outputData.removeFirst()
            }
        }
    }
}

class NetConnectionServer: NSObject, NetServiceDelegate, Loggable {
    var name: String?
    private let netService: NetService
    private let acceptBlock: (_: StreamNetConnection)->Void
    
    init(type: String, name: String, accept: @escaping (_: StreamNetConnection)->Void) {
        acceptBlock = accept
        netService = NetService(domain: "local", type: type, name: name, port: 0)
        
        super.init()
        
        netService.delegate = self
        netService.publish(options: .listenForConnections)
    }
    
    func netService(_ sender: NetService, didAcceptConnectionWith inputStream: InputStream, outputStream: OutputStream) {
        log()
        acceptBlock(StreamNetConnection(inputStream: inputStream, outputStream: outputStream, name: "server"))
    }
}

class NetConnectionClient: NSObject, NetServiceDelegate, Loggable {
    var name: String?
    private let netService: NetService
    private let resolveBlock: (_: StreamNetConnection)->Void
    
    init(type: String, name: String, resolve: @escaping (_: StreamNetConnection)->Void) {
        resolveBlock = resolve
        netService = NetService(domain: "local", type: type, name: name)
        
        super.init()
        
        netService.delegate = self
        netService.resolve(withTimeout: 100)
    }
    
    init(netService: NetService, resolve: @escaping (_: StreamNetConnection)->Void) {
        resolveBlock = resolve
        self.netService = netService
        
        super.init()
        
        netService.delegate = self
        netService.resolve(withTimeout: 100)
    }
    
    func netServiceDidResolveAddress(_ sender: NetService) {
        log()
        var inputStream: InputStream!
        var outputStream: OutputStream!
        guard sender.getInputStream(&inputStream, outputStream: &outputStream) else { return }
        resolveBlock(StreamNetConnection(inputStream: inputStream, outputStream: outputStream, name: "client"))
    }
}

class NetConnectionBrowser: NSObject, NetServiceBrowserDelegate, Loggable {
    var name: String?
    private let netServiceBrowser: NetServiceBrowser
    private let updateBlock: (_ added: Bool, _ netService: NetService)->Void
    
    init(type: String, update: @escaping (_ added: Bool, _ netService: NetService)->Void) {
        updateBlock = update
        netServiceBrowser = NetServiceBrowser()
        super.init()
        netServiceBrowser.delegate = self
        netServiceBrowser.schedule(in: RunLoop.main, forMode: .common)
        netServiceBrowser.searchForServices(ofType: type, inDomain: "local")
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        log()
        updateBlock(true, service)
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        log()
        updateBlock(false, service)
    }
}
