// Bitmap.swift
//
// Renders a view to pixels so a test can check where things are drawn. Used where the bug a
// suite guards against is a position, which no logic test can see: the compact month's event
// dot, and whether each calendar mirrors correctly in a right-to-left layout.

import CoreGraphics
import SwiftUI

/// A rendered view's pixels, RGBA, rows top-down to match SwiftUI's y.
struct Bitmap {

    struct Pixel {
        let red: Int
        let green: Int
        let blue: Int
        let alpha: Int
    }

    let width: Int
    let height: Int
    private let bytes: [UInt8]

    /// Renders `view` at 1× in `direction` with `locale` in the environment, or returns `nil` if
    /// it could not be drawn.
    ///
    /// `ImageRenderer` can hand back its previous image when it is asked for the same view twice
    /// with only small state changed, so compare renders that differ in size or direction rather
    /// than ones that differ only in a flag.
    @MainActor
    static func render(
        _ view: some View,
        direction: LayoutDirection = .leftToRight,
        locale: Locale = .autoupdatingCurrent
    ) -> Bitmap? {
        let content = view
            .environment(\.layoutDirection, direction)
            .environment(\.locale, locale)

        let renderer = ImageRenderer(content: content)
        renderer.scale = 1

        guard let image = renderer.cgImage else {
            return nil
        }

        return Bitmap(image)
    }

    private init?(_ image: CGImage) {
        let width = image.width
        let height = image.height
        var bytes = [UInt8](repeating: 0, count: width * height * 4)

        let drawn = bytes.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else {
                return false
            }

            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }

        guard drawn else {
            return nil
        }

        self.width = width
        self.height = height
        self.bytes = bytes
    }

    func pixel(x column: Int, y row: Int) -> Pixel {
        let offset = (row * self.width + column) * 4

        return Pixel(
            red: Int(self.bytes[offset]),
            green: Int(self.bytes[offset + 1]),
            blue: Int(self.bytes[offset + 2]),
            alpha: Int(self.bytes[offset + 3])
        )
    }

    /// The pixels that match `test`, as a mask indexed `y * width + x`.
    func mask(where test: (Pixel) -> Bool) -> [Bool] {
        var mask = [Bool](repeating: false, count: self.width * self.height)

        for row in 0..<self.height {
            for column in 0..<self.width where test(self.pixel(x: column, y: row)) {
                mask[row * self.width + column] = true
            }
        }

        return mask
    }

    /// The bounds of the pixels that match `test`, or `nil` if none do.
    func bounds(where test: (Pixel) -> Bool) -> CGRect? {
        var bounds: CGRect?

        for row in 0..<self.height {
            for column in 0..<self.width where test(self.pixel(x: column, y: row)) {
                let pixel = CGRect(x: column, y: row, width: 1, height: 1)
                bounds = bounds.map { $0.union(pixel) } ?? pixel
            }
        }

        return bounds
    }

    /// How far this bitmap's matching pixels are from being the mirror image of `other`'s: the
    /// share of pixels, among those either one matches, that only one of them does once `other`
    /// is flipped left to right. 0 is a perfect mirror; anti-aliased edges keep a real one a
    /// little above it. `nil` when the sizes differ or neither has any matching pixels.
    func mirrorMismatch(with other: Bitmap, where test: (Pixel) -> Bool) -> Double? {
        self.mismatch(with: other, flipped: true, where: test)
    }

    /// As `mirrorMismatch`, without the flip: how different two renders of the same size are.
    func mismatch(with other: Bitmap, where test: (Pixel) -> Bool) -> Double? {
        self.mismatch(with: other, flipped: false, where: test)
    }

    private func mismatch(with other: Bitmap, flipped: Bool, where test: (Pixel) -> Bool) -> Double? {
        guard self.width == other.width, self.height == other.height else {
            return nil
        }

        let mine = self.mask(where: test)
        let theirs = other.mask(where: test)

        var either = 0
        var onlyOne = 0

        for row in 0..<self.height {
            for column in 0..<self.width {
                let here = mine[row * self.width + column]
                let there = theirs[row * self.width + (flipped ? self.width - 1 - column : column)]

                if here || there {
                    either += 1
                }

                if here != there {
                    onlyOne += 1
                }
            }
        }

        return either == 0 ? nil : Double(onlyOne) / Double(either)
    }
}
