// Copyright © 2021 Geotab Inc. All rights reserved.

import Foundation

class MainExecuter: AsyncMainExecuterAdapter {
    func after(_ seconds: TimeInterval, execute: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: execute)
    }
    
    func run(execute: @escaping () -> Void) {
        DispatchQueue.main.async(execute: execute)
    }
}
