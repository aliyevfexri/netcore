//
//  File.swift
//  
//
//  Created by Rashad Shirizada on 18.09.23.
//

import Foundation

private class FileUploadRefreshTokenHandler {
    static var shared: FileUploadRefreshTokenHandler = .init()
    private init() {}

    var isCurrentlyRefresshing: Bool = false
}

public class FileUploaderClient {
    private let networkMonitoring: NetworkMonitor
    let tokenProvider: RequestableTokenProvider

    public init(
                tokenProvider: RequestableTokenProvider,// = DefaultTokenProvider(),
                networkMonitoring: NetworkMonitor = NetworkMonitor.shared) {
        self.tokenProvider = tokenProvider
        self.networkMonitoring = networkMonitoring
    }

    public func sendRequest<T: Decodable>(to request: URLRequest, delegate: (any URLSessionTaskDelegate)?) async -> Result<T, Error> {
        let result: Result<(Data, URLResponse), Error> = await sendRequest(to: request, delegate: delegate)
        switch result {
        case .success((let data, _)):
            let decodedResult: Result<T, Error> = JSONResponseHandler().decode(with: data)
            return decodedResult
        case .failure(let error):
            return .failure(error)
        }
    }

    private func sendRequest(to request: URLRequest, delegate: (any URLSessionTaskDelegate)?) async -> Result<(Data, URLResponse), Error> {
        guard networkMonitoring.isConnected else { return .failure(RequestError.lostConnection) }
        guard let token = tokenProvider.getToken() else { return .failure(RequestError.expiredAccessToken) }

        if FileUploadRefreshTokenHandler.shared.isCurrentlyRefresshing {
            print("⌛️ Waiting For Refresh ⌛️")
            try? await Task.sleep(nanoseconds: UInt64(NetworkConstants.Timers.RefreshWaitingMilliSeconds))
        }

        let requestID: String = UUID().uuidString
        var signedRequest = request
        signedRequest.addAllHTTPHeaderFields(defaultHeaders(with: token))
        signedRequest.printLogs(with: requestID)
        
        let uploadData = signedRequest.httpBody
        signedRequest.httpBody = nil
        
        guard let uploadData else { return .failure(NetCoreError.backendError("No data to upload")) }
        
        let session = URLSession.shared
        session.configuration.timeoutIntervalForRequest = 300
        session.configuration.timeoutIntervalForResource = 300
        
        let result = try? await session.upload(for: signedRequest, from: uploadData, delegate: delegate)
        
        if let result {
            if let handledError = JSONResponseHandler().handle(with: result.0, and: result.1) {
                printResponseLogs(requestID: requestID, response: result.1, result: .failure(handledError))
                guard case RequestError.expiredAccessToken = handledError else {
                    return .failure(handledError)
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
            } else {
                printResponseLogs(requestID: requestID, response: result.1, result: .success(result.0))
                return .success(result)
            }
        } else {
            print("❌ERROR Code: 1228")
            return .failure(NetCoreError.unknownError)
        }
    }

    private func refreshAccessToken() async -> Error? {
        if FileUploadRefreshTokenHandler.shared.isCurrentlyRefresshing {
            return RequestError.waitingForRefresh
        }

        FileUploadRefreshTokenHandler.shared.isCurrentlyRefresshing = true
        let result = await tokenProvider.requestNewToken()
        FileUploadRefreshTokenHandler.shared.isCurrentlyRefresshing = false

        return result
    }

    private func handleUnauthorized(_ error: Error) {
        guard case RequestError.unauthorized = error else { return }
        if let onAuthenticationFailure = NetCoreConfiguration.shared.onAuthenticationFailure {
            onAuthenticationFailure()
        } else {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "logout"), object: nil)
        }
    }

    private func defaultHeaders(with token: String) -> [String: String] {
        var headers: [String: String] = [:]
        headers[NetworkConstants.Headers.XPlatform] = "Mobile"
        headers[NetworkConstants.Headers.XClientType] = "iOS"
        headers[NetworkConstants.Headers.Authorization] = "Bearer \(token)"
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
