
//
//  UIImage+Storage.swift
//  Nanit TakeHome
//
//  Created by Daniel Rodriguez on 11/7/26.
//
import UIKit

extension UIImage {
    /// Returns a copy that's safe and cheap to keep: downscaled so its longest
    /// side is at most `maxPixelDimension`, with the orientation baked into
    /// the pixels.
    ///
    /// ## Why downscale?
    /// A modern iPhone photo is around 48 megapixels. Decoded, that's roughly
    /// 190 MB of memory, and the largest place we show it is a circle about
    /// 200 points (600 pixels) wide. 1600 pixels keeps the image sharp, even
    /// when shared, at a small fraction of the cost.
    ///
    /// ## Why bake in the orientation?
    /// Camera photos usually store their pixels sideways, with an `imageOrientation`
    /// tag that says "rotate me when you display this".
    ///
    /// Some code paths, such as JPEG encoding on older systems and CoreImage, can ignore that tag
    /// and show the photo sideways. Redrawing the image writes the pixels upright, so the tag
    /// becomes `.up` and every consumer agrees.
    func preparedForStorage(maxPixelDimension: CGFloat = 1600) -> UIImage {
        // `size` is in points, so multiply by `scale` to get pixels.
        let pixelWidth = size.width * scale
        let pixelHeight = size.height * scale
        let longestSide = max(pixelWidth, pixelHeight)

        // Never scale *up*: that only makes the file bigger without more detail.
        let ratio = min(1, maxPixelDimension / longestSide)
        let targetSize = CGSize(
            width: (pixelWidth * ratio).rounded(),
            height: (pixelHeight * ratio).rounded()
        )

        let format = UIGraphicsImageRendererFormat()
        // Draw 1 pixel per point, so `targetSize` is the exact pixel size.
        format.scale = 1
        // Photos don't need an alpha channel, so render opaque. That roughly
        // halves memory and lets JPEG encoding skip a conversion.
        format.opaque = true

        // `draw(in:)` applies `imageOrientation` while drawing. That's what
        // bakes the rotation into the pixels.
        return UIGraphicsImageRenderer(size: targetSize, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}
