//
//  BirthdayCardView.swift
//  NanitTakeHome
//
//  Created by Daniel Rodriguez on 11/8/26.
//
import SwiftUI

/// Birthday screen's artwork, drawn from plain values.
///
/// ## Why a separate "card" view?
///
/// This view knows nothing about models, navigation or saving. It turns a
/// name, an age, a photo and a theme into pixels.
///
/// This separation pays off twice:
///
/// - **Previews** can show any combination (long name, 11 months, no photo)
///   without setting up app state.
/// - **Sharing** (step 5) will render the same view off screen into an image.
///   Because nothing here depends on being on screen, the shared image
///   matches what the user sees.
///
/// The view fills the whole screen, including behind the status bar and
/// home indicator, so the parent passes in the safe-area insets it should
/// respect.
struct BirthdayCardView: View {
    let name: String
    let age: BabyAge
    let photo: UIImage?
    let theme: BirthdayTheme
    let safeAreaInsets: EdgeInsets

    var onClose: () -> Void = {}
    
    var onChangePhoto: (() -> Void)? = nil

    var body: some View {
        ZStack {
            BackgroundView(theme: theme)

            BirthdayLayout(topInset: safeAreaInsets.top, bottomInset: safeAreaInsets.bottom) {
                AgeTextView(name: name, age: age)
                BabyCircleView(
                    photo: photo,
                    theme: theme,
                    onCameraTap: onChangePhoto
                )
                
                Image("logo_nanit")
                
                ShareButton()
            }
        }
        .overlay(alignment: .topLeading) {
            BackButton(action: onClose)
                .padding(.top, safeAreaInsets.top + BackButton.topOffset)
                .padding(.leading, max(safeAreaInsets.leading, BackButton.leadingOffset))
        }
        .ignoresSafeArea()
    }
}

// MARK: - BackgroundView

private struct BackgroundView: View {
    let theme: BirthdayTheme

    var body: some View {
        theme.backgroundColor
            .overlay {
                Image(theme.backgroundImageName)
                    .resizable()
                    .scaledToFill()
            }
            .clipped()
    }
}

// MARK: - AgeTextView

/// "TODAY <NAME> IS", the number with its swirls, and "MONTH OLD!".
private struct AgeTextView: View {
    let name: String
    let age: BabyAge

    /// Extra space between title lines, so each line is the design's 29pt.
    /// `UIFont.lineHeight` is the font's natural line height at this size
    /// (about 25pt for the 21pt system font).
    static let titleLineSpacing: CGFloat = max(
        0,
        BirthdayMetrics.titleLineHeight
            - UIFont.systemFont(ofSize: BirthdayMetrics.titleFontSize, weight: .medium).lineHeight
    )

    var body: some View {
        VStack(spacing: 0) {
            Text("TODAY \(name.localizedUppercase) IS")
                .font(.system(size: BirthdayMetrics.titleFontSize, weight: .medium))
                .lineSpacing(Self.titleLineSpacing)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.5)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: BirthdayMetrics.titleWidth)

            // The number, flanked by the swirls. Figma: 22pt each side.
            HStack(spacing: BirthdayMetrics.swirlToNumberGap) {
                Image("swirl_left")
                AgeNumberView(number: age.number)
                Image("swirl_right")
            }
            .padding(.top, BirthdayMetrics.titleToNumberGap)
            .padding(.bottom, BirthdayMetrics.numberToUnitGap)

            Text(age.unitText)
                .font(.system(size: BirthdayMetrics.unitFontSize, weight: .medium))
        }
        .foregroundStyle(Color.birthdayText)
    }
}

// MARK: - BabyCircleView

private struct BabyCircleView: View {
    let photo: UIImage?
    let theme: BirthdayTheme
    let onCameraTap: (() -> Void)?

    var body: some View {
        GeometryReader { proxy in
            let diameter = min(proxy.size.width, proxy.size.height)
            let ringInset = BirthdayLayout.ringWidth(circleDiameter: diameter)

            ZStack {
                Image(theme.circleImageName)
                    .resizable()
                    .scaledToFit()

                if let photo {
                    Image(uiImage: photo)
                        .resizable()
                        .scaledToFill()
                        .frame(width: diameter - 2 * ringInset, height: diameter - 2 * ringInset)
                        .clipShape(Circle())
                }
            }
            .frame(width: diameter, height: diameter)
            .overlay(alignment: .topLeading) {
                if let onCameraTap {
                    CameraButton(theme: theme, action: onCameraTap)
                        .position(BirthdayLayout.cameraCenter(circleDiameter: diameter))
                }
            }
        }
    }
}

// MARK: - CameraButton

private struct CameraButton: View {
    let theme: BirthdayTheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(theme.cameraImageName)
                .resizable()
                .frame(width: BirthdayMetrics.cameraIconSize, height: BirthdayMetrics.cameraIconSize)
                // The icon is 36pt, below Apple's recommended 44pt minimum comfortable tap target.
                .frame(width: 44, height: 44)
                .contentShape(Circle())
        }
    }
}

// MARK: - BackButton

private struct BackButton: View {
    let action: () -> Void

    /// Where the 44pt tap area sits, measured from the breakdown image (no
    /// redline gives these). The arrow's center there is about 28pt from
    /// the left edge and 28.5pt below the status bar, level with the
    /// title's first line. A 44pt box has its center 22pt in, so:
    /// - leading: 28 − 22 = 6pt;
    /// - top: 28.5 − 22 ≈ 6pt below the status bar.
    static let leadingOffset: CGFloat = 6
    static let topOffset: CGFloat = 6

    var body: some View {
        Button(action: action) {
            Image("ic_back")
                // 44 × 44pt is Apple's minimum comfortable tap target
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
    }
}

// MARK: - ShareButton

private struct ShareButton: View {
    var body: some View {
        Button(action: { /* TBD */ }) {
            HStack(spacing: 7) {
                Text("Share the news")
                    .font(.system(size: 17))
                Image("ic_share")
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Capsule().fill(Color.shareButton))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews

private let previewInsets = EdgeInsets(top: 62, leading: 0, bottom: 34, trailing: 0)

#Preview("Fox · 1 month · iOS frame size", traits: .fixedLayout(width: 375, height: 667)) {
    BirthdayCardView(
        name: "Anakin Skywalker", age: .months(1), photo: nil, theme: .fox,
        safeAreaInsets: EdgeInsets(top: 20, leading: 0, bottom: 0, trailing: 0)
    )
}

#Preview("Elephant · 11 months") {
    BirthdayCardView(
        name: "Dan", age: .months(11), photo: nil, theme: .elephant,
        safeAreaInsets: previewInsets
    )
}

#Preview("Pelican · 13 years, long name") {
    BirthdayCardView(
        name: "The Greatest Lorem Ipsum", age: .years(13), photo: nil, theme: .pelican,
        safeAreaInsets: previewInsets
    )
}
