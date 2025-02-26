import SwiftUI

struct PuzzlePieceState: Identifiable {
    let id: UUID
    var piece: PuzzlePiece
    var currentRotation: Int
    var position: CGPoint
    var pilePosition: CGPoint
    var isPlaced: Bool
    var isInPile: Bool
    
    init(piece: PuzzlePiece, currentRotation: Int, position: CGPoint, pilePosition: CGPoint, isPlaced: Bool, isInPile: Bool = true) {
        self.id = piece.id
        self.piece = piece
        self.currentRotation = currentRotation
        self.position = position
        self.pilePosition = pilePosition
        self.isPlaced = isPlaced
        self.isInPile = isInPile
    }
}

class PuzzleViewModel: ObservableObject {
    @Published var pieceStates: [PuzzlePieceState]
    @Published var canvasArea: CGRect
    var puzzle: Puzzle
    var cellCenters: [[CGPoint]]
    var cellSizes: CGSize = CGSize(width: 0, height: 0)
    var piecesArea: CGRect = .zero
    
    // Track the dragged piece to handle correct positioning
    private var draggedPieceID: UUID? = nil
    
    init(puzzle: Puzzle, canvasArea: CGRect) {
        self.puzzle = puzzle
        self.canvasArea = canvasArea
        self.pieceStates = []
        self.cellCenters = []
        updateCellCenters()
        initializePieceStates()
    }
    
    func setPiecesArea(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) {
        piecesArea = CGRect(x: x, y: y, width: width, height: height)
        
        // Only distribute pieces if we haven't already done so or if pieces area changed significantly
        if pieceStates.allSatisfy({ $0.position.x == -1000 && $0.position.y == -1000 }) {
            // Ensure pieces area is created before distributing pieces
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.distributePieces()
            }
        }
    }
    
    private func distributePieces() {
        // Distribute pieces evenly in the pieces area
        let unplacedPieces = pieceStates.filter { !$0.isPlaced }
        let pieceCount = unplacedPieces.count
        
        if pieceCount == 0 || piecesArea == .zero {
            return
        }
        
        // Ensure we have a valid pieces area
        if piecesArea.width < 10 || piecesArea.height < 10 {
            print("Pieces area is too small: \(piecesArea)")
            return
        }
        
        // Calculate spacing between pieces - reduced spacing
        let pieceHeight: CGFloat = cellSizes.height + 10 // Further reduced spacing
        
        // Position the pieces in a single centered column
        // Since we're using a slider approach, we can position them at absolute positions
        // within the stack - no need to worry about ScrollView complications
        for (index, stateID) in unplacedPieces.map({ $0.id }).enumerated() {
            if let stateIndex = pieceStates.firstIndex(where: { $0.id == stateID }) {
                // Horizontal position - center within the pieces area
                let xPos = piecesArea.midX
                
                // Create the position - this is an absolute position in the game view
                let newPosition = CGPoint(
                    x: xPos,
                    y: piecesArea.minY + 30 + CGFloat(index) * pieceHeight
                )
                
                // Update the pile position for returns
                pieceStates[stateIndex].pilePosition = newPosition
                
                // Only update position if not being dragged
                // IMPORTANT: Check against draggedPieceID to prevent repositioning during drag
                if pieceStates[stateIndex].isInPile && 
                   !pieceStates[stateIndex].isPlaced && 
                   draggedPieceID != stateID {
                    pieceStates[stateIndex].position = newPosition
                }
            }
        }
        
        // Force update to ensure UI refreshes
        objectWillChange.send()
    }
    
    func updateCanvasArea(_ newArea: CGRect) {
        canvasArea = newArea
        updateCellCenters()
        
        // Update positions of placed pieces to match new grid
        for (index, state) in pieceStates.enumerated() {
            if state.isPlaced {
                let correctPosition = cellCenters[state.piece.correctRow][state.piece.correctColumn]
                pieceStates[index].position = correctPosition
            }
        }
        
        // Update piece sizes based on the new grid
        updatePieceSizes()
        
        // Redistribute pieces with new sizes
        // Add a slight delay to ensure the pieces area is properly set
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            print("Canvas updated, redistributing pieces")
            self.distributePieces()
        }
    }
    
    private func updateCellCenters() {
        let cellWidth = canvasArea.width / 4
        let cellHeight = canvasArea.height / 3
        cellSizes = CGSize(width: cellWidth, height: cellHeight)
        
        cellCenters = (0..<3).map { row in
            (0..<4).map { col in
                CGPoint(
                    x: canvasArea.minX + (CGFloat(col) + 0.5) * cellWidth,
                    y: canvasArea.minY + (CGFloat(row) + 0.5) * cellHeight
                )
            }
        }
        
        // Update piece sizes when cell sizes change
        updatePieceSizes()
    }
    
    private func updatePieceSizes() {
        // Update the size of each piece in the model
        for (index, piece) in puzzle.pieces.enumerated() {
            if index < puzzle.pieces.count {
                // Set the size of each piece to match the grid cell size
                puzzle.pieces[index].size = cellSizes
            }
        }
    }
    
    func initializePieceStates() {
        pieceStates = []
        
        // Create all pieces first with random rotations
        for piece in puzzle.pieces {
            // All pieces start with random rotation
            let randomRotation = Int.random(in: 0...3)
            let state = PuzzlePieceState(
                piece: piece,
                currentRotation: randomRotation, // Random rotation in the pile
                position: CGPoint(x: -1000, y: -1000), // Off-screen initially, will be updated
                pilePosition: CGPoint(x: -1000, y: -1000), // Will be updated
                isPlaced: false,
                isInPile: true
            )
            pieceStates.append(state)
        }
        
        // Shuffle the pieces to randomize their order
        pieceStates.shuffle()
        
        // If pieces area is set, distribute pieces
        if piecesArea != .zero {
            distributePieces()
        }
    }
    
    // Get pieces that should be shown in the pile
    var piecesForPile: [PuzzlePieceState] {
        return pieceStates.filter { !$0.isPlaced }
    }
    
    // Mark a piece as being dragged - call this when starting a drag
    func markPieceAsDragging(id: UUID) {
        // Set the dragged piece ID
        draggedPieceID = id
        
        // Find the piece in the states array
        if let index = pieceStates.firstIndex(where: { $0.id == id }) {
            // Mark it as not in the pile while dragging
            pieceStates[index].isInPile = false
            
            // Store the current position for debugging
            let currentPosition = pieceStates[index].position
            print("Marking piece as dragging. Current position: \(currentPosition)")
            
            // Force UI update
            objectWillChange.send()
        }
    }
    
    func updatePieceRotation(id: UUID, rotation: Int) {
        if let index = pieceStates.firstIndex(where: { $0.piece.id == id }) {
            pieceStates[index].currentRotation = rotation
        }
    }
    
    func handleDrop(id: UUID, position: CGPoint, isDragEnded: Bool) {
        if let index = pieceStates.firstIndex(where: { $0.piece.id == id }) {
            let state = pieceStates[index]
            
            // Print the current position for debugging
            print("handleDrop called for piece \(id). Current position: \(state.position), New position: \(position), isDragEnded: \(isDragEnded)")
            
            // Special handling for unplaced pieces
            if !state.isPlaced {
                // Update our tracking of which piece is being dragged
                if !isDragEnded {
                    // Drag started or continuing
                    draggedPieceID = id
                    
                    // Mark as not in pile while dragging
                    pieceStates[index].isInPile = false
                    
                    // Update position directly
                    pieceStates[index].position = position
                    
                    // Force UI update
                    objectWillChange.send()
                } else {
                    // Drag ended - clear draggedPieceID
                    draggedPieceID = nil
                    
                    // Print position for debugging
                    print("Piece dropped at: \(position)")
                    print("Canvas area: \(canvasArea)")
                    
                    // Check if the piece is over the canvas area
                    if position.x >= canvasArea.minX && position.x <= canvasArea.maxX &&
                       position.y >= canvasArea.minY && position.y <= canvasArea.maxY {
                        
                        // Get the correct cell for this piece
                        let correctCellCenter = cellCenters[state.piece.correctRow][state.piece.correctColumn]
                        
                        // Calculate the bounds of the correct cell
                        let cellHalfWidth = cellSizes.width / 2
                        let cellHalfHeight = cellSizes.height / 2
                        
                        let cellMinX = correctCellCenter.x - cellHalfWidth
                        let cellMaxX = correctCellCenter.x + cellHalfWidth
                        let cellMinY = correctCellCenter.y - cellHalfHeight
                        let cellMaxY = correctCellCenter.y + cellHalfHeight
                        
                        // Calculate overlap percentage with the correct cell
                        let pieceWidth = cellSizes.width
                        let pieceHeight = cellSizes.height
                        
                        let pieceMinX = position.x - pieceWidth/2
                        let pieceMaxX = position.x + pieceWidth/2
                        let pieceMinY = position.y - pieceHeight/2
                        let pieceMaxY = position.y + pieceHeight/2
                        
                        // Calculate intersection area
                        let overlapWidth = max(0, min(pieceMaxX, cellMaxX) - max(pieceMinX, cellMinX))
                        let overlapHeight = max(0, min(pieceMaxY, cellMaxY) - max(pieceMinY, cellMinY))
                        let overlapArea = overlapWidth * overlapHeight
                        
                        // Calculate piece area
                        let pieceArea = pieceWidth * pieceHeight
                        
                        // Calculate overlap percentage
                        let overlapPercentage = overlapArea / pieceArea
                        
                        // Print for debugging
                        print("Overlap: \(overlapPercentage), Rotation: \(state.currentRotation), Correct: \(state.piece.correctRotation)")
                        
                        // If overlap is more than 40% and rotation is correct, snap and lock
                        if overlapPercentage > 0.4 && state.currentRotation == state.piece.correctRotation {
                            pieceStates[index].position = correctCellCenter
                            pieceStates[index].isPlaced = true
                            pieceStates[index].isInPile = false
                            checkCompletion()
                        } else {
                            // If not over the correct cell or rotation is wrong, return to pile
                            returnPieceToPile(index: index)
                        }
                    } else {
                        // If dropped outside the canvas, return to pile
                        returnPieceToPile(index: index)
                    }
                }
            }
        }
    }
    
    private func returnPieceToPile(index: Int) {
        // Mark as back in the pile
        pieceStates[index].isInPile = true
        pieceStates[index].isPlaced = false
        
        // Return to saved pile position
        pieceStates[index].position = pieceStates[index].pilePosition
        
        // Redistribute all pieces to maintain organization
        distributePieces()
    }
    
    private func checkCompletion() {
        // Check if all pieces are placed correctly
        if isCompleted {
            // Maybe add some animation or feedback here
        }
    }
    
    var isCompleted: Bool {
        pieceStates.allSatisfy { $0.isPlaced }
    }
}
