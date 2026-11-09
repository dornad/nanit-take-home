//
//  BirthdayLayoutTests.swift
//  NanitTakeHomeTests
//
//  Created by Daniel Rodriguez on 11/8/26.
//
import Testing
import UIKit
@testable import NanitTakeHome

///
struct BirthdayLayoutTests {
    typealias M = BirthdayMetrics

    /// Spec 4a: the camera icon's center is on the ring's middle line, at 45°
    /// (top-right), at the design size and when the circle shrinks.
    @Test(arguments: [M.circleDesignDiameter, 150])
    func cameraSitsOnRingAt45Degrees(diameter: CGFloat) {
        let center = BirthdayLayout.cameraCenter(circleDiameter: diameter)
        let dx = center.x - diameter / 2
        let dy = diameter / 2 - center.y // flipped: positive means "up"
        let ringMidRadius = diameter / 2 - BirthdayLayout.ringWidth(circleDiameter: diameter) / 2

        #expect(abs(hypot(dx, dy) - ringMidRadius) < 0.01)
        #expect(abs(dx - dy) < 0.01) // equal x and y offsets means 45°
        #expect(dx > 0 && dy > 0)    // top-right quadrant
    }
}

@MainActor
struct BirthdayThemeTests {
    @Test(arguments: BirthdayTheme.allCases)
    func assetsExist(theme: BirthdayTheme) {
        #expect(UIImage(named: theme.backgroundImageName) != nil)
        #expect(UIImage(named: theme.circleImageName) != nil)
        #expect(UIImage(named: theme.cameraImageName) != nil)
    }

    /// The iOS icons: the back arrow and the share pill's arrow.
    @Test func iconArtworkExists() {
        #expect(UIImage(named: "ic_back") != nil)
        #expect(UIImage(named: "ic_share") != nil)
    }

    @Test func thereAreThreeThemes() {
        #expect(BirthdayTheme.allCases.count == 3)
    }

    @Test(arguments: 0...12)
    func digitArtworkExists(number: Int) {
        #expect(UIImage(named: "digit_\(number)") != nil)
    }
}
