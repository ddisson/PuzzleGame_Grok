//
//  PuzzleGame_GrokApp.swift
//  PuzzleGame_Grok
//
//  Created by Dmitry Disson on 2/24/25.
//

import SwiftUI
import UIKit

// Instead of extending UIViewController directly, we'll use the AppDelegate to control orientation
// and a SceneDelegate observer approach if needed in SwiftUI

// Add orientation locking capability
class AppDelegate: NSObject, UIApplicationDelegate {
    static var orientationLock = UIInterfaceOrientationMask.landscapeRight // Force specifically right landscape
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Force landscape orientation at app launch
        UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
        
        // Start orientation monitoring
        OrientationManager.shared.lockLandscapeRight()
        
        return true
    }
    
    // Called when app is about to enter foreground state
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Force orientation when app comes back to foreground
        UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
    }
}

// Custom scene modifier that will be applied to our SwiftUI views
struct LandscapeModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onAppear {
                // Set the device orientation when the view appears
                UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
            }
    }
}

@main
struct PuzzleGame_GrokApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var orientationManager = OrientationManager.shared
    
    let persistenceController = PersistenceController.shared
    
    init() {
        // Force the initial orientation to landscape
        UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
        
        // Block rotation to other orientations
        AppDelegate.orientationLock = .landscapeRight
        
        // Setup additional orientation locks through our manager
        NotificationCenter.default.addObserver(forName: UIScene.willConnectNotification, 
                                              object: nil, 
                                              queue: .main) { _ in
            OrientationManager.shared.lockLandscapeRight()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .statusBar(hidden: true) // Hide status bar for more immersive experience
                .onAppear {
                    // Ensure orientation is set to landscape when app appears
                    UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
                    OrientationManager.shared.lockLandscapeRight()
                }
                .lockLandscapeRight() // Apply our custom modifier to lock orientation
        }
    }
}
