// Copyright © 2021 Geotab Inc. All rights reserved.

import Foundation

protocol AsyncMainExecuterAdapter {
    func after(_ seconds: TimeInterval, execute: @escaping () -> Void)
    
    func run(execute: @escaping () -> Void)
}
