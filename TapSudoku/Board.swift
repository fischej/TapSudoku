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
        generateBoard()

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

    private mutating func generateBoard() {
        // So the basic idea here is first, set up an array of values 1...9 for every cell on the board (tryValues). Then,
        // go through every cell in the board, trying (and removing) a random integer from that cell's tryValues. If the
        // board is valid after that, move on to the next cell; if not, try another tryValues element. If we have exhausted
        // all elements in tryValues for this cell, reset the cell and its tryValues, and back up to the previous cell.
        // When we backtrack, we reset the new cell to zero, but *not* its tryValues. We first exhaust the remaining tryValues
        // (since we know the others were already tried and found invalid). And the logic repeats: if a valid number is found,
        // move on; if not, backtrack again.

#if DEBUG
        let startTime = Date()
#endif

        solvedBoard = Array(repeating: Array(repeating: 0, count: size), count: size)

        var targetRow = 0
        var targetCol = 0
        var foundValue = false
        var tryValues = Array(repeating: Array(repeating: Array(1...9), count: 9), count: 9)
        var tryValue: Int

        // Not sure how "Swifty" the following code is. Any suggestions for improvement welcomed.
        while targetRow < size {
            if solvedBoard[targetRow][targetCol] > 0 {
                print("Value \(solvedBoard[targetRow][targetCol]) found at row \(targetRow), col \(targetCol), moving on")
                targetCol += 1
                if targetCol > 8 {
                    targetCol = 0
                    targetRow += 1
                }
            }
            else {
                print("Working on row \(targetRow) col \(targetCol)")
                foundValue = false

                while tryValues[targetRow][targetCol].count > 0 {
                    tryValues[targetRow][targetCol].shuffle()
                    tryValue = tryValues[targetRow][targetCol].removeLast()
                    solvedBoard[targetRow][targetCol] = tryValue
                    if validate(board: solvedBoard) {
                        foundValue = true
                        printBoard(board: solvedBoard)
                        break
                    }
                }

                if foundValue == false {
                    print("No value found, backtracking")
                    tryValues[targetRow][targetCol] = Array(1...9)
                    solvedBoard[targetRow][targetCol] = 0
                    targetCol -= 1
                    if targetCol < 0 {
                        targetCol = 8
                        targetRow -= 1
                    }
                    solvedBoard[targetRow][targetCol] = 0
                }
            }
        }

#if DEBUG
        print("\n*** Elapsed time: \(Date().timeIntervalSince(startTime) * 1000)")
#endif

    }

    private func printBoard(board: [[Int]]) {
        print("")
        for row in 0...8 {
            print(board[row])
        }
    }

    mutating func validate() {
        // This validate function is used in-game. It keeps track of which cells are currently
        // invalid. Cells with a value of zero (i.e., not yet entered) are considered valid.

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
            }
        }
    }

    private func validate(board: [[Int]]) -> Bool {
        // This version of the validate function is used by the generate() function. It takes a board and determines
        // whether or not the entire board is valid, excepting cells that have not been entered yet (value = 0).

        // Validate the rows
        for row in 0..<size {
            for col in 0..<size {
                if board[row][col] > 0 {
                    for nextCol in col + 1..<size {
                        if board[row][col] == board[row][nextCol] {
                            return false
                        }
                    }
                }
            }
        }

        // Validate the columns
        for col in 0..<size {
            for row in 0..<size {
                if board[row][col] > 0 {
                    for nextRow in row + 1..<size {
                        if board[row][col] == board[nextRow][col] {
                            return false
                        }
                    }
                }
            }
        }

        // Validate the squares
        for row in stride(from: 0, through: 6, by: 3) {
            for col in stride(from: 0, through: 6, by: 3) {
                var squareArray = Array(repeating: 0, count: 9)
                var squareArrayIndex = 0
                for rowOffset in 0...2 {
                    for colOffset in 0...2 {
                        squareArray[squareArrayIndex] = board[row + rowOffset][col + colOffset]
                        squareArrayIndex += 1
                    }
                }

                for cell in 0..<size {
                    if squareArray[cell] > 0 {
                        for nextCell in cell + 1..<size {
                            if squareArray[cell] == squareArray[nextCell] {
                                return false
                            }
                        }
                    }
                }
            }
        }

        return true
    }
}
