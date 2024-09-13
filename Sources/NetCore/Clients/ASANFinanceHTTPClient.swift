//
//  File.swift
//  
//
//  Created by Fakhri Aliyev on 12.09.23.
//

import Foundation

public class ASANFinanceHTTPClient: HTTPClient {
    
    let client: HTTPClient
    let tokenProvider: TokenProvider
    
    public init(client: HTTPClient,
                tokenProvider: TokenProvider) {
        self.client = client
        self.tokenProvider = tokenProvider
    }
    
    public func sendRequest(to request: URLRequest) async -> Error? {
        var request = request
        request.addAllHTTPHeaderFields([NetworkConstants.Headers.Authorization: "\(tokenProvider.getToken() ?? "")"])
        return await client.sendRequest(to: request)
    }
    
    public func sendRequest<T>(to request: URLRequest) async -> Result<T, Error> where T : Decodable {
        var request = request
        request.addAllHTTPHeaderFields([NetworkConstants.Headers.Authorization: "\(tokenProvider.getToken() ?? "")"])
        return await client.sendRequest(to: request)
    }
    
    public func sendRequest(to request: URLRequest) async -> Result<(Data, URLResponse), Error> {
        var request = request
        request.addAllHTTPHeaderFields([NetworkConstants.Headers.Authorization: "\(tokenProvider.getToken() ?? "")"])
        return await client.sendRequest(to: request)
    }
}
