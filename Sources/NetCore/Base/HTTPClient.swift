import Foundation


public protocol HTTPClient {
    @discardableResult
    func sendRequest(to request: URLRequest) async -> Error?
    func sendRequest(to request: URLRequest) async -> Result<(Data, URLResponse), Error>
    func sendRequest<T:Decodable>(to request: URLRequest) async  -> Result<T, Error>
}
