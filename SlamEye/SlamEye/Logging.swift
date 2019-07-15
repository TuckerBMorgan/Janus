//
//  Logging.swift
//  SyncPlayer
//
//  Created by Jeremy Jones on 5/8/19.
//  Copyright © 2019 Apple Inc. All rights reserved.
//

import Foundation

class Log {
    static var shared: Log = Log()
    private var enabled = Set<String>()
    var enableAll = false
    
    init() {
        if let logParam = UserDefaults.standard.string(forKey: "log") {
            for scope in logParam.split(separator: ",") {
                if scope == "all" {
                    enableAll = true
                } else {
                    enabled.insert(String(scope))
                }
            }
        }
    }
    
    func enable(scope: String) {
        enabled.insert(scope)
    }
    
    func disable(scope: String) {
        enabled.remove(scope)
    }
    
    func log(scopes: [String], message: String) {
        if enableAll || scopes.contains(where: { enabled.contains($0) }) {
            print(message)
        }
    }
    
    static func log(scopes: [String], message: String) {
        Log.shared.log(scopes: scopes, message: message)
    }
}

protocol Loggable {
    var name: String? { get }
    func log(_ message: String, _ function: String)
}

extension Loggable {
    func log(_ message: String = "", _ function: String = #function) {
        let className = String(describing: type(of:self))
        if let name = self.name {
            Log.log(scopes: [className, name], message: "[\(className)-\(name)] \(function): \(message)")
        } else {
            Log.log(scopes: [className], message: "[\(className)] \(function): \(message)")
        }
    }
}
