//
//  ModuleContainerDelegate.swift
//  GeotabDriveSDK
//
//  Created by Yunfeng Liu on 2020-07-16.
//

/**
 Interface for searching module and module functions.
 */
protocol ModuleContainerDelegate {
    func findModule(module: String) -> Module?
    func findModuleFunction(module: String, function: String) -> ModuleFunction?
}
