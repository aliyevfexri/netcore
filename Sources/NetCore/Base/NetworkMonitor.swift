//
//  NetworkMonitor.swift
//  
//
//  Created by anduser on 13.07.2023.
//

import Foundation
import Network
import SwiftUI

public final class NetworkMonitor: ObservableObject {
    public static let shared = NetworkMonitor()
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkConnectivityMonitor")
    
    @Published public private(set) var isConnected: Bool = false
    private(set) var currentConnectionType = NWInterface.InterfaceType.other
    
    private init() {
        startMonitoring()
    }
    
    public func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status != .unsatisfied
                self?.currentConnectionType = NWInterface.InterfaceType.allCases.first(where: path.usesInterfaceType) ?? .other
            }
        }
        monitor.start(queue: queue)
    }
    
    public func stopMonitoring() {
        monitor.cancel()
    }
}

extension NWInterface.InterfaceType: CaseIterable {
    public static var allCases: [NWInterface.InterfaceType] = [
        .other,
        .wifi,
        .cellular,
        .loopback,
        .wiredEthernet
    ]
}
