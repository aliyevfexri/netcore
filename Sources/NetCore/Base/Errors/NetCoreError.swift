//
//  File.swift
//  
//
//  Created by Fakhri Aliyev on 27.07.23.
//

import Foundation

public enum NetCoreError: Error, LocalizedError {
    case backendError(String)
    case unimplementedCase
    case unknownError
    
    public var errorDescription: String {
        switch self {
        case .backendError(let error):
            return error
        case .unimplementedCase:
            return "Unimplemented case"
        case .unknownError:
            return "Naməlum Xəta"
        }
    }
}
