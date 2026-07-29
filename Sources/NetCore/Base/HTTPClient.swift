import Foundation

public protocol HTTPClient {
    @discardableResult
    func sendRequest(to request: URLRequest, delegate: (any URLSessionTaskDelegate)?) async -> Error?
    func sendRequest(to request: URLRequest, delegate: (any URLSessionTaskDelegate)?) async -> Result<(Data, URLResponse), Error>
    func sendRequest<T:Decodable>(to request: URLRequest, delegate: (any URLSessionTaskDelegate)?) async  -> Result<T, Error>

    /// Sends a request signed with the given token, without attempting token
    /// refresh or forced-logout recovery on failure. For auth-adjacent calls
    /// (e.g. logout) where the token must be captured by the caller ahead of
    /// time — so the call is correct even if local token storage is cleared
    /// while the request is in flight — and a 401 must not cascade into a
    /// retry or a forced logout. Header-building is identical to the normal
    /// signed path; only the recovery behavior on failure differs.
    /// Conformers without refresh logic (e.g. the plain URLSession client)
    /// fall back to the default implementation below, which ignores the
    /// token and behaves like `sendRequest`.
    @discardableResult
    func sendRequestWithoutRecovery(to request: URLRequest, signedWith token: String, delegate: (any URLSessionTaskDelegate)?) async -> Error?
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

    public func sendRequestWithoutRecovery(to request: URLRequest, signedWith token: String, delegate: (any URLSessionTaskDelegate)? = nil) async -> Error? {
        return await sendRequest(to: request, delegate: delegate)
    }
}

