// Copyright © 2021 Geotab Inc. All rights reserved.

struct FileInfo: Codable {
    let name: String
    let size: UInt32?
    let isDir: Bool
    let modifiedDate: String
}
