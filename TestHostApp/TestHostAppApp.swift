//
//  TestHostAppApp.swift
//  TestHostApp
//
//  Created by Raj on 30/04/25.
//

import SwiftUI

@main
struct TestHostAppApp: App {
    
    @Environment(\.scenePhase) var scenePhase
    
    init() {
        NSDKCommerceManager.shared.initlize()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
