import UIKit
import SwiftUI

struct Puzzle {
    let finalImage: UIImage
    var pieces: [PuzzlePiece]
}

struct PuzzlePiece: Identifiable {
    let id = UUID()
    let image: UIImage
    let correctRow: Int
    let correctColumn: Int
    let correctRotation: Int // 0, 1, 2, 3 (0°, 90°, 180°, 270°)
    var size: CGSize // Size of the piece when placed in the grid
    
    init(image: UIImage, correctRow: Int, correctColumn: Int, correctRotation: Int, size: CGSize = CGSize(width: 150, height: 150)) {
        self.image = image
        self.correctRow = correctRow
        self.correctColumn = correctColumn
        self.correctRotation = correctRotation
        self.size = size
    }
}

// Function to cut image into puzzle pieces
func cutImageIntoPieces(image: UIImage, rows: Int, columns: Int) -> [UIImage] {
    var pieces: [UIImage] = []
    let pieceWidth = image.size.width / CGFloat(columns)
    let pieceHeight = image.size.height / CGFloat(rows)
    
    for row in 0..<rows {
        for column in 0..<columns {
            let rect = CGRect(
                x: CGFloat(column) * pieceWidth,
                y: CGFloat(row) * pieceHeight,
                width: pieceWidth,
                height: pieceHeight
            )
            if let cgImage = image.cgImage?.cropping(to: rect) {
                let pieceImage = UIImage(cgImage: cgImage)
                pieces.append(pieceImage)
            }
        }
    }
    return pieces
}

// Create the puzzle for the MVP
func createPuzzle() -> Puzzle {
    let image = UIImage(named: "anna_elza")!
    let pieceImages = cutImageIntoPieces(image: image, rows: 3, columns: 4)
    var pieces: [PuzzlePiece] = []
    
    // Calculate initial piece size based on the image
    let pieceWidth = image.size.width / 4
    let pieceHeight = image.size.height / 3
    let pieceSize = CGSize(width: pieceWidth, height: pieceHeight)
    
    for row in 0..<3 {
        for column in 0..<4 {
            let pieceImage = pieceImages[row * 4 + column]
            // All pieces have correct rotation of 0 (no rotation needed)
            let piece = PuzzlePiece(
                image: pieceImage,
                correctRow: row,
                correctColumn: column,
                correctRotation: 0, // No rotation needed for the correct position
                size: pieceSize
            )
            pieces.append(piece)
        }
    }
    return Puzzle(finalImage: image, pieces: pieces)
}
