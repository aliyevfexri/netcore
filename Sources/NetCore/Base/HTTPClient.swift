import Foundation

public protocol HTTPClient {
    @discardableResult
    func sendRequest(to request: URLRequest, delegate: (any URLSessionTaskDelegate)?) async -> Error?
    func sendRequest(to request: URLRequest, delegate: (any URLSessionTaskDelegate)?) async -> Result<(Data, URLResponse), Error>
    func sendRequest<T:Decodable>(to request: URLRequest, delegate: (any URLSessionTaskDelegate)?) async  -> Result<T, Error>
}

extension HTTPClient {
    public func sendRequest(to request: URLRequest, delegate: (any URLSessionTaskDelegate)? = nil) async -> Error? {
        return await sendRequest(to: request, delegate: delegate)
    }
    
    public func sendRequest(to request: URLRequest, delegate: (any URLSessionTaskDelegate)? = nil) async  -> Result<(Data, URLResponse), Error> {
        return await sendRequest(to: request, delegate: delegate)
    }
    
    public func sendRequest<T:Decodable>(to request: URLRequest, delegate: (any URLSessionTaskDelegate)? = nil) async  -> Result<T, Error> {
        return await sendRequest(to: request, delegate: delegate)
    }
}

