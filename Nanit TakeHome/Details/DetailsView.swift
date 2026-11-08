
//
//  DetailsView.swift
//  Nanit TakeHome
//
//  Created by Daniel Rodriguez on 11/7/26.
//
import Observation
import SwiftUI

// MARK: - DetailsModel

@MainActor
@Observable
final class DetailsModel {
    /// The name and birthday.
    ///
    /// Leverages `didSet` to save the profile.
    ///
    /// Note: `didSet` piping into `UserDefaults` without a debounce is OK in this case.
    /// A profile is a few bytes, and `UserDefaults` updates its in-memory copy right away
    /// and writes to disk asynchronously, so a save per keystroke never blocks typing.
    ///
    /// See the "Overview" in Apple's `UserDefaults` documentation.
    var profile: BabyProfile {
        didSet {
            store.saveProfile(profile)
        }
    }
    
    /// The baby's picture or `nil` to show the placeholder.
    fileprivate(set) var photo: UIImage?
    
    /// Where everything is saved.
    ///
    /// `@ObservationIgnored`: Store never changes, so there's nothing for SwiftUI to watch.
    @ObservationIgnored private let store: any ProfileStore

    /// `profile` defaults to `nil` rather than `.init()` because default arguments are evaluated
    /// in a nonisolated context, where the main actor-isolated `BabyProfile.init()` can't be called.
    init(
        store: any ProfileStore = DiskProfileStore()
    ) {
        self.store = store
        self.profile = store.loadProfile()
        self.photo = store.loadPhoto()
    }
    
    func setPhoto(_ image: UIImage) {
        let prepared = image.preparedForStorage()
    }
}

// MARK: - DetailsView

struct DetailsView: View {
    
    @Bindable var model: DetailsModel
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button {
                        // TBD
                    } label: {
                        ProfilePicture(photo: model.photo)
                    }
                    .buttonStyle(.plain) // `.plain` stops the Form from tinting the whole row like a link
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                }
                
                Section {
                    TextField("Name", text: $model.profile.name)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled() // avoid iOS fixing unusual names - gives parent full control!
                        .submitLabel(.done)
                    Button {
                        // TBD
                    } label: {
                        LabeledContent("Birthday") {
                            if let birthday = model.profile.birthday {
                                Text(Self.formatted(birthday))
                            } else {
                                Text("Add birthday").foregroundStyle(.secondary)
                            }
                        }
                    }
                    // Show the label in the normal text color, not link blue,
                    // so the row reads like the Name row above it.
                    .tint(.primary)
                }
                
                Section {
                    Button("Show birthday screen") {
                        // TBD
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(!model.profile.canShowBirthdayScreen)
                }
            }
        }
    }
    
    /// "Mar 10, 2025" in US English, "10 Mar 2025" in UK English and so on.
    /// `formatted(date:time:)` follows the user's locale automatically, which
    /// is better than a hard-coded format string.
    private static func formatted(_ birthday: Birthday) -> String {
        birthday.date().formatted(date: .abbreviated, time: .omitted)
    }
}

/// The picture at the top of the form: the chosen photo, or a placeholder.
private struct ProfilePicture: View {
    let photo: UIImage?

    /// Big enough to read as "the baby's picture" without dominating the form.
    private let diameter: CGFloat = 120

    var body: some View {
        Group {
            if let photo {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
            } else {
                Color(.secondarySystemFill)
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.system(size: diameter * 0.45))
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .frame(width: diameter, height: diameter)
        .clipShape(Circle())
        .overlay(alignment: .bottomTrailing) {
            Image(systemName: "camera.circle.fill")
                .font(.system(size: 32))
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, Color.accentColor)
        }
    }
}

// MARK: - Previews

#Preview("Empty profile") {
    DetailsView(model: DetailsModel())
}

#Preview("Filled profile") {
    DetailsView(model: DetailsModel(store: InMemoryProfileStore(profile: BabyProfile(
        name: "Anakin Skywalker",
        birthday: Birthday(year: 2025, month: 10, day: 1)
    ))))
}

