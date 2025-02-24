import SwiftUI

enum Screen {
    case mainMenu
    case choosePuzzle
    case game
    case congratulations
}

struct ContentView: View {
    @State private var currentScreen: Screen = .mainMenu
    let puzzle = createPuzzle() // Single puzzle for MVP
    
    var body: some View {
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
}

// Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewDevice("iPad Pro (12.9-inch) (6th generation)")
    }
}
