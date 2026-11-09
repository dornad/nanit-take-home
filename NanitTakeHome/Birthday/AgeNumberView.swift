//
//  AgeNumberView.swift
//  NanitTakeHome
//
//  Created by Daniel Rodriguez on 11/8/26.
//
import SwiftUI

/// The big age number, drawn with the design's digit artwork rather than a font.
///
/// The Figma provides 0 to 9 plus whole `10`, `11` and `12` glyphs. Those
/// three are drawn as single pieces, with tighter, hand-tuned spacing than
/// two separate digits would have, so they're used as-is.
///
/// From 13 up there's no artwork, so the number is composed from single digits.
struct AgeNumberView: View {
    let number: Int

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(Self.glyphNames(for: number).enumerated()), id: \.offset) { _, name in
                Image(name)
            }
        }
    }

    /// Which digit images spell `number`. It's pure logic, so it's tested
    /// directly.
    ///
    /// - 0...12: one image each, including the whole `10`, `11`, `12` glyphs.
    /// - 13 and up: one image per digit, e.g. 13 → `digit_1`, `digit_3`.
    nonisolated static func glyphNames(for number: Int) -> [String] {
        let number = max(0, number)
        if number <= 12 {
            return ["digit_\(number)"]
        }
        // `String(number)` gives the decimal digits in order: "13" → "1", "3".
        return String(number).map { "digit_\($0)" }
    }
}

#Preview {
    VStack(spacing: 20) {
        AgeNumberView(number: 1)
        AgeNumberView(number: 11)
        AgeNumberView(number: 13)
    }
}
