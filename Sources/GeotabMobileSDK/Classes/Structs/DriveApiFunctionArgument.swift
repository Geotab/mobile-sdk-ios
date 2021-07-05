//
//  DriveApiFunctionArgument.swift
//  
//
//  Created by Nathan Kuruvilla on 2021-06-25.
//

import Foundation

struct DriveApiFunctionArgument: Codable {
    let callerId: String
    let error: String? // javascript given error, when js failed providing result, it provides error
    let result: String?
}
