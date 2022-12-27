//
//  ContentView.swift
//  TapSudoku
//
//  Created by Jeff Fischer on 12/12/22.
//
//  Modified from code by Paul Hudson, Hacking With Swift, @twostraws.

/// As Paul alluded in his video on this project, his game board generator, while conceptually simple, all too often created boards with multiple valid solutions. He issued a challenge to create a board creation algorithm that would avoid this. The `Board.generateBoard()` method is my attempt at this. Unfortunately, experience has shown it is also not immune to the multiple valid solutions problem (but it seems to have reduced the symmetry--if that's an improvement). Therefore, I also changed the error indication logic, as follows.

/// To warn the user they may be heading down the path of an ultimately invalid solution (even though it is still currently valid), I added the concept of a "caution" color. The end game detector will allow a valid, alternate solution, but in order to avoid getting several moves into a potential alternate before discovering it will not be valid, we mark the numbers that don't match the original solved game with yellow (if Show Errors is on). True errors (i.e., row, column, or square duplicates) are still shown in red.

/// I've also added three new number states (in CellView), with appropriate colors. `isGiven` indicates that the number in this cell was part of the originally generated game board. The closure code passed to CellView is now conditional on isGiven being false (i.e., if true, nothing happens if you click on that cell). `isCorrect` indicates whether or not the number in this cell is a valid guess, based on the no duplicates rule. `isCaution` indicates whether the number in this cell differs from the number in this cell on the originally generated game board. "Caution," in the sense that this guess *may* be part of an alternate valid solution, but be careful entering more guesses based on this one--you're more likely headed for a breakdown than an alternate valid solution. I used the yellow color for this state, which means the currently-selected number is now white, like all the other entered numbers.

/// Finally, I added the ability to enter pre-guess hints for a cell. "Hint mode" is engaged when `isEnteringHints` is true. In addition to entering hints in the cell, it also changes the selected cell highlight color and the number pad color to indigo for extra visual indications that hint mode is on.

// TODO: Implement Undo logic to take back a guess.
// TODO: Create a "solver" algorithm to ensure unique solutions.

import SwiftUI

struct ContentView: View {
    @State private var board = Board(difficulty: .testing)
    let spacing = 1.5

    @State private var selectedRow = -1
    @State private var selectedCol = -1
    @State private var selectedNum = 0


    @State private var solved = false
    @State private var showingNewGame = false

    @State private var isEnteringHints = false

    // Paul's original code automatically highlighted errors as entered. I made it optional.
    @State private var isShowingErrors = false

    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Toggle("Show Errors", isOn: $isShowingErrors)
                        .tint(.red)
                        .padding()

                    Spacer()

                    Toggle("Enter Hints", isOn: $isEnteringHints)
                        .tint(.indigo)
                        .padding()
                }

                Grid(horizontalSpacing: 1, verticalSpacing: 1) {
                    ForEach(0..<9) { row in
                        GridRow {
                            ForEach(0..<9) { col in
                                CellView(
                                    number: board.playerBoard[row][col],
                                    selectedNumber: selectedNum,
                                    highlightState: highlightState(for: row, col: col),
                                    isGiven: board.startingBoard[row][col] > 0,
                                    isCorrect: isShowingErrors ? board.cellIsValid[row][col] : true,
                                    isCaution: isShowingErrors ? board.playerBoard[row][col] != board.solvedBoard[row][col] : false,
                                    hints: board.cellHints[row][col]
                                ) {
                                    if board.startingBoard[row][col] == 0 {
                                        selectedRow = row
                                        selectedCol = col
                                        selectedNum = board.playerBoard[row][col]
                                    }
                                }

                                if col == 2 || col == 5 {
                                    Spacer()
                                        .frame(width: spacing, height: 1)
                                }
                            }
                        }
                        .padding(.bottom, row == 2 || row == 5 ? spacing : 0)
                    }
                }
                .padding(5)

                HStack {
                    ForEach(1..<10) { i in
                        Button(String(i)) {
                            guard selectedRow > -1 && selectedCol > -1 else { return }

                            if isEnteringHints {
                                enterHint(i)
                            }
                            else {
                                enterGuess(i)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .font(.largeTitle)
                        .foregroundColor(isEnteringHints ? .indigo : .blue)
                        // Paul's original code eliminated a choice when all instances had been entered. I removed that behavior.
                        // This also made the whole counting of number choices unnecessary, so that code was simplified into the
                        // checkSolution() function below.
                        //                        .opacity(counts[i, default: 0] == 9 ? 0 : 1)
                    }
                }
                .padding()
            }
            .navigationTitle("Tap Sudoku")
            .toolbar {
                Button {
                    showingNewGame = true
                } label: {
                    Label("Start a new game", systemImage: "plus")
                }
            }
        }
        .preferredColorScheme(.dark)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .alert("Start a new game", isPresented: $showingNewGame) {
            ForEach(Board.Difficulty.allCases, id: \.self) { difficulty in
                Button(String(describing: difficulty).capitalized) {
                    newGame(difficulty: difficulty)
                }
            }

            Button("Cancel", role: .cancel) { }
        } message: {
            if solved {
                Text("You solved the board correctly - good job!")
            }
        }
        .onAppear(perform: checkSolution)
        .onChange(of: board) { _ in
            checkSolution()
        }
    }

    func highlightState(for row: Int, col: Int) -> CellView.HighlightState {
        if row == selectedRow {
            if col == selectedCol {
                return isEnteringHints ? .selectedHints : .selected
            }
            else {
                return .highlighted
            }
        }
        else if col == selectedCol {
            return .highlighted
        }
        else {
            return .standard
        }
    }

    func enterGuess(_ number: Int) {
        if board.playerBoard[selectedRow][selectedCol] == number {
            board.playerBoard[selectedRow][selectedCol] = 0
            selectedNum = 0
        }
        else {
            board.playerBoard[selectedRow][selectedCol] = number
            selectedNum = number
        }

        board.validate()
    }

    func enterHint(_ number: Int) {
        if board.cellHints[selectedRow][selectedCol].contains(number)  {
            board.cellHints[selectedRow][selectedCol].removeAll(where: { $0 == number })
        }
        else {
            board.cellHints[selectedRow][selectedCol].append(number)
        }
    }

    func newGame(difficulty: Board.Difficulty) {
        board = Board(difficulty: difficulty)
        selectedRow = -1
        selectedCol = -1
        selectedNum = 0
    }

    func checkSolution() {
        solved = false
        var guessCount = 0

        for row in 0..<board.size {
            for col in 0..<board.size {
                if board.playerBoard[row][col] > 0 {
                    guessCount += 1
                }
            }
        }

        if guessCount == board.size * board.size && board.cellIsValid == board.allCellsValid {
            Task {
                try await Task.sleep(for: .seconds(0.5))
                showingNewGame = true
                solved = true
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
