import SwiftUI

struct MainMenuView: View {
    let onPlay: () -> Void
    let onExit: () -> Void
    
    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)
            VStack(spacing: 20) {
                Text("Puzzle Game")
                    .font(.largeTitle)
                    .foregroundColor(.green)
                
                Button(action: onPlay) {
                    Text("Play")
                        .font(.title)
                        .padding()
                        .frame(width: 200)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Button(action: onExit) {
                    Text("Exit")
                        .font(.title)
                        .padding()
                        .frame(width: 200)
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
    }
}

struct MainMenuView_Previews: PreviewProvider {
    static var previews: some View {
        MainMenuView(onPlay: {}, onExit: {})
            .previewDevice("iPad Pro (12.9-inch) (6th generation)")
    }
}
