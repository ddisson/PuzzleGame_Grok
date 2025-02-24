import SwiftUI

struct CongratulationsView: View {
    let puzzle: Puzzle
    let onBack: () -> Void
    @State private var scale: CGFloat = 0.1
    
    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)
            Image(uiImage: puzzle.finalImage)
                .resizable()
                .scaledToFit()
                .scaleEffect(scale)
                .animation(.easeInOut(duration: 1.0), value: scale)
                .onAppear { scale = 1.0 }
            Text("Great Job, Sonya!")
                .font(.largeTitle)
                .foregroundColor(.white)
                .padding()
                .background(Color.black.opacity(0.5))
                .cornerRadius(10)
        }
        .onTapGesture { onBack() }
    }
}

struct CongratulationsView_Previews: PreviewProvider {
    static var previews: some View {
        CongratulationsView(puzzle: createPuzzle(), onBack: {})
            .previewDevice("iPad Pro (12.9-inch) (6th generation)")
    }
}
