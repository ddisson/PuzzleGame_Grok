//
//  PuzzleGame_GrokApp.swift
//  PuzzleGame_Grok
//
//  Created by Dmitry Disson on 2/24/25.
//

import SwiftUI

@main
struct PuzzleGame_GrokApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
