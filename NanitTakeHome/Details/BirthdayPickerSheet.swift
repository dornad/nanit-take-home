//
//  BirthdayPickerSheet.swift
//  NanitTakeHome
//
//  Created by Daniel Rodriguez on 11/7/26.
//
import SwiftUI

/// Birthday DatePicker
///
/// ## Why a sheet instead of an inline `DatePicker`
///
/// SwiftUI's `DatePicker` always holds *some* date, because its binding is a
/// non-optional `Date`. But the Spec requires a real "no birthday yet" state to
/// keep the button disabled.
///
/// With an inline picker, the row would show today's date before the user had chosen anything,
/// which looks like a birthday was set when it wasn't.
///
/// So the details row shows "Add birthday" until a date is chosen, and tapping it opens this sheet.
/// The picker lives here, starting at today, and the choice only counts when the user taps Done.
struct BirthdayPickerSheet: View {
    /// What to start the picker on: the current birthday, or nil for none.
    let initial: Birthday?
    /// Called with the chosen birthday on Done, or with nil on Remove.
    let onSave: (Birthday?) -> Void

    @Environment(\.dismiss) private var dismiss

    /// The picker's working value. It's separate from the saved birthday, so `Cancel` can throw it away.
    @State private var date: Date

    init(initial: Birthday?, onSave: @escaping (Birthday?) -> Void) {
        self.initial = initial
        self.onSave = onSave
        self._date = State(initialValue: initial?.date() ?? .now)
    }

    var body: some View {
        NavigationStack {
            Form {
                DatePicker(
                    "Birthday",
                    selection: $date,
                    in: ...Date.now, // prevents future dates: a baby can't be born tomorrow.
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)

                // Lets the user go back to "no birthday".
                if initial != nil {
                    Section {
                        Button("Remove Birthday", role: .destructive) {
                            onSave(nil)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("Birthday")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onSave(Birthday(date: date))
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    BirthdayPickerSheet(initial: nil) { _ in }
}
