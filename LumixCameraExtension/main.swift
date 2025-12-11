//
//  main.swift
//  LumixCameraExtension
//
//  Created by Louis Kaiser on 11.12.25.
//

import Foundation
import CoreMediaIO

let providerSource = LumixCameraExtensionProviderSource(clientQueue: nil)
CMIOExtensionProvider.startService(provider: providerSource.provider)

CFRunLoopRun()
