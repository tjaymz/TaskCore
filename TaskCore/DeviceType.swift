//
//  DeviceType.swift
//  TaskCore
//
//  Created by James Trujillo on 5/2/25.
//


import SwiftUI

enum DeviceType {
    case iPhone, iPad
    
    static var current: DeviceType {
#if targetEnvironment(macCatalyst)
        return .iPad
#else
        return UIDevice.current.userInterfaceIdiom == .pad ? .iPad : .iPhone
#endif
    }
}
