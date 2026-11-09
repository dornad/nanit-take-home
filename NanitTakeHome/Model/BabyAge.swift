//
//  BabyAge.swift
//  NanitTakeHome
//
//  Created by Daniel Rodriguez on 11/8/26.
//
import Foundation

/// `BabyAge`
///
/// The age is a "pure" value: given it a birthday and a "today", and it always
/// gives the same answer. There's no `Date.now` inside, which is what makes
/// it testable and reproducible on Previews.
///
/// This way we can ask "what does the screen say on 2025-03-09 for a baby born on 2024-03-10?"
/// without waiting for that day to come.
enum BabyAge: Hashable, Sendable {
    /// Under 1 year: 0 to 11 months.
    case months(Int)
    /// 1 year and up.
    case years(Int)

    /// Works out the age on `today` for someone born on `birthday`.
    ///
    /// Both dates are reduced to the start of their day first, so the time
    /// of day `today` happens to have can't affect the answer.
    init(birthday: Birthday, on today: Date, calendar: Calendar = .current) {
        let birthDay = calendar.startOfDay(for: birthday.date(in: calendar))
        let todayDay = calendar.startOfDay(for: today)
        let wholeMonths = calendar.dateComponents([.month], from: birthDay, to: todayDay).month ?? 0

        // The date picker blocks future birthdays, but the device clock
        // can be changed. A negative age makes no sense, so clamp to 0.
        let months = max(0, wholeMonths)

        // Spec 3b: months until 1 year, then whole years.
        self = months < 12 ? .months(months) : .years(months / 12)
    }

    /// The number shown in the big digit artwork.
    var number: Int {
        switch self {
        case .months(let count), .years(let count): count
        }
    }

    /// The line under the number, matching the design's "MONTH OLD!".
    ///
    /// Singular only for exactly 1. English uses the plural for zero ("0
    /// months old"), so a newborn reads "0 MONTHS OLD!".
    var unitText: String {
        switch self {
        case .months(1): "MONTH OLD!"
        case .months: "MONTHS OLD!"
        case .years(1): "YEAR OLD!"
        case .years: "YEARS OLD!"
        }
    }
}
