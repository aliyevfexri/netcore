//
//  File.swift
//  
//
//  Created by Fakhri Aliyev on 11.07.23.
//

import Foundation

private class PrinterHandler {
    static var shared: PrinterHandler = .init()
    private init() {
        opQueue = OperationQueue()
        opQueue.maxConcurrentOperationCount = 1
        opQueue.qualityOfService = .background
    }
    
    let opQueue: OperationQueue
}

extension URLRequest {
    public mutating func addAllHTTPHeaderFields(_ newHeaders: [String : String]) {
        let allHeaders = allHTTPHeaderFields ?? [:]
        allHTTPHeaderFields = allHeaders.merging(newHeaders) { (current, _) in current }
    }
    
    public func printLogs(with requestID: String){
        PrinterHandler.shared.opQueue.addOperation {
            let timeDifference = TimeZone.current.secondsFromGMT(for: Date.now)
            let dateForCurrentTimeZone = Date.now.addingTimeInterval(Double(timeDifference))
            
            Swift.print("Request ▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼")
            Swift.print("ℹ️ RequestID:", requestID)
            Swift.print("ℹ️ Request Time:", dateForCurrentTimeZone)
            Swift.print("ℹ️ HttpMethod:", httpMethod ?? "❗️")
            Swift.print("ℹ️ AllHTTPHeaderFields:", allHTTPHeaderFields ?? "❗️")
            Swift.print("ℹ️ HttpBody:", String(decoding: httpBody ?? Data(), as: UTF8.self))
            Swift.print("ℹ️ URL:", url?.absoluteString ?? "NO URL")
            Swift.print("Request ▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲")
        }
    }
}
