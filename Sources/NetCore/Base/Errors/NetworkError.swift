//
//  File.swift
//  
//
//  Created by Fakhri Aliyev on 27.07.23.
//

import Foundation

public enum NetworkError: Error, LocalizedError {
    case backendError(String)
    case unimplementedCase
    
    public var errorDescription: String {
        switch self {
        case .backendError(let error):
            return error
        case .unimplementedCase:
            return "Unimplemented case"
        }
    }
}
