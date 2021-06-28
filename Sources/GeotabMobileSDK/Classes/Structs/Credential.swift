//
//  AuthResponse.swift
//  GeotabDriveSDK_Example
//
//  Created by Anubhav Saini on 2020-02-03.
//  Copyright © 2020 CocoaPods. All rights reserved.
//


public struct CredentialResult: Codable {
    public let credentials: GeotabCredentials
    public var path: String
}
