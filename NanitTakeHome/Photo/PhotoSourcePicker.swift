//
//  PhotoSourcePicker.swift
//  NanitTakeHome
//
//  Created by Daniel Rodriguez on 11/7/26.
//


import AVFoundation
import PhotosUI
import SwiftUI

/// Spec 2 and 4: "select from gallery or take a photo".
///
/// Both Details and  Birthday screens need the same flow: ask *where* the photo comes from, then
/// show the library or the camera. Writing it once as a view modifier means the details screen and
/// the birthday screen (step 4) share one implementation, so they can't drift apart.
///
/// ## Usage
///
/// ```
///     .photoSourcePicker(isPresented: $isChoosingPhoto) { image in ... }
/// ```
///
/// The flow:
/// 1. `isPresented` becomes true → a dialog offers Library or Camera.
/// 2. Library → the system photo picker. Camera → a permission check, then the camera.
/// 3. The chosen image goes to `onPick`. Cancelling at any point calls nothing.
extension View {
    func photoSourcePicker(
        isPresented: Binding<Bool>,
        onPick: @escaping (UIImage) -> Void
    ) -> some View {
        modifier(PhotoSourcePicker(isPresented: isPresented, onPick: onPick))
    }
}

private struct PhotoSourcePicker: ViewModifier {
    @Binding var isPresented: Bool
    let onPick: (UIImage) -> Void

    @State private var isLibraryPresented = false
    @State private var isCameraPresented = false
    @State private var isCameraDeniedAlertPresented = false

    /// What the library picker returns.
    ///
    /// It's a *reference* to an asset, not the image itself; loading actually happens in `load(_:)`.
    @State private var libraryItem: PhotosPickerItem?

    private var isCameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    func body(content: Content) -> some View {
        content
            // Step 1 of the flow: ask where the photo comes from.
            .confirmationDialog("Add a picture", isPresented: $isPresented, titleVisibility: .visible) {
                Button("Choose from Library") { isLibraryPresented = true }
                if isCameraAvailable {
                    Button("Take Photo") { requestCamera() }
                }
            }

            // Library path.
            // `PhotosPicker` runs in a separate system process and only gives
            // us the photos the user picks, so it needs no photo-library permission
            // prompt.
            // That's why there's no NSPhotoLibraryUsageDescription in the project.
            .photosPicker(isPresented: $isLibraryPresented, selection: $libraryItem, matching: .images)
            .onChange(of: libraryItem) { _, item in
                guard let item else { return }
                // Clear it right away, so picking the *same* photo again still counts as a change and triggers this handler.
                libraryItem = nil
                Task { await load(item) }
            }

            // Camera path. A full-screen cover, because the system camera UI
            // is designed to fill the screen.
            .fullScreenCover(isPresented: $isCameraPresented) {
                CameraPicker(
                    onPick: { image in
                        isCameraPresented = false
                        onPick(image)
                    },
                    onCancel: { isCameraPresented = false }
                )
                // The camera draws its own controls to the screen edges.
                .ignoresSafeArea()
            }

            // Shown when camera permission was turned off earlier. iOS asks
            // only once, so the only way back is the Settings app.
            .alert("Camera access is off", isPresented: $isCameraDeniedAlertPresented) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("To take a photo, allow camera access for Happy Birthday in Settings.")
            }
    }

    /// Checks camera permission before showing the camera.
    ///
    /// iOS shows its permission prompt the first time an app uses the camera.
    /// Checking ourselves means a *denied* permission gets a helpful alert,
    /// instead of a black camera screen.
    private func requestCamera() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isCameraPresented = true
        case .notDetermined:
            // First use: show the system prompt, then open the camera only
            // if the user allowed it. The prompt's text comes from
            // NSCameraUsageDescription in project.yml.
            Task {
                if await AVCaptureDevice.requestAccess(for: .video) {
                    isCameraPresented = true
                }
            }
        case .denied, .restricted:
            // .restricted means parental controls or device management
            // blocked the camera. The user may not be able to change that,
            // but Settings is still the right pointer.
            isCameraDeniedAlertPresented = true
        @unknown default:
            // A future iOS might add a status. Treat it like "not allowed"
            // rather than guessing.
            isCameraDeniedAlertPresented = true
        }
    }

    /// Loads the picked library photo's data and turns it into a `UIImage`.
    ///
    /// `loadTransferable` is async because the photo may still need
    /// downloading from iCloud. If loading fails, or the data isn't an image,
    /// we silently do nothing: the user can simply pick again.
    private func load(_ item: PhotosPickerItem) async {
        guard
            let data = try? await item.loadTransferable(type: Data.self),
            let image = UIImage(data: data)
        else { return }
        onPick(image)
    }
}
