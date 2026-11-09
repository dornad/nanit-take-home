
//
//  BirthdayTheme.swift
//  NanitTakeHome
//
//  Created by Daniel Rodriguez on 11/8/26.
//

import SwiftUI

/// The birthday screen has 3 visual options. One should be chosen randomly every time you enter the screen."
///
/// Each theme is a matching set of
/// - background color,
/// - illustration
/// - circle artwork
///
/// taken from the three Figma iOS frames (fox, elephant,
enum BirthdayTheme: String, CaseIterable, Identifiable, Sendable {
    case fox
    case elephant
    case pelican

    var id: Self { self }

    /// A random theme for one visit to the birthday screen.
    static func random() -> BirthdayTheme {
        allCases.randomElement()!
    }

    /// The flat color under the background illustration.
    ///
    var backgroundColor: Color {
        // TODO: Move this into Asset
        switch self {
        case .fox: Color(hex: 0xC5E8DF)
        case .elephant: Color(hex: 0xFEEFCB)
        case .pelican: Color(hex: 0xDAF1F6)
        }
    }

    var backgroundImageName: String {
        "bg_\(rawValue)"
    }

    var circleImageName: String {
        switch self {
        case .fox: "ring_green"
        case .elephant: "ring_yellow"
        case .pelican: "ring_blue"
        }
    }

    var cameraImageName: String {
        switch self {
        case .fox: "camera_green"
        case .elephant: "camera_yellow"
        case .pelican: "camera_blue"
        }
    }
}

extension Color {
    /// The navy used for all birthday-screen text. It's read from the Figma
    /// SVGs (the swirls, the logo and the back arrow use `#394562`), so it's
    /// exact rather than sampled.
    static let birthdayText = Color(hex: 0x394562)

    /// Spec 5a: the "Share the news" pill's coral fill, sampled from the
    /// Figma iOS frames. It's the same in all three themes.
    static let shareButton = Color(hex: 0xEF7B7B)

    /// Builds a color from a hex literal like `0x394562`, so values can be
    /// copied straight from a design file. The parts are pulled out with bit
    /// shifts: red is the top byte, then green, then blue.
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
