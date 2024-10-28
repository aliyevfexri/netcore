//
//  File.swift
//  
//
//  Created by Fakhri Aliyev on 28.06.23.
//

import Foundation

public class AuthenticatedHTTPClient: HTTPClient {
    private let networkMonitoring: NetworkMonitor
    private var requestCounter: UInt = 0
    private let maxRequestCount: UInt = 2
    let client: HTTPClient
    let tokenProvider: RequestableTokenProvider
    
    
    public init(client: HTTPClient = URLSession.shared,
                tokenProvider: RequestableTokenProvider,
                networkMonitoring: NetworkMonitor = NetworkMonitor.shared) {
        self.client = client
        self.tokenProvider = tokenProvider
        self.networkMonitoring = networkMonitoring
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
        guard networkMonitoring.isConnected else { return .failure(RequestError.lostConnection) }
        guard let token = tokenProvider.getToken() else { return .failure(RequestError.expiredAccessToken) }
        
        var signedRequest = request
        signedRequest.addAllHTTPHeaderFields(defaultHeaders(with: token))
        
        let result:Result<(Data, URLResponse), Error> = await client.sendRequest(to: signedRequest, delegate: delegate)
        do {
            let (data, response) = try result.get()
            return .success((data, response))
        } catch(let error) {
            guard let newError = await checkExpiredAccessTokenError(error) else {
                return await sendRequest(to: request, delegate: delegate)
            }
            handleUnauthorized(newError)
            return .failure(newError)
        }
    }
    
    private func defaultHeaders(with token: String) -> [String : String] {
        var headers:[String : String] = [:]
        headers[NetworkConstants.Headers.XPlatform] = "Mobile"
        headers[NetworkConstants.Headers.XClientType] = "iOS"
        headers[NetworkConstants.Headers.ContentType] = "application/json"
        headers[NetworkConstants.Headers.Authorization] = "Bearer \(token)"
        return headers
    }
    
    private func checkExpiredAccessTokenError(_ error: Error) async -> Error? {
        //Checks if error is expiredAccesToken. If not return error
        guard case RequestError.expiredAccessToken = error else { return error }
        //If it is checks can request new acces token with refresh token. If request count is lower than max count it continues. Otherwise it returns unauthorized error and should log out
        guard requestCounter < maxRequestCount else { return RequestError.unauthorized }
        //if count is lower than bound, it can request new acces token
        do {
            //Requests new token
            let result = try await tokenProvider.requestNewToken()
            requestCounter += 1
            switch result {
            case .success(_):
                //Token refreshs and should send previous request again
                requestCounter = 0
                return nil
            case .failure(let failure):
                //Should finish request and show error
                return failure
            }
        } catch(let error) {
            return error
        }
    }
    
    private func handleUnauthorized(_ error: Error) {
        guard case RequestError.unauthorized = error else { return }
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "logout"), object: nil)
    }

}
