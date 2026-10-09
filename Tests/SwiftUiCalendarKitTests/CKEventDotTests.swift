// CKEventDotTests.swift
//
// The compact month's "has events" dot — `CKEventDotModifier`. Rendered rather than inspected:
// the bug this guards against was a position, so the test looks at where the pixels land. The
// old dot was off-centre in any column not about 50 points wide, and drawn outside the cell
// altogether in a right-to-left layout; both cases are covered below.
//
// There is no "hidden" case: `ImageRenderer` reused the previous same-sized render when only the
// dot's visibility changed, which made such a test unreliable.

@testable import SwiftUiCalendarKit
import CoreGraphics
import SwiftUI
import Testing

@Suite("Event dot — centred under the day number in any column, in either direction")
@MainActor
struct CKEventDotTests {

    /// The size of the day number the dot hangs off, as `CKMonthComponent` draws it.
    private static let number: CGFloat = 33

    @Test("The dot sits centred under the number", arguments: [
        (LayoutDirection.leftToRight, CGFloat(50)),
        (.rightToLeft, 50),
        (.leftToRight, 120),
        (.rightToLeft, 120),
        (.leftToRight, 33),
        (.rightToLeft, 33)
    ])
    func centred(direction: LayoutDirection, columnWidth: CGFloat) throws {
        let dot = try #require(Self.dotBounds(direction: direction, columnWidth: columnWidth))

        #expect(abs(dot.midX - columnWidth / 2) <= 0.5)
        #expect(abs(dot.width - CKEventDotModifier.diameter) <= 1)
    }

    @Test("The dot is just below the number, not over it", arguments: [
        LayoutDirection.leftToRight,
        .rightToLeft
    ])
    func belowTheNumber(direction: LayoutDirection) throws {
        let dot = try #require(Self.dotBounds(direction: direction, columnWidth: 50))

        #expect(abs(dot.minY - (Self.number + CKEventDotModifier.gap)) <= 0.5)
    }

    // MARK: Rendering

    /// Renders a day number with the dot, centred in a column `columnWidth` wide as the month
    /// grid centres it, and returns the bounds of the green pixels, or `nil` if there are none.
    private static func dotBounds(direction: LayoutDirection, columnWidth: CGFloat) -> CGRect? {
        let cell = Color.clear
            .frame(width: Self.number, height: Self.number)
            .modifier(CKEventDotModifier(isVisible: true))
            .frame(width: columnWidth, height: Self.number + 20, alignment: .top)
            .environment(\.layoutDirection, direction)

        let renderer = ImageRenderer(content: cell)
        renderer.scale = 1

        guard let image = renderer.cgImage else {
            return nil
        }

        return Self.greenBounds(in: image)
    }

    private static func greenBounds(in image: CGImage) -> CGRect? {
        let width = image.width
        let height = image.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)

        let drawn = pixels.withUnsafeMutableBytes { buffer -> Bool in
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

        var bounds: CGRect?

        for row in 0..<height {
            for column in 0..<width {
                let offset = (row * width + column) * 4
                let red = pixels[offset]
                let green = pixels[offset + 1]
                let blue = pixels[offset + 2]
                let alpha = pixels[offset + 3]

                // Anti-aliased edges are faint; only count pixels that are clearly the dot.
                guard alpha > 128, green > 120, green > red, green > blue else {
                    continue
                }

                // The bitmap's rows run top-down, matching SwiftUI's y.
                let pixel = CGRect(x: column, y: row, width: 1, height: 1)
                bounds = bounds.map { $0.union(pixel) } ?? pixel
            }
        }

        return bounds
    }
}
