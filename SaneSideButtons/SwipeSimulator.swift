//
//  SwipeSimulator.swift
//  SaneSideButtons
//
//  Created by Jan Hülsmann on 16.10.22.
//

import AppKit
import Synchronization

final class SwipeSimulator: Sendable {

    enum EventTap: Error {
        case failedSetup
    }

    private enum Keys {
        static let ignored: String = "ignoredApplications"
        static let reverse: String = "reverseButtons"
    }

    private let swipeBegin: [String: Int] = [
        kTLInfoKeyGestureSubtype as String: kTLInfoSubtypeSwipe,
        kTLInfoKeyGesturePhase as String: 1
    ]

    private let swipeLeft: [String: Int] = [
        kTLInfoKeyGestureSubtype as String: kTLInfoSubtypeSwipe,
        kTLInfoKeySwipeDirection as String: kTLInfoSwipeLeft,
        kTLInfoKeyGesturePhase as String: 4
    ]

    private let swipeRight: [String: Int] = [
        kTLInfoKeyGestureSubtype as String: kTLInfoSubtypeSwipe,
        kTLInfoKeySwipeDirection as String: kTLInfoSwipeRight,
        kTLInfoKeyGesturePhase as String: 4
    ]

    static let shared = SwipeSimulator()

    // MARK: - Internal State

    /// Whether the CGEvent tap is currently active.
    private let eventTapIsRunning: Mutex<Bool> = Mutex(false)

    /// A set of bundle identifiers that are ignored.
    private let ignoredApplications: Mutex<Set<String>> = Mutex(
        Set(UserDefaults.standard.stringArray(forKey: Keys.ignored) ?? [])
    )

    /// Whether the swipe direction is reversed (e.g. right <-> left).
    private let reverseButtons: Mutex<Bool> = Mutex(UserDefaults.standard.bool(forKey: Keys.reverse))

    /// Store the event tap reference to prevent premature release (M4 Mac compatibility)
    private let activeEventTap: Mutex<CFMachPort?> = Mutex(nil)

    private init() { }

    // MARK: - Public

    func areButtonsReversed() -> Bool {
        self.reverseButtons.withLock { $0 }
    }

    func toggleReverseButtons() {
        self.reverseButtons.withLock { reversed in
            reversed.toggle()
            UserDefaults.standard.set(reversed, forKey: Keys.reverse)
        }
    }

    func isEventTapRunning() -> Bool {
        self.eventTapIsRunning.withLock { $0 }
    }

    func addIgnoredApplication(bundleID: String) {
        self.ignoredApplications.withLock { applications in
            applications.insert(bundleID)
            UserDefaults.standard.set(Array(applications), forKey: Keys.ignored)
        }
    }

    func removeIgnoredApplication(bundleID: String) {
        self.ignoredApplications.withLock { applications in
            applications.remove(bundleID)
            UserDefaults.standard.set(Array(applications), forKey: Keys.ignored)
        }
    }

    func ignoredApplicationsContain(_ bundleID: String) -> Bool {
        self.ignoredApplications.withLock { $0.contains(bundleID) }
    }

    func setupEventTap() throws {
        try self.eventTapIsRunning.withLock { isRunning in
            guard !isRunning else { return }
            let eventMask = CGEventMask(
                1 << CGEventType.otherMouseDown.rawValue | 1 << CGEventType.otherMouseUp.rawValue
            )

            // Try multiple tap locations for M4 Mac compatibility
            let tapConfigurations: [(tap: CGEventTapLocation, place: CGEventTapPlacement, options: CGEventTapOptions)] = [
                (.cghidEventTap, .headInsertEventTap, .defaultTap),
                (.cgSessionEventTap, .headInsertEventTap, .defaultTap),
                (.cghidEventTap, .tailAppendEventTap, .defaultTap),
                (.cgAnnotatedSessionEventTap, .headInsertEventTap, .defaultTap)
            ]

            var eventTap: CFMachPort?
            for config in tapConfigurations {
                eventTap = CGEvent.tapCreate(
                    tap: config.tap,
                    place: config.place,
                    options: config.options,
                    eventsOfInterest: eventMask,
                    callback: mouseEventCallBack,
                    userInfo: nil)

                if eventTap != nil {
                    #if DEBUG
                    print("Event tap created successfully with tap location: \(config.tap.rawValue)")
                    #endif
                    break
                }
            }

            guard let eventTap else {
                isRunning = false
                throw EventTap.failedSetup
            }

            // Store the tap reference to prevent premature release (M4 Mac fix)
            self.activeEventTap.withLock { $0 = eventTap }

            let runLoopSource = CFMachPortCreateRunLoopSource(nil, eventTap, 0)
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            CGEvent.tapEnable(tap: eventTap, enable: true)
            isRunning = true
        }
    }

    func recreateEventTap() {
        // Properly clean up old tap before creating new one (M4 Mac compatibility)
        self.activeEventTap.withLock { tap in
            if let tap {
                CFMachPortInvalidate(tap)
            }
            tap = nil
        }
        self.eventTapIsRunning.withLock { $0 = false }
        try? self.setupEventTap()
    }

    func markEventTapAsInactive() {
        self.eventTapIsRunning.withLock { $0 = false }
    }

    private func fakeSwipe(direction: TLInfoSwipeDirection) {
        let eventBegin: CGEvent = tl_CGEventCreateFromGesture(self.swipeBegin as CFDictionary,
                                                              [] as CFArray).takeRetainedValue()

        let swipeDirection = self.reverseButtons.withLock { $0 ? direction.reversed : direction }
        let eventSwipe: CGEvent? = switch swipeDirection {
        case TLInfoSwipeDirection(kTLInfoSwipeLeft):
            tl_CGEventCreateFromGesture(self.swipeLeft as CFDictionary, [] as CFArray).takeRetainedValue()
        case TLInfoSwipeDirection(kTLInfoSwipeRight):
            tl_CGEventCreateFromGesture(self.swipeRight as CFDictionary, [] as CFArray).takeRetainedValue()
        default:
            nil
        }

        guard let eventSwipe else { return }
        eventBegin.post(tap: .cghidEventTap)
        eventSwipe.post(tap: .cghidEventTap)
    }

    fileprivate func handleMouseEvent(type: CGEventType, cgEvent: CGEvent) -> CGEvent? {
        guard type == .otherMouseDown && self.isValidApplication() else {
            return cgEvent
        }

        let number = CGEvent.getIntegerValueField(cgEvent)(.mouseEventButtonNumber)

        #if DEBUG
        // Log button presses to help diagnose M4 Mac issues
        print("Mouse button pressed: \(number)")
        #endif

        // Standard mapping: button 3 = back, button 4 = forward
        // Some mice on M4 Macs may report different button numbers
        switch number {
        case 3:
            // Standard back button
            self.fakeSwipe(direction: TLInfoSwipeDirection(kTLInfoSwipeLeft))
            return nil
        case 4:
            // Standard forward button
            self.fakeSwipe(direction: TLInfoSwipeDirection(kTLInfoSwipeRight))
            return nil
        case 5, 6, 7, 8:
            // Extended button support for mice that may map differently on M4 Macs
            // Odd numbers (5, 7) map to back/left, even numbers (6, 8) map to forward/right
            if number % 2 == 1 {
                self.fakeSwipe(direction: TLInfoSwipeDirection(kTLInfoSwipeLeft))
            } else {
                self.fakeSwipe(direction: TLInfoSwipeDirection(kTLInfoSwipeRight))
            }
            return nil
        default:
            return cgEvent
        }
    }

    private func isValidApplication() -> Bool {
        guard let frontAppBundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier else { return true }
        return self.ignoredApplications.withLock { !$0.contains(frontAppBundleID) }
    }
}

// swiftlint:disable private_over_fileprivate
fileprivate func mouseEventCallBack(proxy: CGEventTapProxy,
                                    type: CGEventType,
                                    cgEvent: CGEvent,
                                    userInfo: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
    guard let cgEvent = SwipeSimulator.shared.handleMouseEvent(type: type, cgEvent: cgEvent) else { return nil }
    return Unmanaged.passRetained(cgEvent)
}

fileprivate extension TLInfoSwipeDirection {
    var reversed: TLInfoSwipeDirection {
        switch self {
        case TLInfoSwipeDirection(kTLInfoSwipeLeft):
            return TLInfoSwipeDirection(kTLInfoSwipeRight)
        case TLInfoSwipeDirection(kTLInfoSwipeRight):
            return TLInfoSwipeDirection(kTLInfoSwipeLeft)
        default:
            return self
        }
    }
}
// swiftlint:enable private_over_fileprivate
