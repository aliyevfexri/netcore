import Foundation

public protocol ResponseHandler {
    func handle<T: Decodable>(with data: Data, and response: URLResponse) -> Result<T, Error>
    func handle(with data: Data, and response: URLResponse) -> Error?
}

public class JSONResponseHandler: ResponseHandler {
    public init(){}
    
    /// This function handles HTTP request with JSON response.
    /// - Parameters:
    ///   - data: Response data comes from api as JSON format
    ///   - response: Response comes from api ( to check status code ) . It has to be HTTPURLResponse
    /// - Returns: Returns Result on success case Decodable model, on failure case Error object
    public func handle<T: Decodable>(with data: Data, and response: URLResponse) -> Result<T, Error> {
        if let error = handle(with: data, and: response) {
            return .failure(error)
        } else {
            return decode(with: data)
        }
    }
    
    /// This function handles HTTP request and returns error if status code is not suitable
    /// - Parameters:
    ///   - data: Response data comes from api and used to decode error object
    ///   - response: Response comes from api ( to check status code ) . It has to be HTTPURLResponse
    /// - Returns: Returns Error object if status code is not suitable
    public func handle(with data: Data, and response: URLResponse) -> Error? {
        guard let response = response as? HTTPURLResponse else {
            return RequestError.noResponse
        }
        switch response.statusCode {
        case 200...299:
            return nil
        case 401:
            return RequestError.expiredAccessToken
        default:
            do {
                let error = try decodeError(from: data)
                return error
            } catch(let error) {
                return error
            }
        }
    }
    
    public func decode<T: Decodable>(with data: Data) -> Result<T, Error>{
        print("⚠️Trying to Parse ", String(describing: T.self))
        do {
            let decodedResponse = try JSONDecoder().decode(T.self, from: data)
            return .success(decodedResponse)
        } catch let error as DecodingError {
            switch error {
            case .typeMismatch(let key, let value):
                print("⚠️error \(key), value \(value) and ERROR: \(error.localizedDescription)")
            case .valueNotFound(let key, let value):
                print("⚠️error \(key), value \(value) and ERROR: \(error.localizedDescription)")
            case .keyNotFound(let key, let value):
                print("⚠️error \(key), value \(value) and ERROR: \(error.localizedDescription)")
            case .dataCorrupted(let key):
                print("⚠️error \(key), and ERROR: \(error.localizedDescription)")
            default:
                print("⚠️ERROR: \(error.localizedDescription)")
            }
            return .failure(RequestError.decode)
        } catch {
            return .failure(error)
        }
    }
    private func decodeError(from data: Data) throws -> Error? {
        guard let errorModelType = NetCoreConfiguration.shared.errorModelType else {
            print("No model registered")
            return NetCoreError.unknownError
        }
        let decoder = JSONDecoder()
        return try decoder.decode(errorModelType, from: data)
    }
}
