//
//  FileInfo.swift
//  GeotabMobileSDK
//
//  Created by Anubhav Saini on 2020-12-10.
//


struct FileInfo: Codable {
    let name: String
    let size: UInt32?
    let isDir: Bool
    let modifiedDate: String
}
