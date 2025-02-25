import SwiftUI

struct GameView: View {
    let puzzle: Puzzle
    let onBack: () -> Void
    let onComplete: () -> Void
    @StateObject private var viewModel: PuzzleViewModel
    @State private var isZoomed: Bool = false
    
    init(puzzle: Puzzle, onBack: @escaping () -> Void, onComplete: @escaping () -> Void) {
        self.puzzle = puzzle
        self.onBack = onBack
        self.onComplete = onComplete
        self._viewModel = StateObject(wrappedValue: PuzzleViewModel(
            puzzle: puzzle,
            canvasArea: CGRect(x: 50, y: 50, width: 600, height: 450) // Adjust as needed
        ))
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white.edgesIgnoringSafeArea(.all)
                
                // Canvas Area with Grid
                VStack(spacing: 0) {
                    ForEach(0..<3) { row in
                        HStack(spacing: 0) {
                            ForEach(0..<4) { column in
                                Rectangle()
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(
                                        width: viewModel.canvasArea.width / 4,
                                        height: viewModel.canvasArea.height / 3
                                    )
                                    .border(Color.gray.opacity(0.3), width: 1)
                            }
                        }
                    }
                }
                .position(x: viewModel.canvasArea.midX, y: viewModel.canvasArea.midY)
                
                // Puzzle Pieces
                ForEach(viewModel.pieceStates) { state in
                    PuzzlePieceView(
                        state: state,
                        onRotationChange: { rotation in
                            viewModel.updatePieceRotation(id: state.piece.id, rotation: rotation)
                        },
                        onDrop: { position in
                            viewModel.handleDrop(id: state.piece.id, position: position)
                        }
                    )
                }
                
                // Final Puzzle Image
                if isZoomed {
                    Color.black.opacity(0.8)
                        .edgesIgnoringSafeArea(.all)
                    Image(uiImage: puzzle.finalImage)
                        .resizable()
                        .scaledToFit()
                        .onTapGesture { isZoomed = false }
                } else {
                    Image(uiImage: puzzle.finalImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 75)
                        .position(x: viewModel.canvasArea.maxX + 150, y: 50)
                        .onTapGesture { isZoomed = true }
                }
                
                // Back Button
                Button(action: onBack) {
                    Image(systemName: "arrow.left")
                        .font(.title)
                        .foregroundColor(.green)
                }
                .position(x: 30, y: 30)
            }
        }
        .onChange(of: viewModel.isCompleted) { completed in
            if completed { onComplete() }
        }
    }
}

struct PuzzlePieceView: View {
    let state: PuzzlePieceState
    let onRotationChange: (Int) -> Void
    let onDrop: (CGPoint) -> Void
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging: Bool = false
    
    var body: some View {
        Image(uiImage: state.piece.image)
            .resizable()
            .scaledToFit()
            .frame(width: 150, height: 150)
            .rotationEffect(Angle(degrees: Double(state.currentRotation * 90)))
            .offset(isDragging ? dragOffset : .zero)
            .position(isDragging ? state.position + dragOffset : state.position)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if !state.isPlaced {
                            isDragging = true
                            dragOffset = value.translation
                        }
                    }
                    .onEnded { value in
                        if !state.isPlaced {
                            isDragging = false
                            let finalPosition = state.position + value.translation
                            onDrop(finalPosition)
                            dragOffset = .zero
                        }
                    }
            )
            .onTapGesture(count: 2) { // Double tap to rotate
                if !state.isPlaced {
                    let newRotation = (state.currentRotation + 1) % 4
                    onRotationChange(newRotation)
                }
            }
            .gesture(
                RotationGesture()
                    .onChanged { angle in
                        if !state.isPlaced {
                            // Show rotation preview
                            let degrees = angle.degrees
                            let snappedDegrees = round(degrees / 90) * 90
                            let preview = Int(snappedDegrees / 90) % 4
                            onRotationChange(preview)
                        }
                    }
            )
    }
}

extension CGPoint {
    static func + (lhs: CGPoint, rhs: CGSize) -> CGPoint {
        CGPoint(x: lhs.x + rhs.width, y: lhs.y + rhs.height)
    }
}

struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        GameView(puzzle: createPuzzle(), onBack: {}, onComplete: {})
            .previewDevice("iPad Pro (12.9-inch) (6th generation)")
    }
}
