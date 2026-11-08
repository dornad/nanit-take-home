
//
//  ProfileStore.swift
//  Nanit TakeHome
//
//  Created by Daniel Rodriguez on 11/7/26.
//

import UIKit

// MARK: - ProfileStore

/// Spec 2: "All elements should be persistent between app launches."
///
/// This protocol abstracts away what the rest of the app knows about saving.
///
/// > *What* can be saved, not *how*.
///
/// Screens depend on the protocol, not on `DiskProfileStore`, so Previews and Tests can
/// use `InMemoryProfileStore`, which never touches the disk.
///
/// `@MainActor`: Pinning the protocol here means Swift 6 wont ask us to make the stores `Sendable`,
/// a guarantee.  Otherwise we have to prove for `UserDefaults` and `FileManager`.
@MainActor
protocol ProfileStore: AnyObject {
    func loadProfile() -> BabyProfile
    func saveProfile(_ profile: BabyProfile)

    func loadPhoto() -> UIImage?
    func savePhoto(_ photo: UIImage?)
}

// MARK: - DiskProfileStore

/// The real store. Small fields go in `UserDefaults`; the photo goes in a file.
///
/// ## Why not everything in one place?
///
/// **Images** can be megabytes. Putting them in `UserDefaults` would load
/// the whole thing into memory on every launch, and Apple warns against it.
///
/// A file in Application Support is the standard home for app-generated data the user doesn't browse directly.
///
/// ## Why not CoreData/SwiftData/SQLiteData ?
/// There's one record with three fields. A database would add a schema and migrations to solve a problem we don't have/need.
final class DiskProfileStore: ProfileStore {
    private let defaults: UserDefaults
    private let photoURL: URL

    /// The `UserDefaults` key the profile is saved under. Versioning (`v1`) leaves room for a
    /// different format later without misreading old data.
    private static let profileKey = "babyProfile.v1"

    /// - Parameters:
    ///   - defaults: Where to save the name and birthday. Tests pass a
    ///     throwaway suite so they never touch the real app's data.
    ///   - directory: Where to save the photo. Defaults to Application
    ///     Support, which iOS backs up but doesn't show in the Files app.
    init(
        defaults: UserDefaults = .standard,
        directory: URL = URL.applicationSupportDirectory
    ) {
        self.defaults = defaults
        self.photoURL = directory.appending(path: "baby-photo.jpg")
    }

    // MARK: Name and birthday

    /// The structure of the data saved to disk (aka "the shape").
    ///
    /// It's separate from `BabyProfile` so the in-memory model can change (i.e.: gaining computed properties)
    /// without silently changing the saved format.
    private struct StoredProfile: Codable {
        var name: String
        var birthday: Birthday?
    }

    func loadProfile() -> BabyProfile {
        // A first launch has no data yet, and a value saved in a format we
        // can't decode shouldn't crash the app. In both cases, start fresh.
        guard
            let data = defaults.data(forKey: Self.profileKey),
            let stored = try? JSONDecoder().decode(StoredProfile.self, from: data)
        else {
            return BabyProfile()
        }
        return BabyProfile(name: stored.name, birthday: stored.birthday)
    }

    func saveProfile(_ profile: BabyProfile) {
        let stored = StoredProfile(name: profile.name, birthday: profile.birthday)
        // Encoding two simple fields can't fail, so `try?` doesn't hide a real
        // error here. If it ever did fail, the old value would stay saved.
        if let data = try? JSONEncoder().encode(stored) {
            defaults.set(data, forKey: Self.profileKey)
        }
    }

    // MARK: Photo

    func loadPhoto() -> UIImage? {
        // `UIImage(contentsOfFile:)` returns nil when the file doesn't exist,
        // which is exactly "no photo yet".
        UIImage(contentsOfFile: photoURL.path(percentEncoded: false))
    }

    func savePhoto(_ photo: UIImage?) {
        guard let photo else {
            // A missing file is already the state we want, so a failure to delete one isn't an error.
            try? FileManager.default.removeItem(at: photoURL)
            return
        }
        // JPEG at 85% quality is visually lossless for photos, and several times smaller than PNG.
        guard let data = photo.jpegData(compressionQuality: 0.85) else { return }
        do {
            // Application Support isn't created for an app automatically, so
            // make sure it exists before the first write.
            try FileManager.default.createDirectory(
                at: photoURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try data.write(to: photoURL, options: .atomic) // use atomic to avoid half a photo being left due to an unforseen event (crash - I've seen it)
        } catch {
            // IMHO A failed save shouldn't interrupt the user: they still see the
            // photo for this session. Logging it keeps the failure visible
            // during development.
            print("Couldn't save the photo: \(error)")
        }
    }
}

// MARK: - InMemoryProfileStore

/// A store that keeps everything in memory, for previews and tests.
///
/// Nothing it holds survives the process, which is the point of being in-memory.
final class InMemoryProfileStore: ProfileStore {
    private var profile: BabyProfile
    private var photo: UIImage?

    init(profile: BabyProfile = BabyProfile(), photo: UIImage? = nil) {
        self.profile = profile
        self.photo = photo
    }

    func loadProfile() -> BabyProfile { profile }
    func saveProfile(_ profile: BabyProfile) { self.profile = profile }
    func loadPhoto() -> UIImage? { photo }
    func savePhoto(_ photo: UIImage?) { self.photo = photo }
}
