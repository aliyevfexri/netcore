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
    var onAuthenticationFailure: (() -> Void)?

    private init() {}

    // Function to register the model from the main project
    public func registerErrorModel<T: Decodable & Error>(_ type: T.Type) {
        self.errorModelType = type
    }

    public func addExtraHeaders(_ headers: [String: String]) {
        self.extraHeaders.merge(headers) { (_, new) in new }
    }

    /// Registers the handler invoked when a request cannot be authenticated
    /// (token refresh failed / unauthorized). The main project registers a
    /// handler that logs the user out. May be invoked from any thread.
    /// If no handler is registered, a legacy "logout" NotificationCenter
    /// notification is posted instead.
    public func registerAuthenticationFailureHandler(_ handler: @escaping () -> Void) {
        self.onAuthenticationFailure = handler
    }
}
