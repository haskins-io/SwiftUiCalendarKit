//
//  File.swift
//  SwiftUiCalendarKit
//
//  Created by Mark Haskins on 21/09/2026.
//


import SwiftUI

/// Lays subviews out in a row, wrapping to the next line when they run out of width.
nonisolated struct CKFlowLayout: Layout {

    var spacing: CGFloat = 8

    var lineSpacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let lines = self.lines(within: proposal.width ?? .infinity, subviews: subviews)

        let width = lines.map(\.width).max() ?? 0
        let height = lines.reduce(0) { $0 + $1.height }
        + max(0, CGFloat(lines.count - 1)) * self.lineSpacing

        return CGSize(width: proposal.width ?? width, height: height)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        var top = bounds.minY

        for line in self.lines(within: bounds.width, subviews: subviews) {
            var leading = bounds.minX

            for index in line.indices {
                let size = self.size(of: subviews[index], within: bounds.width)

                subviews[index].place(
                    at: CGPoint(x: leading, y: top + (line.height - size.height) / 2),
                    proposal: ProposedViewSize(size)
                )

                leading += size.width + self.spacing
            }

            top += line.height + self.lineSpacing
        }
    }

    /// One wrapped line: which subviews are on it, and how big it is.
    private struct Line {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    /// A subview's size, **given the width actually available to it**.
    ///
    /// The first version of this measured everything with `.unspecified` and then placed it at
    /// that ideal size. For a leaf chip that is fine — its ideal width *is* its width. For a
    /// subview that can wrap internally it is not: the day footer's gated group is itself a
    /// `CKFlowLayout`, and measured unspecified it reports the width of all its chips on one
    /// line, is placed at that width, and runs off the edge. Three of six chips simply
    /// disappeared off the right of an iPhone.
    ///
    /// Proposing the container width whenever the ideal exceeds it lets such a subview lay
    /// itself out properly, and changes nothing for the ones that cannot wrap.
    private func size(of subview: LayoutSubview, within width: CGFloat) -> CGSize {

        let ideal = subview.sizeThatFits(.unspecified)

        guard ideal.width > width, width.isFinite else {
            return ideal
        }

        return subview.sizeThatFits(ProposedViewSize(width: width, height: nil))
    }

    /// Breaks the subviews into lines that fit `width`.
    ///
    /// A subview wider than the whole container still gets a line of its own rather than being
    /// dropped — it will be clipped by its own `lineLimit`, which is the caller's business, but
    /// it must not disappear.
    private func lines(within width: CGFloat, subviews: Subviews) -> [Line] {

        var lines: [Line] = []
        var current = Line()

        for index in subviews.indices {
            let size = self.size(of: subviews[index], within: width)
            let needed = current.indices.isEmpty ? size.width : current.width + self.spacing + size.width

            if !current.indices.isEmpty, needed > width {
                lines.append(current)
                current = Line()
            }

            current.width = current.indices.isEmpty ? size.width : current.width + self.spacing + size.width
            current.height = max(current.height, size.height)
            current.indices.append(index)
        }

        if !current.indices.isEmpty {
            lines.append(current)
        }

        return lines
    }
}
