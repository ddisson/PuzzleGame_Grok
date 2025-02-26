import SwiftUI
import UIKit

// A more robust orientation manager to ensure the app stays in landscape mode
class OrientationManager: ObservableObject {
    static let shared = OrientationManager()
    
    @Published var orientation: UIDeviceOrientation = UIDevice.current.orientation
    private var orientationObserver: NSObjectProtocol?
    
    init() {
        // Begin monitoring orientation at initialization
        if !UIDevice.current.isGeneratingDeviceOrientationNotifications {
            UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        }
        
        // Setup the orientation observer
        setupOrientationObserver()
    }
    
    // Lock to make sure we stay in landscape
    func lockOrientation() {
        // Force the orientation immediately
        setOrientationToLandscape()
        
        // Set the app delegate lock
        AppDelegate.orientationLock = .landscape
    }
    
    // Lock specifically to landscape right
    func lockLandscapeRight() {
        // Force the orientation immediately
        setOrientationToLandscape()
        
        // Set the app delegate lock to be more restrictive
        AppDelegate.orientationLock = .landscapeRight
    }
    
    // Set device orientation to landscape in a safer way
    private func setOrientationToLandscape() {
        if UIDevice.current.orientation.isPortrait {
            let value = UIInterfaceOrientation.landscapeRight.rawValue
            UIDevice.current.setValue(value, forKey: "orientation")
            
            // If the app is compiled with iOS 16+ support, we need an additional method
            if #available(iOS 16.0, *) {
                // For iOS 16+, set the orientation at the scene level
                UIApplication.shared.connectedScenes.forEach { scene in
                    if let windowScene = scene as? UIWindowScene {
                        windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscapeRight))
                    }
                }
            }
        }
    }
    
    private func setupOrientationObserver() {
        // Remove any existing observer
        if let observer = orientationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        // Create a new observer for device orientation changes
        orientationObserver = NotificationCenter.default.addObserver(
            forName: UIDevice.orientationDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            let deviceOrientation = UIDevice.current.orientation
            
            // Update our published orientation
            self?.orientation = deviceOrientation
            
            // If we're in portrait, force back to landscape
            if deviceOrientation.isPortrait {
                // Small delay to avoid fighting with the system
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    // Force back to landscape right
                    self?.setOrientationToLandscape()
                }
            }
        }
    }
    
    deinit {
        // Clean up the observer if the manager is deallocated
        if let observer = orientationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        // Stop generating orientation notifications
        if UIDevice.current.isGeneratingDeviceOrientationNotifications {
            UIDevice.current.endGeneratingDeviceOrientationNotifications()
        }
    }
}

// Add a ViewModifier for easy use in SwiftUI views
struct OrientationLockModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onAppear {
                OrientationManager.shared.lockOrientation()
            }
            .onDisappear {
                // Keep landscape lock when leaving view
                OrientationManager.shared.lockOrientation()
            }
    }
}

// Add a ViewModifier specifically for landscape right
struct LandscapeRightLockModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onAppear {
                OrientationManager.shared.lockLandscapeRight()
            }
            .onDisappear {
                // Keep landscape lock when leaving view
                OrientationManager.shared.lockLandscapeRight()
            }
    }
}

// Extension to make it easier to apply the orientation lock
extension View {
    func lockOrientation() -> some View {
        modifier(OrientationLockModifier())
    }
    
    func lockLandscapeRight() -> some View {
        modifier(LandscapeRightLockModifier())
    }
} 
