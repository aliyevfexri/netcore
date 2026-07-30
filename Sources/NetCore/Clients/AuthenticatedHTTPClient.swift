//
//  File.swift
//  
//
//  Created by Fakhri Aliyev on 28.06.23.
//

import Foundation

private class RefreshTokenHandler {
    static var shared: RefreshTokenHandler = .init()
    private init() {}
    
    var isCurrentlyRefresshing: Bool = false
}

public class AuthenticatedHTTPClient: HTTPClient {
//    private let networkMonitoring: NetworkMonitor

    private var bundleVersion: String {
        (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? ""
    }
    let client: HTTPClient
    let tokenProvider: RequestableTokenProvider
    
    public init(client: HTTPClient = URLSession.shared,
                tokenProvider: RequestableTokenProvider,
                networkMonitoring: NetworkMonitor = NetworkMonitor.shared) {
        self.client = client
        self.tokenProvider = tokenProvider
//        self.networkMonitoring = networkMonitoring
    }
    
    @discardableResult
    public func sendRequest(to request: URLRequest, delegate: (any URLSessionTaskDelegate)?) async -> Error? {
        let result: Result<(Data, URLResponse), Error> = await sendRequest(to: request, delegate: delegate)
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
//        guard networkMonitoring.isConnected else { return .failure(RequestError.lostConnection) }
        guard let token = tokenProvider.getToken() else { return .failure(RequestError.expiredAccessToken) }
        
        var signedRequest = request
        signedRequest.addAllHTTPHeaderFields(defaultHeaders(with: token))
        
        if RefreshTokenHandler.shared.isCurrentlyRefresshing {
            print("⌛️ Waiting For Refresh ⌛️")
            try? await Task.sleep(nanoseconds: UInt64(NetworkConstants.Timers.RefreshWaitingMilliSeconds))
        }
        
        let result:Result<(Data, URLResponse), Error> = await client.sendRequest(to: signedRequest, delegate: delegate)
        do {
            let (data, response) = try result.get()
            return .success((data, response))
        } catch(let error) {
            guard case RequestError.expiredAccessToken = error else {
                return .failure(error)
            }
            let refreshError = await refreshAccessToken()
            if let refreshError {
                if case RequestError.unauthorized = refreshError {
                    handleUnauthorized(refreshError)
                } else if case RequestError.waitingForRefresh = refreshError {
                    print("⌛️ Waiting For Refresh ⌛️")
                    try? await Task.sleep(nanoseconds: UInt64(NetworkConstants.Timers.RefreshWaitingMilliSeconds))
                    print("⌛️ Restarting task ↪️")
                    return await sendRequest(to: request, delegate: delegate)
                }
                return .failure(refreshError)
            } else {
                return await sendRequest(to: request, delegate: delegate)
            }
        }
    }
    
    private func refreshAccessToken() async -> Error? {
        if RefreshTokenHandler.shared.isCurrentlyRefresshing {
            return RequestError.waitingForRefresh
        }
        
        RefreshTokenHandler.shared.isCurrentlyRefresshing = true
        //Requests new token
        let result = await tokenProvider.requestNewToken()
        
        RefreshTokenHandler.shared.isCurrentlyRefresshing = false
        
        return result
    }
    
    private func defaultHeaders(with token: String) -> [String : String] {
        var headers:[String : String] = [:]
        headers[NetworkConstants.Headers.XPlatform] = "Mobile"
        headers[NetworkConstants.Headers.XClientType] = "iOS"
        headers[NetworkConstants.Headers.ContentType] = "application/json"
        headers[NetworkConstants.Headers.Authorization] = "Bearer \(token)"
        headers[NetworkConstants.Headers.XAppVersion] = bundleVersion
        return headers
    }
    
    private func handleUnauthorized(_ error: Error) {
        guard case RequestError.unauthorized = error else { return }
        if let onAuthenticationFailure = NetCoreConfiguration.shared.onAuthenticationFailure {
            onAuthenticationFailure()
        } else {
            // Legacy fallback for consumers that have not registered a handler.
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "logout"), object: nil)
        }
    }
}
