import SwiftUI

struct GameView: View {
    let puzzle: Puzzle
    let onBack: () -> Void
    let onComplete: () -> Void
    @StateObject private var viewModel: PuzzleViewModel
    @State private var isZoomed: Bool = false
    @StateObject private var orientationManager = OrientationManager.shared
    @State private var draggingPieceID: UUID? = nil // Track which piece is being dragged
    @State private var draggedPiecePosition: CGPoint = .zero // Current position of dragged piece
    
    // Canvas area dimensions
    let canvasSize: CGFloat
    let canvasAreaWidth: CGFloat
    let canvasAreaHeight: CGFloat
    let canvasAreaX: CGFloat
    let canvasAreaY: CGFloat
    
    // Pieces area dimensions
    let piecesAreaWidth: CGFloat
    let piecesAreaHeight: CGFloat
    let piecesAreaX: CGFloat
    let piecesAreaY: CGFloat
    
    init(puzzle: Puzzle, onBack: @escaping () -> Void, onComplete: @escaping () -> Void) {
        self.puzzle = puzzle
        self.onBack = onBack
        self.onComplete = onComplete
        self._viewModel = StateObject(wrappedValue: PuzzleViewModel(
            puzzle: puzzle,
            canvasArea: CGRect(x: 50, y: 50, width: 600, height: 450) // Initial size, will be updated
        ))
        
        // Force landscape orientation
        UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
        
        // Initialize canvas area dimensions with default values - will be updated in onAppear
        self.canvasSize = 600
        self.canvasAreaWidth = 600
        self.canvasAreaHeight = 450
        self.canvasAreaX = 50 + 600/2
        self.canvasAreaY = 50 + 450/2
        
        // Initialize pieces area dimensions with default values - will be updated in onAppear
        self.piecesAreaWidth = 200
        self.piecesAreaHeight = 450
        self.piecesAreaX = 700
        self.piecesAreaY = 225
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white.edgesIgnoringSafeArea(.all)
                
                // Update canvas area based on screen size
                Color.clear.onAppear {
                    // Increased canvas size by ~30%
                    let canvasWidth = geometry.size.width * 0.6 // Increased from 0.45
                    let canvasHeight = canvasWidth * 0.75 // 4:3 aspect ratio
                    let canvasX = geometry.size.width * 0.05
                    let canvasY = geometry.size.height * 0.15
                    
                    viewModel.updateCanvasArea(CGRect(
                        x: canvasX,
                        y: canvasY,
                        width: canvasWidth,
                        height: canvasHeight
                    ))
                }
                .onChange(of: geometry.size) { newSize in
                    // Increased canvas size by ~30%
                    let canvasWidth = newSize.width * 0.6 // Increased from 0.45
                    let canvasHeight = canvasWidth * 0.75 // 4:3 aspect ratio
                    let canvasX = newSize.width * 0.05
                    let canvasY = newSize.height * 0.15
                    
                    viewModel.updateCanvasArea(CGRect(
                        x: canvasX,
                        y: canvasY,
                        width: canvasWidth,
                        height: canvasHeight
                    ))
                }
                
                // Canvas Area - slightly darker background
                Rectangle()
                    .fill(Color.gray.opacity(0.1)) // Same as pile background
                    .frame(width: viewModel.canvasArea.width, height: viewModel.canvasArea.height)
                    .position(x: viewModel.canvasArea.midX, y: viewModel.canvasArea.midY)
                
                // Grid lines (very subtle)
                VStack(spacing: 0) {
                    ForEach(0..<3) { row in
                        HStack(spacing: 0) {
                            ForEach(0..<4) { column in
                                Rectangle()
                                    .fill(Color.clear)
                                    .frame(
                                        width: viewModel.canvasArea.width / 4,
                                        height: viewModel.canvasArea.height / 3
                                    )
                                    .border(Color.gray.opacity(0.1), width: 0.25)
                            }
                        }
                    }
                }
                .position(x: viewModel.canvasArea.midX, y: viewModel.canvasArea.midY)
                
                // Create scrollable area for pieces on the right side
                let piecesAreaWidth = geometry.size.width * 0.25 // Fixed width for pieces area
                let piecesAreaHeight = viewModel.canvasArea.height + 100 // The visible height
                let piecesAreaX = viewModel.canvasArea.maxX + piecesAreaWidth/2 + 40 // Increased gap between canvas and pieces
                let piecesAreaY = viewModel.canvasArea.minY + piecesAreaHeight/2 - 50 // Adjusted position
                
                // Set the area where pieces will be distributed
                Color.clear.onAppear {
                    viewModel.setPiecesArea(
                        x: piecesAreaX - piecesAreaWidth/2,
                        y: viewModel.canvasArea.minY - 50, // Start above the canvas
                        width: piecesAreaWidth,
                        height: piecesAreaHeight
                    )
                }
                .onChange(of: geometry.size) { _ in
                    // Update pieces area if screen size changes
                    viewModel.setPiecesArea(
                        x: piecesAreaX - piecesAreaWidth/2,
                        y: viewModel.canvasArea.minY - 50, // Start above the canvas
                        width: piecesAreaWidth,
                        height: piecesAreaHeight
                    )
                }
                
                // Placed pieces are rendered at the ZStack level
                ForEach(viewModel.pieceStates.filter { $0.isPlaced }) { state in
                    PuzzlePieceView(
                        state: state,
                        cellSize: viewModel.cellSizes,
                        onRotationChange: { rotation in
                            viewModel.updatePieceRotation(id: state.piece.id, rotation: rotation)
                        },
                        onDrop: { position in
                            viewModel.handleDrop(id: state.piece.id, position: position, isDragEnded: false)
                        },
                        onDragEnded: { position in
                            viewModel.handleDrop(id: state.piece.id, position: position, isDragEnded: true)
                        }
                    )
                }
                
                // Pieces area with ScrollView
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 25) { // Increased spacing between pieces
                        // Add top padding to create the indent from the top
                        Spacer().frame(height: 20)
                        
                        // Render placeholder areas for unplaced pieces in the stack
                        ForEach(viewModel.pieceStates.filter { 
                            !$0.isPlaced && (draggingPieceID != $0.id) 
                        }) { state in
                            // We're only showing pieces that are not being dragged
                            ZStack {
                                // Background for each piece container - wider than the piece itself
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.05))
                                    .frame(width: piecesAreaWidth - 20, height: viewModel.cellSizes.width + 30)
                                
                                PieceInStackPlaceholder(
                                    state: state,
                                    cellSize: viewModel.cellSizes.width,
                                    onTapAction: { tappedPieceID in
                                        // Handle double-tap for rotation
                                        if draggingPieceID == nil {
                                            let newRotation = (state.currentRotation + 1) % 4
                                            viewModel.updatePieceRotation(id: tappedPieceID, rotation: newRotation)
                                        }
                                    },
                                    onDragStarted: { pieceID, position in
                                        // When drag starts, update the state immediately
                                        print("Drag started for piece \(pieceID)")
                                        draggingPieceID = pieceID
                                        draggedPiecePosition = position
                                        // Update the view model
                                        viewModel.handleDrop(id: pieceID, position: position, isDragEnded: false)
                                    }
                                )
                            }
                            // Ensure each piece container has a distinct identity area
                            .contentShape(Rectangle())
                            .id(state.id)
                        }
                        
                        // Add bottom padding
                        Spacer().frame(height: 50)
                    }
                    .frame(width: piecesAreaWidth)
                    .padding(.vertical, 10)
                }
                .frame(width: piecesAreaWidth, height: piecesAreaHeight)
                .background(Color.gray.opacity(0.02)) // Very subtle background for the scrollable area
                .cornerRadius(12) // Rounded corners for the scroll area
                .position(x: piecesAreaX, y: piecesAreaY)
                
                // Render the piece being dragged on top of everything
                if let dragID = draggingPieceID {
                    DraggablePieceView(
                        pieceID: dragID,
                        position: $draggedPiecePosition,
                        isDragging: Binding<Bool>(
                            get: { draggingPieceID != nil },
                            set: { 
                                if !$0 { 
                                    draggingPieceID = nil 
                                }
                            }
                        ),
                        viewModel: viewModel
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
                        .position(x: 120, y: 50)
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
        .onAppear {
            // Lock orientation to landscape
            AppDelegate.orientationLock = .landscapeRight
            
            // Force orientation
            OrientationManager.shared.lockLandscapeRight()
        }
        .onDisappear {
            // Keep orientation locked to landscape
            AppDelegate.orientationLock = .landscapeRight
        }
        // Force landscape orientation for the entire view
        .statusBar(hidden: true)
        .environment(\.layoutDirection, .leftToRight) // Ensure LTR layout
        .lockLandscapeRight() // Apply our custom orientation lock
    }
}

// Placeholder for pieces in the stack that can be dragged
struct PieceInStackPlaceholder: View {
    var state: PuzzlePieceState
    var cellSize: CGFloat
    var onTapAction: (UUID) -> Void
    var onDragStarted: (UUID, CGPoint) -> Void
    
    @State private var isPressed: Bool = false
    @State private var isDragging: Bool = false
    
    var body: some View {
        ZStack {
            Image(uiImage: state.piece.image)
                .resizable()
                .scaledToFit()
                .frame(width: cellSize, height: cellSize)
                .rotationEffect(Angle(degrees: Double(state.currentRotation * 90)))
                .scaleEffect(isPressed ? 1.05 : 1.0)
                .shadow(color: isPressed ? .blue.opacity(0.5) : .clear, radius: isPressed ? 10 : 0)
                .animation(.easeInOut(duration: 0.1), value: isPressed) // Faster animation
        }
        .contentShape(Rectangle()) // Make the entire area tappable
        .highPriorityGesture(
            DragGesture(minimumDistance: 5, coordinateSpace: .global) // Small distance for better distinction between tap and drag
                .onChanged { gesture in
                    // Show visual feedback that we're dragging
                    isPressed = true
                    
                    // Only start a new drag if we're not already dragging
                    if !isDragging {
                        isDragging = true
                        let location = gesture.location
                        onDragStarted(state.id, location)
                    }
                }
                .onEnded { _ in
                    // Reset pressed state when drag ends
                    isPressed = false
                    isDragging = false
                }
        )
        // Add double-tap to rotate the piece
        .onTapGesture(count: 2) {
            onTapAction(state.id)
        }
        // Add single tap for visual feedback without freezing
        // .onTapGesture(count: 1) {
        //     // Just show a brief highlight effect
        //     isPressed = true
        //     DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
        //         isPressed = false
        //     }
        // }
    }
}

// This is the active view for a piece being dragged - shows on top of everything
struct DraggablePieceView: View {
    var pieceID: UUID
    @Binding var position: CGPoint
    @Binding var isDragging: Bool
    @ObservedObject var viewModel: PuzzleViewModel
    
    @State private var dragOffset: CGSize = .zero
    
    var body: some View {
        let pieceState = viewModel.pieceStates.first(where: { $0.id == pieceID })
        
        if let state = pieceState {
            Image(uiImage: state.piece.image)
                .resizable()
                .scaledToFit()
                .frame(width: viewModel.cellSizes.width, height: viewModel.cellSizes.height)
                .rotationEffect(Angle(degrees: Double(state.currentRotation * 90)))
                .position(position)
                .scaleEffect(1.05)
                .shadow(color: .blue.opacity(0.5), radius: 10)
                .gesture(
                    DragGesture(coordinateSpace: .global)
                        .onChanged { gesture in
                            // Calculate initial offset on first touch
                            if dragOffset == .zero {
                                dragOffset = CGSize(
                                    width: gesture.startLocation.x - position.x,
                                    height: gesture.startLocation.y - position.y
                                )
                            }
                            
                            // Update the piece position directly with finger tracking
                            let newPosition = CGPoint(
                                x: gesture.location.x - dragOffset.width,
                                y: gesture.location.y - dragOffset.height
                            )
                            
                            // Update position for UI
                            position = newPosition
                            
                            // Tell the view model the piece is being dragged
                            viewModel.handleDrop(id: pieceID, position: newPosition, isDragEnded: false)
                        }
                        .onEnded { gesture in
                            // Calculate final position
                            let finalPosition = CGPoint(
                                x: gesture.location.x - dragOffset.width,
                                y: gesture.location.y - dragOffset.height
                            )
                            
                            // Finalize the position and tell the view model the drag ended
                            position = finalPosition
                            isDragging = false
                            viewModel.handleDrop(id: pieceID, position: finalPosition, isDragEnded: true)
                            
                            // Reset drag offset for next time
                            dragOffset = .zero
                        }
                )
                // Double tap to rotate while dragging
                .onTapGesture(count: 2) {
                    let newRotation = (state.currentRotation + 1) % 4
                    viewModel.updatePieceRotation(id: pieceID, rotation: newRotation)
                }
        }
    }
}

// Standard PuzzlePieceView for pieces placed on the canvas
struct PuzzlePieceView: View {
    let state: PuzzlePieceState
    let cellSize: CGSize
    let onRotationChange: (Int) -> Void
    let onDrop: (CGPoint) -> Void
    let onDragEnded: (CGPoint) -> Void
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging: Bool = false
    @State private var dragLocation: CGPoint?
    
    var body: some View {
        Image(uiImage: state.piece.image)
            .resizable()
            .scaledToFit()
            .frame(width: cellSize.width, height: cellSize.height)
            .rotationEffect(Angle(degrees: Double(state.currentRotation * 90)))
            .position(state.position)
            .gesture(
                DragGesture(coordinateSpace: .global)
                    .onChanged { value in
                        if !state.isPlaced {
                            isDragging = true
                            if dragLocation == nil {
                                // Store initial touch location relative to piece center
                                dragLocation = CGPoint(
                                    x: value.startLocation.x - state.position.x,
                                    y: value.startLocation.y - state.position.y
                                )
                            }
                            
                            // Move piece exactly with finger by calculating offset from touch point
                            let newPosition = CGPoint(
                                x: value.location.x - (dragLocation?.x ?? 0),
                                y: value.location.y - (dragLocation?.y ?? 0)
                            )
                            
                            // Update position directly for smooth movement
                            onDrop(newPosition)
                        }
                    }
                    .onEnded { value in
                        if !state.isPlaced {
                            isDragging = false
                            
                            // Final position is where the finger was released
                            let finalPosition = CGPoint(
                                x: value.location.x - (dragLocation?.x ?? 0),
                                y: value.location.y - (dragLocation?.y ?? 0)
                            )
                            
                            // Signal that drag has ended
                            onDragEnded(finalPosition)
                            
                            // Reset drag location
                            dragLocation = nil
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

// Preference key for tracking view position in a coordinate space
struct ViewPositionKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
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
