//
//  BirthdayScreen.swift
//  NanitTakeHome
//
//  Created by Daniel Rodriguez on 11/8/26.
//
import SwiftUI

/// BirthdayScreen connects the card artwork to the app's data and navigation.
struct BirthdayScreen: View {
    let model: DetailsModel
    let theme: BirthdayTheme

    @Environment(\.dismiss) private var dismiss
    
    private var age: BabyAge {
        guard let birthday = model.profile.birthday else { return .months(0) }
        return BabyAge(birthday: birthday, on: .now)
    }

    var body: some View {
        GeometryReader { proxy in
            BirthdayCardView(
                name: model.profile.displayName,
                age: age,
                photo: model.photo,
                theme: theme,
                safeAreaInsets: proxy.safeAreaInsets,
                onClose: { dismiss() },
            )
        }
        // Force the design to show in Light mode, otherwise the system's
        // status bar would otherwise turn white and disappear against
        // against the pastel colors.
        .preferredColorScheme(.light)   
        // Note: Step 4 will add photo change in here
    }
}
