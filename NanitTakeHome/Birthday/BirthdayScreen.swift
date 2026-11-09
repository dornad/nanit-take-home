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
    
    /// Pixels per point on this screen, so the shared image is as sharp as the screen.
    @Environment(\.displayScale) private var displayScale
    
    @State private var isChoosingPhoto = false
    
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
                onChangePhoto: { isChoosingPhoto = true },
                onShare: { share(in: proxy) }
            )
        }
        .photoSourcePicker(isPresented: $isChoosingPhoto){ image in
            model.setPhoto(image)
        }
        // Force the design to show in Light mode, otherwise the system's
        // status bar would otherwise turn white and disappear against
        // against the pastel colors.
        .preferredColorScheme(.light)
    }
    
    private func share(in proxy: GeometryProxy) {
        let insets = proxy.safeAreaInsets
        // adding insets in order to get the image sized to the full screen
        let fullSize = CGSize(
            width: proxy.size.width + insets.leading + insets.trailing,
            height: proxy.size.height + insets.top + insets.bottom)
        guard let image = BirthdaySnapshot.render(
            name: model.profile.name,
            age: age,
            photo: model.photo,
            theme: theme,
            size: fullSize,
            safeAreaInsets: insets,
            scale: displayScale
        ) else { return }
        ShareSheet.present(items: [image])
    }
}
