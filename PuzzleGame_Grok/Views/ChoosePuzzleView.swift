import SwiftUI

struct ChoosePuzzleView: View {
    let puzzle: Puzzle
    let onSelectPuzzle: () -> Void
    let onBack: () -> Void
    
    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)
            VStack {
                HStack {
                    Button(action: onBack) {
                        Image(systemName: "arrow.left")
                            .font(.title)
                            .foregroundColor(.green)
                    }
                    Spacer()
                }
                .padding()
                
                ScrollView(.horizontal) {
                    HStack {
                        Button(action: onSelectPuzzle) {
                            VStack {
                                Image(uiImage: puzzle.finalImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 200, height: 150)
                                Text("12 pieces")
                                    .font(.title2)
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

struct ChoosePuzzleView_Previews: PreviewProvider {
    static var previews: some View {
        ChoosePuzzleView(puzzle: createPuzzle(), onSelectPuzzle: {}, onBack: {})
            .previewDevice("iPad Pro (12.9-inch) (6th generation)")
    }
}
