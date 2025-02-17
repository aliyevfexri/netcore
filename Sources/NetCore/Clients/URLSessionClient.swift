//
//  File.swift
//  
//
//  Created by Fakhri Aliyev on 11.07.23.
//

import Foundation

//MARK: - Public functions
extension URLSession: HTTPClient {
    public func sendRequest(to request: URLRequest, delegate: (any URLSessionTaskDelegate)?) async  -> Result<(Data, URLResponse), Error> {
        return await sendRequest(to: request, delegate: delegate, networkLostCount: 0)
    }
    
    public func sendRequest(to request: URLRequest, delegate: (any URLSessionTaskDelegate)?) async -> Error? {
        let result: Result<(Data, URLResponse), Error> = await sendRequest(to: request, delegate: delegate)
        switch result {
        case .success:
            return nil
        case .failure(let failure):
            return failure
        }
    }
    
    public func sendRequest<T:Decodable>(to request: URLRequest, delegate: (any URLSessionTaskDelegate)?) async -> Result<T, Error> {
        
        let result: Result<(Data, URLResponse), Error> = await sendRequest(to: request, delegate: delegate)
        
        do{
            let (data, _) = try result.get()
            
            let decodedResult: Result<T,Error> = JSONResponseHandler().decode(with: data)
            
            switch decodedResult {
            case .success(let decodedData):
                return .success(decodedData)
            case .failure(let failure):
                return .failure(failure)
            }
        } catch(let error){
            return .failure(error)
        }
    }
}

//MARK: - Private functions
extension URLSession {
    private func sendRequest(to request: URLRequest, delegate: (any URLSessionTaskDelegate)?, networkLostCount: Int) async  -> Result<(Data, URLResponse), Error> {
        let networkMonitoring = NetworkMonitor.shared
        var request = request
        let requestID: String = UUID().uuidString
        
        guard networkMonitoring.isConnected else {
            printResponseLogs(requestID: requestID, response: nil, result: .failure(RequestError.lostConnection))
            return .failure(RequestError.lostConnection)
        }
        
        request.addAllHTTPHeaderFields(getDefaultHeaders)
        request.printLogs(with: requestID)
        
        var data: Data?
        var response: URLResponse?
        
        do {
            let (sessionData, sessionResponse) = try await URLSession.shared.data(for: request, delegate: delegate)
            data = sessionData
            response = sessionResponse
        } catch (let error) {
            if checkNetworkLostRefresh(with: error, and: networkLostCount) {
                printResponseLogs(requestID: requestID, response: response, result: .failure(error))
                return await sendRequest(to: request, delegate: delegate, networkLostCount: networkLostCount+1)
            } else {
                printResponseLogs(requestID: requestID, response: response, result: .failure(error))
                return .failure(error)
            }
        }
        
        guard let data, let response else {
            printResponseLogs(requestID: requestID, response: response, result: .failure(RequestError.noResponse))
            return .failure(RequestError.noResponse)
        }
        
        if let handledError = JSONResponseHandler().handle(with: data, and: response) {
            printResponseLogs(requestID: requestID, response: response, result: .failure(handledError))
            return .failure(handledError)
        } else {
            printResponseLogs(requestID: requestID, response: response, result: .success(data))
            return .success((data, response))
        }
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
        if let response { print("ℹ️ Response statusCode:", statusCode, "\(isSuccess ? "✅":"❌")") }
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
    
    private var bundleVersion: String {
        (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? ""
    }
    
    private var getDefaultHeaders: [String: String] {
        var headers:[String : String] = [:]
        headers[NetworkConstants.Headers.XPlatform] = "Mobile"
        headers[NetworkConstants.Headers.XClientType] = "iOS"
        headers[NetworkConstants.Headers.ContentType] = "application/json"
        headers[NetworkConstants.Headers.AcceptLanguage] = "az"//TODO: - Changed Fixed Language
        headers[NetworkConstants.Headers.XAppVersion] = bundleVersion
        return headers
    }
    
    private func checkNetworkLostRefresh(with error: Error, and previousNetworkLostCount: Int) -> Bool {
        guard (error as? URLError)?.errorCode == -1005 else { return false }
        print("⁉️Critical Error: ", error)
        
        let newNetworkLostCount = previousNetworkLostCount + 1
        
        guard newNetworkLostCount < 3 else { return false }
        return true
    }
}
