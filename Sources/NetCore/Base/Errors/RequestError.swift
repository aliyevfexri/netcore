import Foundation

public enum RequestError: Error, LocalizedError {
    case error(Error)
    case decode
    case invalidURL
    case noResponse
    case unauthorized
    case expiredAccessToken
    case unexpectedStatusCode
    case lostConnection
    case unknown
    case waitingForRefresh
    
    public var errorDescription: String? { return customMessage }
    
    public var customMessage: String {
        switch self {
        case .error(let error):
            return error.localizedDescription
        case .decode:
            return "Decode error"
        case .unauthorized:
            return "Session expired"
        case .expiredAccessToken:
            return "Access Token expired. Should get new Access Token with Refresh Token"
        case .lostConnection:
            return "İnternet bağlantısı xətası"
        case .invalidURL:
            return "Invalid path"
        case .noResponse:
            return "No Response"
        case .unexpectedStatusCode:
            return "Unexpected status"
        case .unknown:
            return "Unknown"
        case .waitingForRefresh:
            return "Waiting for refresh"
        }
    }
}

