//
//  Board.swift
//  TapSudoku
//
//  Created by Jeff Fischer on 12/12/22.
//

import Foundation

struct Board: Equatable {
    enum Difficulty: Int, CaseIterable {
#if DEBUG
        case testing = 2
#endif
        case trivial = 10
        case easy = 20
        case medium = 24
        case hard = 27
        case extreme = 29
    }

    let size = 9
    let difficulty: Difficulty

    /// `solvedBoard` has all cells filled with valid numbers. It is the originally generated solution to the game.
    /// `startingBoard` is a copy of solvedBoard with a number of cells set to zero, according to the selected game difficulty level.
    /// `playerBoard` is the copy of startingBoard with which the user interacts.
    var solvedBoard = [[Int]]()
    var startingBoard = [[Int]]()
    var playerBoard = [[Int]]()

    var cellHints = [[[Int]]]()
    var allCellsValid = [[Bool]]()
    var cellIsValid = [[Bool]]()

    init(difficulty: Difficulty = .easy) {
        self.difficulty = difficulty

        create()
        prepareForPlay()
    }

    private mutating func create () {
        let numbers = Array(1...size).shuffled()
        let positions = [0, 3, 6, 1, 4, 7, 2, 5, 8]

        let rows = Array([[0, 1, 2].shuffled(), [3, 4, 5].shuffled(), [6, 7, 8].shuffled()].shuffled()).joined()
        let columns = Array([[0, 1, 2].shuffled(), [3, 4, 5].shuffled(), [6, 7, 8].shuffled()].shuffled()).joined()

        for row in rows {
            var newRow = [Int]()

            for column in columns {
                let position = (positions[row] + column) % size
                newRow.append(numbers[position])
            }

            solvedBoard.append(newRow)
            //            print(newRow)
        }

        cellHints = Array(repeating: Array(repeating: Array([Int]()), count: size), count: size)
        allCellsValid = Array(repeating: Array(repeating: true, count: size), count: size)
        cellIsValid = allCellsValid
    }

    private mutating func prepareForPlay() {
        let empties = difficulty.rawValue
        let allCells = 0..<Int(ceil(Double(size * size) / 2))

        startingBoard = solvedBoard

        for cell in allCells.shuffled().prefix(upTo: empties) {
            let row = cell / size
            let col = cell % size
            startingBoard[row][col] = 0
            startingBoard[8 - row][8 - col] = 0
        }

        playerBoard = startingBoard
    }

    mutating func validate() {
        cellIsValid = allCellsValid

        // For row and column validation, we simply compare each cell to its neighbors
        // to the right (for rows), or below (for columns).

        // Validate the rows
        for row in 0..<size {
            for col in 0..<size {
                if playerBoard[row][col] > 0 {
                    for nextCol in col + 1..<size {
                        if playerBoard[row][col] == playerBoard[row][nextCol] {
                            cellIsValid[row][col] = false
                            cellIsValid[row][nextCol] = false
                        }
                    }
                }
            }
//            print("Row \(row): \(cellIsValid[row])")
        }

        // Validate the columns
        for col in 0..<size {
            for row in 0..<size {
                 if playerBoard[row][col] > 0 {
                    for nextRow in row + 1..<size {
                        if playerBoard[row][col] == playerBoard[nextRow][col] {
                            cellIsValid[row][col] = false
                            cellIsValid[nextRow][col] = false
                        }
                    }
                }
//                print("Column \(col): \(cellIsValid[row][col])")
            }
        }

        // Validate the squares (harder than you think) :-)
        for row in stride(from: 0, through: 6, by: 3) {
            for col in stride(from: 0, through: 6, by: 3) {
                // Every time through the inner loop, [row][col] points to the upper left cell of a 3 x 3 square.
                // We will now turn this 3 x 3 grid into a 1D array for ease of validation.
                var squareArray = Array(repeating: 0, count: 9)
                var squareArrayIndex = 0
                for rowOffset in 0...2 {
                    for colOffset in 0...2 {
                        squareArray[squareArrayIndex] = playerBoard[row + rowOffset][col + colOffset]
                        squareArrayIndex += 1
                    }
                }

                // At this point, squareArray has the 3 x 3 grid being tested mapped onto a 1D array. We can now validate using
                // the same logic as if we were validating a row. The tricky bit is mapping the invalid cells in squareArray
                // back onto the cellIsValid array (whose layout mirrors the game board).
                for cell in 0..<size {
                    if squareArray[cell] > 0 {
                        for nextCell in cell + 1..<size {
                            if squareArray[cell] == squareArray[nextCell] {
                                let rowOffset = cell / 3
                                let colOffset = cell % 3
                                let nextRowOffset = nextCell / 3
                                let nextColOffset = nextCell % 3
                                cellIsValid[row + rowOffset][col + colOffset] = false
                                cellIsValid[row + nextRowOffset][col + nextColOffset] = false
                            }
                        }
                    }
                }
//                print(squareAsRow)
            }
//            print("Row \(row): \(cellIsValid[row])")
//            print("Row \(row + 1): \(cellIsValid[row + 1])")
//            print("Row \(row + 2): \(cellIsValid[row + 2])")
        }
    }
}
