//
//  File.swift
//  MyNetwork
//
//  Created by Faxri Aliyev on 16.10.24.
//

import Foundation
import Combine

/// uploadProgressSubject returns upload progress value
/// Value is between (0 - 100) Double
public class FileUploadURLSessionDelegate: NSObject, URLSessionTaskDelegate {
    var uploadProgressSubject: PassthroughSubject<Double, Never>?
    
    public init(uploadProgressSubject: PassthroughSubject<Double, Never>? = nil) {
        self.uploadProgressSubject = uploadProgressSubject
    }
    
    // This method is called periodically to report progress
    public func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didSendBodyData bytesSent: Int64,
                    totalBytesSent: Int64,
                    totalBytesExpectedToSend: Int64) {
        let progress = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
        Swift.print("Upload progress: \(progress * 100)%")
        
        // You can pass this progress to a closure or observer
        uploadProgressSubject?.send(progress * 100)
    }
}
