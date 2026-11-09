//
//  BabyProfileTests.swift
//  NanitTakeHomeTests
//
//  Created by Daniel Rodriguez on 11/8/26.
//
import Foundation
import Testing
@testable import NanitTakeHome

@MainActor
struct BabyProfileTests {
    private let someBirthday = Birthday(year: 2025, month: 3, day: 10)

    @Test func emptyProfileCannotShowBirthdayScreen() {
        #expect(BabyProfile().canShowBirthdayScreen == false)
    }

    @Test func nameAloneIsNotEnough() {
        let profile = BabyProfile(name: "Luke", birthday: nil)
        #expect(profile.canShowBirthdayScreen == false)
    }

    @Test func birthdayAloneIsNotEnough() {
        let profile = BabyProfile(name: "", birthday: someBirthday)
        #expect(profile.canShowBirthdayScreen == false)
    }

    /// A name made only of spaces would show "TODAY    IS" on the birthday
    /// screen, so it counts as empty.
    @Test func whitespaceOnlyNameCountsAsEmpty() {
        let profile = BabyProfile(name: "   \n", birthday: someBirthday)
        #expect(profile.canShowBirthdayScreen == false)
    }

    @Test func nameAndBirthdayEnableTheButton() {
        let profile = BabyProfile(name: "Luke", birthday: someBirthday)
        #expect(profile.canShowBirthdayScreen)
    }

    /// The displayed name drops surrounding spaces but keeps inner ones.
    @Test func displayNameIsTrimmed() {
        let profile = BabyProfile(name: "  Luke Skywalker  ")
        #expect(profile.displayName == "Luke Skywalker")
    }
}
