//
//  BirthdayLayoutTests.swift
//  NanitTakeHomeTests
//
//  Created by Daniel Rodriguez on 11/8/26.
//
import Foundation
import Testing
@testable import NanitTakeHome

/// `Birthday` stores calendar fields rather than an instant (see its doc
/// comment). These tests prove that converting to a `Date` and back gives the
/// same day, including in time zones where that's easy to get wrong.
@MainActor
struct BirthdayTests {
    /// A Gregorian calendar fixed to the given time zone. Tests never use
    /// `Calendar.current`, because that changes with the machine running them.
    private func calendar(_ identifier: String) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: identifier)!
        return calendar
    }

    @Test func roundTripsThroughDate() {
        let cal = calendar("America/New_York")
        let birthday = Birthday(year: 2025, month: 3, day: 10)
        #expect(Birthday(date: birthday.date(in: cal), calendar: cal) == birthday)
    }

    /// Far from UTC on both sides of the date line, the day must still
    /// survive a round trip.
    @Test(arguments: ["Pacific/Kiritimati", "Pacific/Pago_Pago", "UTC"])
    func roundTripsInExtremeTimeZones(identifier: String) {
        let cal = calendar(identifier)
        let birthday = Birthday(year: 2024, month: 12, day: 31)
        #expect(Birthday(date: birthday.date(in: cal), calendar: cal) == birthday)
    }

    /// Brazil (before 2019) started daylight saving *at midnight*, so
    /// 2018-11-04 00:00 didn't exist in São Paulo. Using noon (see
    /// `date(in:)`) keeps us on the right day.
    @Test func survivesMidnightDaylightSavingJump() {
        let cal = calendar("America/Sao_Paulo")
        let birthday = Birthday(year: 2018, month: 11, day: 4)
        #expect(Birthday(date: birthday.date(in: cal), calendar: cal) == birthday)
    }
}
