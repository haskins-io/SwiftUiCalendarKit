// CKSwipeTests.swift
//
// Which way a horizontal swipe moves the day view — `CKSwipe`.

@testable import SwiftUiCalendarKit
import Foundation
import SwiftUI
import Testing

@Suite("Swipe — towards the leading edge moves forward, in either layout direction")
struct CKSwipeTests {

    private static let left = CGSize(width: -80, height: 10)
    private static let right = CGSize(width: 80, height: -10)

    @Test("Left to right: swiping left goes forward, right goes back")
    func leftToRight() {
        #expect(CKSwipe.step(translation: Self.left, layoutDirection: .leftToRight) == 1)
        #expect(CKSwipe.step(translation: Self.right, layoutDirection: .leftToRight) == -1)
    }

    @Test("Right to left: swiping right goes forward, left goes back")
    func rightToLeft() {
        #expect(CKSwipe.step(translation: Self.right, layoutDirection: .rightToLeft) == 1)
        #expect(CKSwipe.step(translation: Self.left, layoutDirection: .rightToLeft) == -1)
    }

    @Test("A mostly vertical drag is left to the scroll view", arguments: [
        LayoutDirection.leftToRight,
        .rightToLeft
    ])
    func vertical(direction: LayoutDirection) {
        #expect(CKSwipe.step(translation: CGSize(width: -40, height: 120), layoutDirection: direction) == nil)
        #expect(CKSwipe.step(translation: CGSize(width: 40, height: -120), layoutDirection: direction) == nil)
    }

    @Test("A drag exactly as tall as it is wide, or with no sideways movement, does nothing", arguments: [
        LayoutDirection.leftToRight,
        .rightToLeft
    ])
    func ambiguous(direction: LayoutDirection) {
        #expect(CKSwipe.step(translation: CGSize(width: 50, height: 50), layoutDirection: direction) == nil)
        #expect(CKSwipe.step(translation: .zero, layoutDirection: direction) == nil)
    }
}
