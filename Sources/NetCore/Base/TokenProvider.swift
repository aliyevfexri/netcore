//
//  File.swift
//  
//
//  Created by Fakhri Aliyev on 28.06.23.
//

import Foundation

public protocol TokenProvider {
    func getToken() -> String?
}

public protocol RequestableTokenProvider: TokenProvider {
    var api: HTTPClient { get set }
    func requestNewToken() async -> Error?
}
