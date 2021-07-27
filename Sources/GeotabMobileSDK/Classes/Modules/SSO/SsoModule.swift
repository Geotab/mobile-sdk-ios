// Copyright © 2021 Geotab Inc. All rights reserved.

import Foundation

class SsoModule: Module {

    let viewPresenter: ViewPresenter
    
    init(viewPresenter: ViewPresenter) {
        self.viewPresenter = viewPresenter
        super.init(name: "sso")
        functions.append(SamlLoginFunction(module: self, name: "samlLogin"))
    }
}

