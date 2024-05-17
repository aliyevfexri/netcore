//
//  File.swift
//  
//
//  Created by Fakhri Aliyev on 11.07.23.
//

import Foundation

extension Result {
    public func print(){
        switch self {
        case .success(let success):
            Swift.print(success)
        case .failure(let failure):
            Swift.print(String(describing: failure))
        }
    }
}
