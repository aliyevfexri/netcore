//
//  File.swift
//  NetCore
//
//  Created by Faxri Aliyev on 24.10.24.
//

import Foundation

public class NetCoreConfiguration {
    public static let shared = NetCoreConfiguration()
    
    var errorModelType: (Decodable & Error).Type?
    var extraHeaders: [String: String] = [:]
    
    private init() {}
    
    // Function to register the model from the main project
    public func registerErrorModel<T: Decodable & Error>(_ type: T.Type) {
        self.errorModelType = type
    }
    
    public func addExtraHeaders(_ headers: [String: String]) {
        self.extraHeaders.merge(headers) { (_, new) in new }
    }
}
