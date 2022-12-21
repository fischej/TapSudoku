//
//  CellView.swift
//  TapSudoku
//
//  Created by Jeff Fischer on 12/13/22.
//

import SwiftUI

struct CellView: View {
    enum HighlightState {
        case standard, highlighted, selected, selectedHints

        var color: Color {
            switch self {
                case .standard:
                    return .squareStandard
                case .highlighted:
                    return .squareHighlighted
                case .selected:
                    return .squareSelected
                case .selectedHints:
                    return .squareSelectedHints
            }
        }
    }

    let number: Int
    let selectedNumber: Int
    let highlightState: HighlightState
    let isCorrect: Bool
    let hints: [Int]
    var onSelected: () -> Void

    var displayNumber: String {
        if number == 0 {
            return ""
        }
        else {
            return String(number)
        }
    }

    var foregroundColor: Color {
        if isCorrect {
            if number == selectedNumber {
                return .squareTextSame
            }
            else {
                return .squareTextCorrect
            }
        }
        else {
            return .squareTextWrong
        }
    }

    var body: some View {
        ZStack {
            Button(action: onSelected) {
                Text(displayNumber)
                    .font(.title)
                    .foregroundColor(foregroundColor)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(highlightState.color)
            }
            .buttonStyle(.plain)

            VStack {
                let hintStringArray = hints.map { String($0) }
                let hintString = hintStringArray.joined(separator: " ")

                Text(hintString)
                    .font(.caption2.width(.condensed).weight(.semibold))
                    .foregroundColor(.white)
                    .opacity(number == 0 ? 0.5 : 0)
                    .lineLimit(2)
                    .multilineTextAlignment(.trailing)
                    .padding(.horizontal, 3)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Spacer()
            }
        }
        .frame(maxWidth: 100, maxHeight: 100)
        .aspectRatio(1, contentMode: .fit)
        .accessibilityShowsLargeContentViewer()
    }
}

struct CellView_Previews: PreviewProvider {
    static var previews: some View {
        let hints = [1, 2, 3, 4, 5, 6, 7, 8, 9, 1, 2, 3, 4, 5, 6, 7]
        CellView(number: 0, selectedNumber: 1, highlightState: .standard, isCorrect: true, hints: hints) { }
    }
}
