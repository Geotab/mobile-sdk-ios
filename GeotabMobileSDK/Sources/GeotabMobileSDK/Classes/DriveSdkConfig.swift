//
//  DriveSdkConfig.swift
//  GeotabDriveSDK
//
//  Created by Yunfeng Liu on 2020-01-17.
//

/**
 Configuration options for DriveViewController
 */
public class DriveSdkConfig: MobileSdkConfig {
    /// :nodoc:
    public static var apiCallTimeoutSeconds: Double = 9
    /**
     The server address to which Drive is going to launch from.
     */
    public static var serverAddress: String = "my.geotab.com"
}

