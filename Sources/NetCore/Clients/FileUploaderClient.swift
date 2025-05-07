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
                
                let result = await tokenProvider.requestNewToken()
                requestCounter += 1
                if result == nil {
                    return await sendRequest(to: request, delegate: delegate)
                } else {
                    return .failure(failure)
                }
            }
            return .failure(failure)
        }
    }
    
    private func sendRequest(to request: URLRequest, delegate: (any URLSessionTaskDelegate)?) async  -> Result<(Data, URLResponse), Error> {
        guard networkMonitoring.isConnected else { return .failure(RequestError.lostConnection)}
        
        let requestID: String = UUID().uuidString
        var signedRequest = request
        signedRequest.addAllHTTPHeaderFields(await getDefaultHeaders())
        signedRequest.printLogs(with: requestID)
        
        let uploadData = signedRequest.httpBody
        signedRequest.httpBody = nil
        
        guard let uploadData else { return .failure(NetCoreError.backendError("No data to upload")) }
        let result = try? await URLSession.shared.upload(for: signedRequest, from: uploadData)
        
        if let result {
            if let handledError = JSONResponseHandler().handle(with: result.0, and: result.1) {
                printResponseLogs(requestID: requestID, response: result.1, result: .failure(handledError))
                return .failure(handledError)
            } else {
                printResponseLogs(requestID: requestID, response: result.1, result: .success(result.0))
                return .success(result)
            }
        } else {
            print("❌ERROR Code: 1228")
            return .failure(NetCoreError.unknownError)
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

    func printResponseLogs(requestID: String, response: URLResponse?, result: Result<Data?, Error>){
        let timeDifference = TimeZone.current.secondsFromGMT(for: Date.now)
        let dateForCurrentTimeZone = Date.now.addingTimeInterval(Double(timeDifference))
        var isSuccess = (try? result.get() != nil) ?? false
        switch result {
        case .success: break;
        case .failure: isSuccess = false
        }
        
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
        
        Swift.print("Response ▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼")
        Swift.print("ℹ️ RequestID:", requestID)
        Swift.print("ℹ️ Response Time:", dateForCurrentTimeZone)
        if response != nil { print("ℹ️ Response statusCode:", statusCode, "\(isSuccess ? "✅":"❌")") }
        switch result {
        case .success(let data):
            if let data {
                print("ℹ️ Data", String(decoding: data, as: UTF8.self))
            } else {
                print("ℹ️ Data", "data IS NILL")
            }
        case .failure(let failure):
            print("ℹ️ Error", failure);
        }
        
        Swift.print("Response ▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲")
    }
    
}
