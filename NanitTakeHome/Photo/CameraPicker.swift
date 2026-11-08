//
//  CameraPicker.swift
//  NanitTakeHome
//
//  Created by Daniel Rodriguez on 11/7/26.
//
import SwiftUI
import UIKit

/// Take a Photo
///
/// SwiftUI has no camera view, so this wraps UIKit's `UIImagePickerController` in camera mode.
///
struct CameraPicker: UIViewControllerRepresentable {
    /// Called with the captured photo after the user taps Use Photo.
    let onPick: (UIImage) -> Void
    /// Called when the user cancels, so the presenter can dismiss us.
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.delegate = context.coordinator
        return picker
    }

    /// Nothing about the picker changes after it appears, so there's nothing to update.
    /// The method is required by the protocol.
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick, onCancel: onCancel)
    }

    /// The delegate. `UIImagePickerController` requires its delegate to also
    /// be a `UINavigationControllerDelegate`, because the picker is a
    /// navigation controller. We don't use any of those methods.
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private let onPick: (UIImage) -> Void
        private let onCancel: () -> Void

        init(onPick: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) {
            self.onPick = onPick
            self.onCancel = onCancel
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            // `.originalImage` is the photo as taken.
            if let image = info[.originalImage] as? UIImage {
                onPick(image)
            } else {
                // No image means nothing to use, which behaves like a cancel.
                onCancel()
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onCancel()
        }
    }
}
