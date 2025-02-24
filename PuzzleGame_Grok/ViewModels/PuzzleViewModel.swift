import SwiftUI

struct PuzzlePieceState: Identifiable { // Add Identifiable conformance
    let id: UUID // Add id property
    let piece: PuzzlePiece
    var currentRotation: Int
    var position: CGPoint
    var pilePosition: CGPoint
    var isPlaced: Bool
    
    // Initialize id from piece.id
    init(piece: PuzzlePiece, currentRotation: Int, position: CGPoint, pilePosition: CGPoint, isPlaced: Bool) {
        self.id = piece.id
        self.piece = piece
        self.currentRotation = currentRotation
        self.position = position
        self.pilePosition = pilePosition
        self.isPlaced = isPlaced
    }
}

class PuzzleViewModel: ObservableObject {
    @Published var pieceStates: [PuzzlePieceState]
    let puzzle: Puzzle
    let canvasArea: CGRect
    let cellCenters: [[CGPoint]]
    
    init(puzzle: Puzzle, canvasArea: CGRect) {
        self.puzzle = puzzle
        self.canvasArea = canvasArea
        let cellWidth = canvasArea.width / 4
        let cellHeight = canvasArea.height / 3
        self.cellCenters = (0..<3).map { row in
            (0..<4).map { col in
                CGPoint(
                    x: canvasArea.minX + (CGFloat(col) + 0.5) * cellWidth,
                    y: canvasArea.minY + (CGFloat(row) + 0.5) * cellHeight
                )
            }
        }
        self.pieceStates = []
        initializePieceStates(pileArea: CGRect(
            x: canvasArea.maxX + 50,
            y: canvasArea.minY,
            width: 200,
            height: canvasArea.height
        ))
    }
    
    func initializePieceStates(pileArea: CGRect) {
        pieceStates = []
        for piece in puzzle.pieces {
            let randomX = pileArea.minX + CGFloat.random(in: 0...pileArea.width)
            let randomY = pileArea.minY + CGFloat.random(in: 0...pileArea.height)
            let randomRotation = Int.random(in: 0...3)
            let position = CGPoint(x: randomX, y: randomY)
            let state = PuzzlePieceState(
                piece: piece,
                currentRotation: randomRotation,
                position: position,
                pilePosition: position,
                isPlaced: false
            )
            pieceStates.append(state)
        }
    }
    
    func updatePieceRotation(id: UUID, rotation: Int) {
        if let index = pieceStates.firstIndex(where: { $0.piece.id == id }) {
            pieceStates[index].currentRotation = rotation
        }
    }
    
    func handleDrop(id: UUID, position: CGPoint) {
        if let index = pieceStates.firstIndex(where: { $0.piece.id == id }) {
            let state = pieceStates[index]
            if !state.isPlaced {
                let correctPosition = cellCenters[state.piece.correctRow][state.piece.correctColumn]
                let distance = sqrt(pow(position.x - correctPosition.x, 2) + pow(position.y - correctPosition.y, 2))
                if distance < 50 && state.currentRotation == state.piece.correctRotation {
                    pieceStates[index].position = correctPosition
                    pieceStates[index].isPlaced = true
                } else {
                    pieceStates[index].position = state.pilePosition
                }
            }
        }
    }
    
    var isCompleted: Bool {
        pieceStates.allSatisfy { $0.isPlaced }
    }
}
