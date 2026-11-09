//
//  BabyAgeTests.swift
//  NanitTakeHomeTests
//
//  Created by Daniel Rodriguez on 11/8/26.
//
import Foundation
import Testing
@testable import NanitTakeHome

@MainActor
struct BabyAgeTests {
    /// UTC Gregorian calendar, so no daylight-saving shifts muddy the math.
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    /// A `Date` at an awkward time of day (23:30), to prove the time of day
    /// doesn't affect the answer.
    private func day(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 23, minute: 30))!
    }

    private func age(born birthday: Birthday, on today: Date) -> BabyAge {
        BabyAge(birthday: birthday, on: today, calendar: calendar)
    }

    // MARK: Months, under 1 year

    @Test func newbornIsZeroMonths() {
        let born = Birthday(year: 2026, month: 3, day: 10)
        #expect(age(born: born, on: day(2026, 3, 10)) == .months(0))
    }

    @Test func dayBeforeFirstMonthIsStillZero() {
        let born = Birthday(year: 2026, month: 3, day: 10)
        #expect(age(born: born, on: day(2026, 4, 9)) == .months(0))
    }

    @Test func oneMonthOnTheDay() {
        let born = Birthday(year: 2026, month: 3, day: 10)
        #expect(age(born: born, on: day(2026, 4, 10)) == .months(1))
    }

    @Test func elevenMonthsTheDayBeforeFirstBirthday() {
        let born = Birthday(year: 2025, month: 3, day: 10)
        #expect(age(born: born, on: day(2026, 3, 9)) == .months(11))
    }

    // MARK: Years, 1 and up

    @Test func oneYearOnFirstBirthday() {
        let born = Birthday(year: 2025, month: 3, day: 10)
        #expect(age(born: born, on: day(2026, 3, 10)) == .years(1))
    }

    /// 23 months is still "1 year": years are whole years, not rounded.
    @Test func yearsAreWholeYears() {
        let born = Birthday(year: 2024, month: 3, day: 10)
        #expect(age(born: born, on: day(2026, 3, 9)) == .years(1))
    }

    @Test func thirteenYears() {
        let born = Birthday(year: 2013, month: 1, day: 1)
        #expect(age(born: born, on: day(2026, 1, 1)) == .years(13))
    }

    // MARK: Calendar edge cases

    /// Born Jan 31: February has no 31st, so Calendar clamps to the end of
    /// the shorter month. The baby is 1 month old on Feb 28.
    @Test func monthEndBirthdayClampsToShorterMonth() {
        let born = Birthday(year: 2025, month: 1, day: 31)
        #expect(age(born: born, on: day(2025, 2, 27)) == .months(0))
        #expect(age(born: born, on: day(2025, 2, 28)) == .months(1))
    }

    /// Born Feb 29: in a non-leap year the first birthday falls on Feb 28,
    /// by the same end-of-month rule.
    @Test func leapDayBirthdayTurnsOneOnFebruary28() {
        let born = Birthday(year: 2024, month: 2, day: 29)
        #expect(age(born: born, on: day(2025, 2, 27)) == .months(11))
        #expect(age(born: born, on: day(2025, 2, 28)) == .years(1))
    }

    /// The picker blocks future dates, but the device clock can be changed.
    /// A future birthday shows 0, never a negative age.
    @Test func futureBirthdayClampsToZero() {
        let born = Birthday(year: 2027, month: 1, day: 1)
        #expect(age(born: born, on: day(2026, 1, 1)) == .months(0))
    }

    // MARK: Text

    /// Singular only for exactly one; zero is plural in English.
    @Test(arguments: [
        (BabyAge.months(0), "MONTHS OLD!"),
        (.months(1), "MONTH OLD!"),
        (.months(2), "MONTHS OLD!"),
        (.years(1), "YEAR OLD!"),
        (.years(2), "YEARS OLD!"),
    ])
    func unitText(age: BabyAge, expected: String) {
        #expect(age.unitText == expected)
    }
}

struct AgeNumberViewTests {
    @Test func usesWholeGlyphsUpToTwelve() {
        #expect(AgeNumberView.glyphNames(for: 0) == ["digit_0"])
        #expect(AgeNumberView.glyphNames(for: 10) == ["digit_10"])
        #expect(AgeNumberView.glyphNames(for: 12) == ["digit_12"])
    }

    @Test func composesDigitsFromThirteen() {
        #expect(AgeNumberView.glyphNames(for: 13) == ["digit_1", "digit_3"])
        #expect(AgeNumberView.glyphNames(for: 100) == ["digit_1", "digit_0", "digit_0"])
    }
}
