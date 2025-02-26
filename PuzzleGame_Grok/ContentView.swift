import SwiftUI

enum Screen {
    case mainMenu
    case choosePuzzle
    case game
    case congratulations
}

struct ContentView: View {
    @State private var currentScreen: Screen = .mainMenu
    @StateObject private var orientationManager = OrientationManager.shared
    let puzzle = createPuzzle() // Single puzzle for MVP
    
    var body: some View {
        ZStack {
            // Main content
            switch currentScreen {
            case .mainMenu:
                MainMenuView(
                    onPlay: { currentScreen = .choosePuzzle },
                    onExit: { /* iOS apps don't exit; show alert or do nothing */ }
                )
            case .choosePuzzle:
                ChoosePuzzleView(
                    puzzle: puzzle,
                    onSelectPuzzle: { currentScreen = .game },
                    onBack: { currentScreen = .mainMenu }
                )
            case .game:
                GameView(
                    puzzle: puzzle,
                    onBack: { currentScreen = .choosePuzzle },
                    onComplete: { currentScreen = .congratulations }
                )
            case .congratulations:
                CongratulationsView(
                    puzzle: puzzle,
                    onBack: { currentScreen = .mainMenu }
                )
            }
        }
        .onAppear {
            // Lock the orientation when app first appears
            OrientationManager.shared.lockLandscapeRight()
        }
        .onChange(of: currentScreen) { _ in
            // Ensure orientation is locked when switching screens
            OrientationManager.shared.lockLandscapeRight()
        }
        // Apply our custom orientation lock to the entire app
        .lockLandscapeRight()
    }
}

// Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewDevice("iPad Pro (12.9-inch) (6th generation)")
    }
}
