//
//  ServiceClient.swift
//  NetCore
//
//  Created by Atash Musazada on 14.11.24.
//

import Foundation

public class ServiceClient: HTTPClient {
    private let networkMonitoring: NetworkMonitor
    let client: AuthenticatedHTTPClient
    let tokenProvider: TokenProvider
    
    typealias GeneralResponse = Result<(Data, URLResponse), Error>
    
    public init(client: AuthenticatedHTTPClient,
                tokenProvider: TokenProvider,
                networkMonitoring: NetworkMonitor = NetworkMonitor.shared) {
        self.client = client
        self.tokenProvider = tokenProvider
        self.networkMonitoring = networkMonitoring
    }
    
    @discardableResult
    public func sendRequest(to request: URLRequest, delegate: (any URLSessionTaskDelegate)?) async -> Error? {
        let result: GeneralResponse = await sendRequest(to: request, delegate: delegate)
        switch result {
        case .success:
            return nil
        case .failure(let failure):
            return failure
        }
    }
    
    public func sendRequest<T:Decodable>(to request: URLRequest, delegate: (any URLSessionTaskDelegate)?) async -> Result<T, Error>{
        let result: Result<(Data, URLResponse), Error> = await sendRequest(to: request, delegate: delegate)
        switch result {
        case .success((let data, _)):
            let handledResult: Result<T, Error> = JSONResponseHandler().decode(with: data)
            return handledResult
        case .failure(let error):
            return .failure(error)
        }
    }
    
    public func sendRequest(to request: URLRequest, delegate: (any URLSessionTaskDelegate)?) async -> Result<(Data, URLResponse), Error> {
        
        var signedRequest = request
        
        if let serviceToken = tokenProvider.getToken() {
            var headers:[String : String] = [:]
            headers[NetworkConstants.Headers.XServiceAccessToken] = "\(serviceToken)"
            signedRequest.addAllHTTPHeaderFields(headers)
        }
        
        return await client.sendRequest(to: signedRequest, delegate: delegate)
    }
}
