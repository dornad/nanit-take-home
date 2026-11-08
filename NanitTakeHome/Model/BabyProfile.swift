//
//  BabyProfile.swift
//  Nanit TakeHome
//
//  Created by Daniel Rodriguez on 11/7/26.
//
import Foundation

// MARK: - Baby Profile

/// Everything the user tells us about the baby: the data behind both screens.
///
/// Note that the picture isn't stored here. Image data is large, so it will gets its own
/// file on disk from step 2 on, rather than living inside this small record.
struct BabyProfile: Hashable, Sendable {
    /// What the user typed, kept exactly as entered.
    ///
    /// Avoid trim while the user types, because removing a space they just typed would
    /// make the textfield fight them.
    ///
    /// Use `displayName` when showing the name.
    var name: String = ""

    /// `nil` until the user picks a date. "No birthday yet" is a real state from the PDF spec.
    var birthday: Birthday?

    /// The name with surrounding whitespace removed, which is what the screens
    /// should show.
    var displayName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// The "Show birthday screen" button is disabled while the name or the birthday is empty.
    ///
    /// The rule lives on the model, not in the view, so any unit test can check it without rendering any UI.
    ///
    /// A name of only spaces counts as empty. Otherwise the birthday screen
    /// would say "TODAY    IS", which is obviously incorrect.
    var canShowBirthdayScreen: Bool {
        !displayName.isEmpty && birthday != nil
    }
}

// MARK: - Birthday

/// A calendar date of birth: a year, a month and a day, with no time of day.
///
/// ## Why not just a `Date` object
///
/// A `Date` is an *instant*, a point on the global timeline. A birthday isn't an instant;
/// it's a day on the calendar. For example, if we stored the instant "2025-03-10 00:00 in New York",
/// that same instant is March 9 in Los Angeles, so a parent who travels would see the baby's birthday
/// move by a day.  This is a very subtle bug.
struct Birthday: Codable, Hashable, Sendable {
    let year: Int
    let month: Int
    let day: Int

    init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    /// Captures the calendar day that `date` falls on in `calendar`'s timezone
    init(date: Date, calendar: Calendar = .current) {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        // `dateComponents` always fills in the components we ask for, so the force-unwraps can't fail here.
        self.init(year: parts.year!, month: parts.month!, day: parts.day!)
    }

    /// Converts the birthday back into a `Date`, at **noon** on that day in
    /// `calendar`'s time zone.
    ///
    /// ## Noon vs Midnight
    ///
    /// Why noon and not midnight? Some time zones jump their clocks for
    /// daylight saving *at* midnight (historically Brazil, for example).
    ///
    /// On those days, 00:00 doesn't exist, and asking for it gives you a time on
    /// a different day. Noon always exists, so it's the safe hour to represent a whole day.
    func date(in calendar: Calendar = .current) -> Date {
        let parts = DateComponents(year: year, month: month, day: day, hour: 12)
        // Returns nil only for impossible dates (month 13, February 30), which
        // `init(date:)` can never produce.
        //
        // A crash here would mean a programming error, hence a precondition.
        guard let date = calendar.date(from: parts) else {
            preconditionFailure("Invalid birthday \(year)-\(month)-\(day)")
        }
        return date
    }
}
