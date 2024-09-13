//
//  File.swift
//  
//
//  Created by Fakhri Aliyev on 11.07.23.
//

import Foundation
import NetCore

//MARK: - Public functions
extension URLSession: HTTPClient {
    public func sendRequest(to request: URLRequest) async  -> Result<(Data, URLResponse), Error> {
        return await sendRequest(to: request, networkLostCount: 0)
    }
    
    public func sendRequest(to request: URLRequest) async -> Error? {
        let result: Result<(Data, URLResponse), Error> = await sendRequest(to: request)
        switch result {
        case .success:
            return nil
        case .failure(let failure):
            return failure
        }
    }
    
    public func sendRequest<T:Decodable>(to request: URLRequest) async -> Result<T, Error> {
        
        let result: Result<(Data, URLResponse), Error> = await sendRequest(to: request)
        
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
    private func sendRequest(to request: URLRequest, networkLostCount: Int) async  -> Result<(Data, URLResponse), Error> {
        let networkMonitoring = NetworkMonitor.shared
        
        guard networkMonitoring.isConnected else { return .failure(RequestError.lostConnection)}
        
        var request = request
        request.addAllHTTPHeaderFields(getDefaultHeaders)
        
        request.print()
        
        var data: Data?
        var response: URLResponse?
        
        do {
            let (sessionData, sessionResponse) = try await URLSession.shared.data(for: request, delegate: nil)
            data = sessionData
            response = sessionResponse
        } catch (let error) {
            if checkNetworkLostRefresh(with: error, and: networkLostCount) {
                return await sendRequest(to: request, networkLostCount: networkLostCount+1)
            }
            return .failure(error)
        }
        
        guard let data, let response else {
            return .failure(RequestError.noResponse)
        }
        
        Swift.print("Response ▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼")
        if let httpsRespone = response as? HTTPURLResponse {
            print("ℹ️Response statusCode", httpsRespone.statusCode)
        }
        print("ℹ️Data", String(decoding: data, as: UTF8.self));
        Swift.print("Response ▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲")
        
        guard let handledResult: Error = JSONResponseHandler().handle(with: data, and: response) else {
            return .success((data, response))
        }
        return .failure(handledResult)
    }
    
    private var getDefaultHeaders: [String: String] {
        var headers:[String : String] = [:]
        headers[NetworkConstants.Headers.XPlatform] = "Mobile"
        headers[NetworkConstants.Headers.XClientType] = "iOS"
        headers[NetworkConstants.Headers.ContentType] = "application/json"
        headers[NetworkConstants.Headers.AcceptLanguage] = "az"//TODO: - Changed Fixed Language
        return headers
    }
    //TODO: Explain this code. Why is it written
    private func checkNetworkLostRefresh(with error: Error, and previousNetworkLostCount: Int) -> Bool {
        guard (error as? URLError)?.errorCode == -1005 else { return false }
        print("⁉️Critical Error: ", error)
        
        let newNetworkLostCount = previousNetworkLostCount + 1
        
        guard newNetworkLostCount < 3 else { return false }
        return true
    }
    
}
