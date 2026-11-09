//
//  BirthdayLayoutTests.swift
//  NanitTakeHomeTests
//
//  Created by Daniel Rodriguez on 11/8/26.
//
import Foundation
import Testing
import UIKit
@testable import NanitTakeHome

@MainActor
final class ProfileStoreTests {
    private let suiteName = "ProfileStoreTests.\(UUID().uuidString)"
    private let defaults: UserDefaults
    private let directory: URL

    init() {
        defaults = UserDefaults(suiteName: suiteName)!
        directory = FileManager.default.temporaryDirectory
            .appending(path: "ProfileStoreTests-\(UUID().uuidString)")
    }

    deinit {
        // `deinit` isn't main-actor isolated, so Swift 6 won't let it touch
        // the `defaults` property (UserDefaults isn't Sendable). Removing a
        // suite by name through `.standard` deletes the same data.
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
        try? FileManager.default.removeItem(at: directory)
    }

    private func makeStore() -> DiskProfileStore {
        DiskProfileStore(defaults: defaults, directory: directory)
    }

    @Test func firstLaunchStartsEmpty() {
        let store = makeStore()
        #expect(store.loadProfile() == BabyProfile())
        #expect(store.loadPhoto() == nil)
    }
    
    // On the "relaunch" tests, we simulate a relaunch by creating a new
    // Store via makeStore()

    @Test func profileSurvivesRelaunch() {
        let profile = BabyProfile(name: "Luke", birthday: Birthday(year: 2025, month: 3, day: 10))
        makeStore().saveProfile(profile)
        #expect(makeStore().loadProfile() == profile)
    }

    @Test func photoSurvivesRelaunch() throws {
        let photo = Self.solidImage(size: CGSize(width: 40, height: 30))
        makeStore().savePhoto(photo)

        let loaded = try #require(makeStore().loadPhoto())
        // Compare pixel sizes, not points: the loaded file has a scale of 1.
        #expect(loaded.size.width * loaded.scale == 40)
        #expect(loaded.size.height * loaded.scale == 30)
    }

    @Test func savingNilPhotoDeletesIt() {
        makeStore().savePhoto(Self.solidImage(size: CGSize(width: 10, height: 10)))
        makeStore().savePhoto(nil)
        #expect(makeStore().loadPhoto() == nil)
    }

    /// Unreadable saved data (from a future version, say) starts fresh rather
    /// than crashing.
    @Test func corruptDataStartsEmpty() {
        defaults.set(Data("not json".utf8), forKey: "babyProfile.v1")
        #expect(makeStore().loadProfile() == BabyProfile())
    }

    /// A tiny single-color image, drawn at 1 pixel per point so its size is predictable.
    static func solidImage(size: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor.systemTeal.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}

/// The details model's job in step 2: load on start, save on every change.
/// These use `InMemoryProfileStore`, since the disk store is tested above.
@MainActor
struct DetailsModelTests {
    @Test func loadsSavedProfileOnStart() {
        let saved = BabyProfile(name: "Luke", birthday: Birthday(year: 2025, month: 3, day: 10))
        let model = DetailsModel(store: InMemoryProfileStore(profile: saved))
        #expect(model.profile == saved)
    }

    @Test func editsAreSavedImmediately() {
        let store = InMemoryProfileStore()
        let model = DetailsModel(store: store)

        model.profile.name = "Luke"
        model.profile.birthday = Birthday(year: 2025, month: 3, day: 10)

        // A new model over the same store sees the edits, as after a relaunch.
        #expect(DetailsModel(store: store).profile == model.profile)
    }

    /// The photo is downscaled before it's kept, so a huge camera photo can't
    /// waste memory.
    @Test func setPhotoDownscalesAndSaves() throws {
        let store = InMemoryProfileStore()
        let model = DetailsModel(store: store)

        model.setPhoto(ProfileStoreTests.solidImage(size: CGSize(width: 4000, height: 3000)))

        let photo = try #require(model.photo)
        #expect(photo.size.width * photo.scale == 1600)
        #expect(photo.size.height * photo.scale == 1200)
        #expect(store.loadPhoto() === photo)
    }
}
