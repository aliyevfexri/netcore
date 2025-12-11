# NetCore

NetCore is a modern, protocol-oriented networking library for iOS and macOS. Built with Swift's `async/await`, it simplifies common networking tasks such as making API requests, handling authentication with automatic token refreshing, uploading files, and monitoring network connectivity.

## Features

*   **Modern Concurrency**: Built from the ground up using Swift's `async/await`.
*   **Protocol-Oriented**: Designed around a flexible `HTTPClient` protocol for easy mocking and testing.
*   **Automatic Authentication**: Includes an `AuthenticatedHTTPClient` that automatically attaches bearer tokens and transparently refreshes them when they expire.
*   **File Uploads**: A dedicated `FileUploaderClient` simplifies file uploads and provides progress tracking through a delegate.
*   **Network Monitoring**: An `ObservableObject`-based `NetworkMonitor` to observe network status changes, perfect for SwiftUI apps.
*   **Global Configuration**: Use `NetCoreConfiguration` to register custom Codable error models and add extra headers to all requests.
*   **Robust Error Handling**: Provides clear, distinct error types for network, decoding, and server-side issues.
*   **Detailed Logging**: Built-in utilities for printing detailed and readable request/response logs.
*   **Swift Package Manager**: Easily integrate `NetCore` into your project.

## Compatibility

*   iOS 15.0+
*   macOS 12.0+
*   Swift 5.10+

## Installation

You can add NetCore to your project using Swift Package Manager. In Xcode, go to `File > Add Packages...` and enter the repository URL:

```
https://github.com/aliyevfexri/netcore.git
```

## Core Components

| Component                       | Description                                                                                             |
| ------------------------------- | ------------------------------------------------------------------------------------------------------- |
| `HTTPClient`                    | The core protocol defining the a request-sending interface.                                             |
| `URLSessionClient`              | A default `HTTPClient` implementation extending `URLSession` for basic network requests.                |
| `AuthenticatedHTTPClient`       | A decorator client that handles automatic bearer token injection and refresh logic.                     |
| `FileUploaderClient`            | A specialized client for handling file uploads with authentication and progress tracking.               |
| `ServiceClient`                 | A decorator client that adds an `X-Service-Access-Token` header to outgoing requests.                   |
| `NetCoreConfiguration`          | A singleton to set global configurations, such as custom error models and default headers.              |
| `NetworkMonitor`                | An `ObservableObject` that wraps `NWPathMonitor` to provide real-time network connectivity status.      |
| `JSONResponseHandler`           | A utility class responsible for decoding JSON and interpreting HTTP status codes.                       |
| `FileUploadURLSessionDelegate`  | A `URLSessionTaskDelegate` implementation that reports file upload progress via a Combine `PassthroughSubject`.|

## Usage

### 1. Global Configuration

It's recommended to configure `NetCore` once when your app launches. You can register a custom error model that the library will use to decode server errors.

```swift
// In your AppDelegate or SceneDelegate's setup method
import NetCore

// Define a custom error structure that conforms to Decodable & Error
struct MyAPIError: Decodable, Error {
    let message: String
    let errorCode: Int
}

func setupNetworking() {
    // Register your custom error model
    NetCoreConfiguration.shared.registerErrorModel(MyAPIError.self)

    // Optionally add extra headers that will be included in all requests
    NetCoreConfiguration.shared.addExtraHeaders(["X-Client-Version": "1.0.0"])
}
```

### 2. Making Authenticated Requests

The `AuthenticatedHTTPClient` simplifies working with APIs that require bearer token authentication. You just need to provide a `RequestableTokenProvider`.

```swift
import NetCore

// 1. Create a class that conforms to RequestableTokenProvider
class MyTokenProvider: RequestableTokenProvider {
    // The API client for making the token refresh request itself
    var api: HTTPClient = URLSession.shared

    func getToken() -> String? {
        // Return the currently stored access token
        return UserDefaults.standard.string(forKey: "accessToken")
    }

    func requestNewToken() async -> Error? {
        print("Attempting to refresh token...")
        
        // 1. Build a URLRequest for your refresh token endpoint
        // 2. Use `await api.sendRequest(...)` to get a new token
        // 3. If successful, save the new token and return nil
        // 4. If the refresh token is invalid, return RequestError.unauthorized
        // 5. For other failures, return the specific error
        
        // Dummy implementation
        // let newAccessToken = "new-dummy-token"
        // UserDefaults.standard.set(newAccessToken, forKey: "accessToken")
        return nil // Return nil on success
    }
}

// 2. Create and use the authenticated client
let tokenProvider = MyTokenProvider()
let authClient = AuthenticatedHTTPClient(tokenProvider: tokenProvider)

// 3. Send a request
func fetchUserProfile() async {
    guard let url = URL(string: "https://api.example.com/me") else { return }
    let request = URLRequest(url: url)

    let result: Result<User, Error> = await authClient.sendRequest(to: request)

    switch result {
    case .success(let user):
        print("Successfully fetched user: \(user.name)")
    case .failure(let error):
        // If the token was expired, it would have been refreshed automatically.
        // This failure block is reached if refreshing fails or another error occurs.
        print("Failed to fetch user: \(error.localizedDescription)")
    }
}
```

### 3. Uploading a File with Progress

Use `FileUploaderClient` to upload data and monitor its progress with `FileUploadURLSessionDelegate`.

```swift
import NetCore
import Combine

let tokenProvider = MyTokenProvider() // Assumes MyTokenProvider is available
let fileUploader = FileUploaderClient(tokenProvider: tokenProvider)
var cancellables = Set<AnyCancellable>()

func upload(imageData: Data) async {
    guard let url = URL(string: "https://api.example.com/upload/avatar") else { return }

    var request = URLRequest(url: url)
    request.httpMethod = RequestMethod.post.rawValue
    request.httpBody = imageData // The file data to upload
    request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")

    // 1. Set up a subject and delegate to monitor upload progress
    let progressSubject = PassthroughSubject<Double, Never>()
    let progressDelegate = FileUploadURLSessionDelegate(uploadProgressSubject: progressSubject)

    progressSubject
        .receive(on: DispatchQueue.main)
        .sink { progress in
            print("Upload progress: \(String(format: "%.1f", progress))%")
        }
        .store(in: &cancellables)

    // 2. Send the request with the delegate
    let result: Result<UploadResponse, Error> = await fileUploader.sendRequest(
        to: request,
        delegate: progressDelegate
    )

    switch result {
    case .success(let response):
        print("Upload complete: \(response.fileURL)")
    case .failure(let error):
        print("Upload failed: \(error)")
    }
}
```

### 4. Monitoring Network Status

Inject `NetworkMonitor` as an `ObservableObject` in your SwiftUI views to react to connectivity changes.

```swift
import SwiftUI
import NetCore

struct ContentView: View {
    @StateObject private var networkMonitor = NetworkMonitor.shared

    var body: some View {
        VStack {
            if networkMonitor.isConnected {
                Text("Connected!")
                    .foregroundColor(.green)
            } else {
                Text("No Internet Connection")
                    .foregroundColor(.red)
            }
        }
        .onAppear {
            networkMonitor.startMonitoring()
        }
        .onDisappear {
            networkMonitor.stopMonitoring()
        }
    }
}
