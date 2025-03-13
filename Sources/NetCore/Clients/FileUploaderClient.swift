//
//  File.swift
//  
//
//  Created by Rashad Shirizada on 18.09.23.
//

import Foundation

public class FileUploaderClient {
    private let networkMonitoring: NetworkMonitor
    private var requestCounter: UInt = 0
    private let maxRequestCount: UInt = 2
    let tokenProvider: RequestableTokenProvider
    
    public init(
                tokenProvider: RequestableTokenProvider,// = DefaultTokenProvider(),
                networkMonitoring: NetworkMonitor = NetworkMonitor.shared) {
        self.tokenProvider = tokenProvider
        self.networkMonitoring = networkMonitoring
    }
    
    public func sendRequest<T:Decodable>(to request: URLRequest, delegate: (any URLSessionTaskDelegate)?) async  -> Result<T, Error>{
        let result =  await sendRequest(to: request, delegate: delegate)
        guard let (data, response) = try? result.get() else {
            return .failure(RequestError.noResponse)
        }
        
        let decodedResult: Result<T,Error> = JSONResponseHandler().handle(with: data, and: response)
        
        switch decodedResult {
        case .success(_):
            return decodedResult
        case .failure(let failure):
            if case RequestError.expiredAccessToken = failure {
                guard requestCounter < maxRequestCount else { return .failure(RequestError.unauthorized) }
                do {
                    let result =  try await tokenProvider.requestNewToken()
                    requestCounter += 1
                    if result == nil {
                        return await sendRequest(to: request, delegate: delegate)
                    } else {
                        return .failure(failure)
                    }
                } catch(let error) {
                    return .failure(error)
                }
            }
            return .failure(failure)
        }
    }
    
    public func sendRequest(to request: URLRequest, delegate: (any URLSessionTaskDelegate)?) async  -> Result<(Data, URLResponse), Error> {
        guard networkMonitoring.isConnected else { return .failure(RequestError.lostConnection)}

        var signedRequest = request
        signedRequest.addAllHTTPHeaderFields(await getDefaultHeaders())

        let result:Result<(Data, URLResponse), Error> = await URLSession.shared.sendRequest(to: signedRequest, delegate: delegate)

        switch result {
        case .success(_):
            return result
        case .failure(let failure):
            if case RequestError.expiredAccessToken = failure {
                do {
                    let result = try await tokenProvider.requestNewToken()
                    if let result{
                        return .failure(result)
                    } else {
                        return await sendRequest(to: request, delegate: delegate)
                    }
                } catch(let error) {
                    return .failure(error)
                }
            }
            return .failure(failure)
        }
    }
    
    private func getDefaultHeaders() async -> [String : String] {
        var headers:[String : String] = [:]
        headers[NetworkConstants.Headers.XPlatform] = "Mobile"
        headers[NetworkConstants.Headers.XClientType] = "iOS"
//        headers[NetworkConstants.Headers.ContentType] = "application/json" // only differnece, later we need to think about this
        if let token = tokenProvider.getToken() {
            headers[NetworkConstants.Headers.Authorization] = "Bearer \(token)"
        }
        //...Add aditional headers
        return headers
    }

    
    
}
