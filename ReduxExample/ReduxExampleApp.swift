//
//  ReduxExampleApp.swift
//  ReduxExample
//
//  Created by Илья Шаповалов on 24.09.2023.
//

import SwiftUI

@main
struct ReduxExampleApp: App {
    @StateObject var store = SearchStore(
        state: SearchScreenDomain.State(),
        reducer: SearchScreenDomain.live.reduce(_:with:)
    )
    
    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
        }
    }
}
