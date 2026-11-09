//
//  BirthdayLayout.swift
//  NanitTakeHome
//
//  Created by Daniel Rodriguez on 11/8/26.
//
import SwiftUI

/// Every measurement on the birthday screen, in one place.
nonisolated enum BirthdayMetrics {
    
    // MARK: Age text (top section)

    static let topMinGap: CGFloat = 20
    static let ageToCircleMinGap: CGFloat = 20
    static let titleToNumberGap: CGFloat = 13
    static let numberToUnitGap: CGFloat = 14
    static let swirlToNumberGap: CGFloat = 22
    static let titleWidth: CGFloat = 252
    static let titleLineHeight: CGFloat = 29
    static let titleFontSize: CGFloat = 21
    static let unitFontSize: CGFloat = 18
    static let titleMinSideMargin: CGFloat = 20

    // MARK: Baby circle & Camera

    static let circleSideMinGap: CGFloat = 50
    static let circleDesignDiameter: CGFloat = 228
    static let circleMinDiameter: CGFloat = 120
    static let ringArtworkDiameter: CGFloat = 207
    static let ringArtworkWidth: CGFloat = 7
    static let cameraIconSize: CGFloat = 36
    static let cameraAngleDegrees: Double = 45

    // MARK: Bottom section (pinned to the bottom edge)

    static let circleToLogoGap: CGFloat = 15
    static let logoToShareGap: CGFloat = 53
    static let shareBottomGap: CGFloat = 53
    static let shareButtonSize = CGSize(width: 179, height: 42)
}

/// Spec 3: positions the four pieces of the birthday screen that follow the
/// design's spacing rules: the age text, the baby circle, the logo and the
/// share button.
///
/// ## The positioning rules, from the figma
///
/// 1. "Pin baby image, nanit logo and share button to bottom edge." So the
///    layout is built **from the bottom up**: share button 53pt above the
///    bottom, logo 53pt above that, circle 15pt above the logo.
/// 2. "Center age text section vertically in the space between status bar
///    and the baby image circle." Whatever room is left at the top is
///    shared equally above and below the age text.
/// 3. Minimum gaps (20pt above the text, 20pt below it, 50pt beside the
///    circle). On a screen too short for all of them, something has to
///    give, and that's the circle's size.
///
/// ## Why a custom `Layout`
///
/// These rules are *relationships*, not fixed positions. A `VStack` with
/// spacers can't say "stack these from the bottom, then center that text in
/// whatever is left". SwiftUI's `Layout` protocol lets us measure the pieces
/// and place them by hand, and the math lives in a pure function
/// (`frames(for:)`) that unit tests can check without drawing anything.
///
struct BirthdayLayout: Layout {
    var topInset: CGFloat
    var bottomInset: CGFloat

    /// The layout fills whatever space it's offered.
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        proposal.replacingUnspecifiedDimensions()
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard subviews.count == 4 else {
            assertionFailure("BirthdayLayout expects 4 subviews: age text, circle, logo, share button")
            return
        }
        let ageText = subviews[0], circle = subviews[1], logo = subviews[2], share = subviews[3]

        // Measure the pieces whose size the content decides. The age text
        // gets the width it may use and picks its own height, which is
        // larger when the name wraps onto two lines.
        let textWidth = min(
            BirthdayMetrics.titleWidth,
            max(0, bounds.width - 2 * BirthdayMetrics.titleMinSideMargin)
        )
        let input = Input(
            size: bounds.size,
            topInset: topInset,
            bottomInset: bottomInset,
            ageTextSize: ageText.sizeThatFits(ProposedViewSize(width: textWidth, height: nil)),
            logoSize: logo.sizeThatFits(.unspecified)
        )
        let frames = Self.frames(for: input)

        // `frames` are relative to the layout's own origin, so offset them
        // by `bounds.origin` when placing. Each view is proposed exactly its
        // frame's size, so the circle draws at the computed diameter and the
        // share pill fills its 179 × 42pt slot.
        func place(_ view: LayoutSubview, in frame: CGRect) {
            view.place(
                at: CGPoint(x: bounds.minX + frame.midX, y: bounds.minY + frame.midY),
                anchor: .center,
                proposal: ProposedViewSize(frame.size)
            )
        }
        place(ageText, in: frames.ageText)
        place(circle, in: frames.circle)
        place(logo, in: frames.logo)
        place(share, in: frames.shareButton)
    }

    // MARK: - The math (pure, unit tested)

    /// Bit of trig to put the camera at 45deg from the top of the circle.
    ///
    /// More specifically, from the circle's center:
    /// - x = center + r · cos(45°), moving right;
    /// - y = center − r · sin(45°), moving *up*. Screen y grows downward,
    ///   hence the minus sign.
    ///
    static func cameraCenter(circleDiameter diameter: CGFloat) -> CGPoint {
        let ringMidRadius = diameter / 2 - ringWidth(circleDiameter: diameter) / 2
        let angle = BirthdayMetrics.cameraAngleDegrees * .pi / 180
        return CGPoint(
            x: diameter / 2 + ringMidRadius * cos(angle),
            y: diameter / 2 - ringMidRadius * sin(angle)
        )
    }

    /// The colored ring's on-screen width at a given circle size. The ring
    /// artwork scales with the circle, so its stroke does too.
    static func ringWidth(circleDiameter diameter: CGFloat) -> CGFloat {
        BirthdayMetrics.ringArtworkWidth * diameter / BirthdayMetrics.ringArtworkDiameter
    }

    /// What the layout needs to know. It's a plain struct, so tests can make
    /// one for any screen size.
    struct Input: Equatable {
        var size: CGSize
        var topInset: CGFloat
        var bottomInset: CGFloat
        var ageTextSize: CGSize
        var logoSize: CGSize
    }

    /// Where each piece goes, in the layout's own coordinates (y grows
    /// downward from the top of the screen).
    struct Frames: Equatable {
        var ageText: CGRect
        var circle: CGRect
        var logo: CGRect
        var shareButton: CGRect
    }

    static func frames(for input: Input) -> Frames {
        typealias M = BirthdayMetrics
        let width = input.size.width
        let height = input.size.height
        let ageHeight = input.ageTextSize.height
        let logoSize = input.logoSize

        // A helper: a rectangle of the given size, centered horizontally,
        // whose *bottom* edge is at `bottom`. Building from the bottom up,
        // every piece is placed by where its bottom goes.
        func centered(_ size: CGSize, bottom: CGFloat) -> CGRect {
            CGRect(x: (width - size.width) / 2, y: bottom - size.height, width: size.width, height: size.height)
        }

        // 1. Share button: 53pt above the bottom edge of the screen.
        //
        // The iOS frames are iPhone 8 size, where the screen's edge has
        // nothing on it. On Face ID iPhones the home indicator takes the
        // bottom 34pt. 53pt from the edge already clears it, so the redline
        // is measured from the screen's edge, as drawn. The `max` only
        // matters if a future device ever had an inset taller than 53pt.
        let shareBottom = height - max(M.shareBottomGap, input.bottomInset)
        let shareButton = centered(M.shareButtonSize, bottom: shareBottom)

        // 2. Logo: 53pt above the share button.
        let logo = centered(logoSize, bottom: shareButton.minY - M.logoToShareGap)

        // 3. Circle: 15pt above the logo. Its bottom edge is now fixed;
        // only its size is left to decide. It starts at the design size and
        // shrinks only when a minimum gap would otherwise break:
        let circleBottom = logo.minY - M.circleToLogoGap
        //
        //  • Sides: at least 50pt on each side, so a narrow screen caps it.
        let widthLimit = width - 2 * M.circleSideMinGap
        //
        //  • Height: the age text and its two 20pt minimum gaps must fit
        //    between the status bar and the circle's top. The circle's top
        //    is `circleBottom - diameter`, so the largest diameter allowed is:
        let lowestAllowedCircleTop = input.topInset + M.topMinGap + ageHeight + M.ageToCircleMinGap
        let heightLimit = circleBottom - lowestAllowedCircleTop
        //
        // `min` takes the tightest of the three limits, and `max` keeps it
        // from going below the readable minimum.
        let diameter = max(M.circleMinDiameter, min(M.circleDesignDiameter, widthLimit, heightLimit))
        let circle = centered(CGSize(width: diameter, height: diameter), bottom: circleBottom)

        // 4. Age text. Breakdown: "Center age text section vertically in the
        // space between status bar and the baby image circle."
        //
        // The ideal top puts the text's middle halfway between the status
        // bar's bottom and the circle's top. Then two clamps, so the minimum
        // gaps win if centering would break them:
        //  - `max`: no higher than 20pt below the status bar;
        //  - `min`: no lower than 20pt above the circle.
        // With a centered text both clamps are no-ops whenever the circle
        // didn't hit its minimum size. They only act on extreme screens.
        let idealAgeTop = (input.topInset + circle.minY) / 2 - ageHeight / 2
        let ageTop = min(
            max(idealAgeTop, input.topInset + M.topMinGap),
            circle.minY - M.ageToCircleMinGap - ageHeight
        )
        let ageText = CGRect(
            x: (width - input.ageTextSize.width) / 2,
            y: ageTop,
            width: input.ageTextSize.width,
            height: ageHeight
        )

        return Frames(ageText: ageText, circle: circle, logo: logo, shareButton: shareButton)
    }
}
