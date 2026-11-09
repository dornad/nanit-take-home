//
//  BirthdaySnapshot.swift
//  NanitTakeHome
//
//  Created by Daniel Rodriguez on 11/9/26.
//
import SwiftUI
import UIKit

/// Our screenshot renderer for sharing
///
/// Rather than screenshoting the current screen and trying to erase buttons for it, we can leverage
/// SwiftUI's `ImageRenderer` which draws a SwiftUI `View` straight into an `UIImage` without
/// ever putting it on the screen.
///
/// This works well because I made the decision to separate the Card itself from
/// the Screen (`BirthdayCardView != BirthdayScreen`) where `BirthdayCardView` is
/// state driven.   The elements that should not be visible are driven by `BirthdayCardView.isChromeVisible`
/// which means that the shared snapshot lacks back button, camera and share button.
///
@MainActor
enum BirthdaySnapshot {
    static func render(
        name: String,
        age: BabyAge,
        photo: UIImage?,
        theme: BirthdayTheme,
        size: CGSize,
        safeAreaInsets: EdgeInsets,
        scale: CGFloat
    ) -> UIImage? {
        let card = BirthdayCardView(
            name: name,
            age: age,
            photo: photo,
            theme: theme,
            safeAreaInsets: safeAreaInsets,
            isChromeVisible: false
        )
        .frame(width: size.width, height: size.height)
        .environment(\.colorScheme, .light)
        
        let renderer = ImageRenderer(content: card)
        renderer.scale = scale
        renderer.isOpaque = true
        return renderer.uiImage
    }
}

/// Leverage `UIKit` to perform the share action
///
/// Presents the system's share sheet (`UIActivityViewController`) for the given
/// item(s)
///
/// ## Why `UIKit` and not `ShareLink`
///
/// SwiftUI's `ShareLink` needs its item ready *before* the button is tapped, which
/// which would mean re-rendering the share image every time anything on the screen
/// changes.  To render only once, on tap we can leverage UIKit's share sheet which does
/// the expensive work only when the user actually shares.
@MainActor
enum ShareSheet {
    static func present(items: [Any]) {
        // Find the view controller currently on top for `UIActivityViewController`.
        // for this app it is the full-screen birthday cover, so the share sheet
        // will appear over it.
        guard
            let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }),
            let root = scene.keyWindow?.rootViewController
        else { return }
        
        var top = root
        while let presented = top.presentedViewController {
            top = presented
        }
        
        let activity = UIActivityViewController(activityItems: items, applicationActivities: nil)
        // Bit of insurance if the app is ever ran on iPad (iPad uses popovers and it
        // requires an anchor.  Not having such an anchor causes a crash).
        // The app is iPhone only, but again, I've had this exact issue before.
        activity.popoverPresentationController?.sourceView = top.view
        top.present(activity, animated: true)
    }
}

