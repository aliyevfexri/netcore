//
//  File.swift
//  
//
//  Created by Fakhri Aliyev on 28.06.23.
//

import Foundation

public struct MainConfiguration {
    public static var environment: AppEnvironment! //environment is set from AppConfiguration init
}

public enum AppEnvironment {
    case prod
    case openBeta
    case dev
    case staging
    
    public var domain: String {
        switch self {
        case .prod: return "https://mygov-api.e-gov.az/"
        case .openBeta: return "https://new-api.my.gov.az/"
        case .dev: return "https://dev-api.my.gov.az/"
        case .staging: return "https://staging-api.my.gov.az/"
        }
    }
    
    public var ASANDomain: String {
        switch self {
        case .prod, .openBeta: return "https://apiasanlogin.my.gov.az/"
        case .dev, .staging: return "https://apiportal.login.gov.az/"
        }
    }
    
    public var CDNDomain: String {
        switch self {
        case .prod, .openBeta: return "https://mygov-cdn.e-gov.az/cdn"
        case .dev, .staging: return "https://dev-cdn.my.gov.az/cdn"
        }
    }
}
