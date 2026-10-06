import AppKit
import Combine
import SwiftUI

/// Reads and writes the global (`defaults -g`) appearance preferences.
enum GlobalPrefs {
    static func get(_ key: String) -> CFPropertyList? {
        CFPreferencesSynchronize(kCFPreferencesAnyApplication, kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
        return CFPreferencesCopyValue(key as CFString, kCFPreferencesAnyApplication,
                                      kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
    }

    /// Pass `nil` to delete the key.
    static func set(_ key: String, _ value: CFPropertyList?) {
        CFPreferencesSetValue(key as CFString, value, kCFPreferencesAnyApplication,
                              kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
    }

    static func commit() {
        CFPreferencesSynchronize(kCFPreferencesAnyApplication, kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
        // Same notifications System Settings posts, so running apps refresh what they can.
        let center = DistributedNotificationCenter.default()
        center.postNotificationName(.init("AppleColorPreferencesChangedNotification"),
                                    object: nil, userInfo: nil, deliverImmediately: true)
        center.postNotificationName(.init("AppleAquaColorVariantChanged"),
                                    object: nil, userInfo: nil, deliverImmediately: true)
    }
}

final class AccentStore: ObservableObject {
    private enum Keys {
        static let accent = "AppleAccentColor"
        static let aquaVariant = "AppleAquaColorVariant"
        static let simulate = "NSColorSimulateHardwareAccent"
        static let enclosure = "NSColorSimulatedHardwareEnclosureNumber"
        /// Stored in this app's own defaults.
        static let learnedThisMac = "LearnedThisMacAccentValue"
    }

    @Published private(set) var selected: Accent.Kind = .multicolor
    /// The hardware accent currently exposed as "This Mac", if any.
    @Published private(set) var hardwareAccent: Accent?
    @Published var hovered: Accent?

    var previewAccent: Accent { hovered ?? Accent.find(selected) }
    var hardwareEnabled: Bool { hardwareAccent != nil }

    /// True when a hardware color is set but we don't know yet which
    /// `AppleAccentColor` value means "This Mac" on this system.
    var needsThisMacHint: Bool {
        if case .hardware = selected { return learnedThisMacValue == nil }
        return false
    }

    private var learnedThisMacValue: Int? {
        get { UserDefaults.standard.object(forKey: Keys.learnedThisMac) as? Int }
        set { UserDefaults.standard.set(newValue, forKey: Keys.learnedThisMac) }
    }

    init() { reload() }

    func reload() {
        let raw = (GlobalPrefs.get(Keys.accent) as? NSNumber)?.intValue
        let simulate = (GlobalPrefs.get(Keys.simulate) as? Bool) ?? false
        let enclosure = (GlobalPrefs.get(Keys.enclosure) as? NSNumber)?.intValue

        if simulate, let enclosure {
            hardwareAccent = Accent.find(.hardware(enclosure))
        } else {
            hardwareAccent = nil
        }

        if let raw, Accent.knownSystemValues.contains(raw) {
            selected = .system(raw)
        } else if simulate, let enclosure {
            // An unknown AppleAccentColor value while a hardware accent is active
            // is what System Settings writes for "This Mac": remember it.
            if let raw { learnedThisMacValue = raw }
            selected = .hardware(enclosure)
        } else {
            selected = .multicolor
        }
    }

    func select(_ accent: Accent) {
        switch accent.kind {
        case .multicolor:
            GlobalPrefs.set(Keys.accent, nil)
            GlobalPrefs.set(Keys.aquaVariant, NSNumber(value: 1))
        case .system(let value):
            GlobalPrefs.set(Keys.accent, NSNumber(value: value))
            GlobalPrefs.set(Keys.aquaVariant, NSNumber(value: value == -1 ? 6 : 1))
        case .hardware(let number):
            GlobalPrefs.set(Keys.simulate, kCFBooleanTrue)
            GlobalPrefs.set(Keys.enclosure, NSNumber(value: number))
            if let learned = learnedThisMacValue {
                GlobalPrefs.set(Keys.accent, NSNumber(value: learned))
            }
            hardwareAccent = accent
        }
        GlobalPrefs.commit()
        withAnimation(.easeOut(duration: 0.15)) { selected = accent.kind }
    }

    /// Removes the hardware-accent keys and falls back to Multicolor if needed.
    func reset() {
        GlobalPrefs.set(Keys.simulate, nil)
        GlobalPrefs.set(Keys.enclosure, nil)
        if case .hardware = selected {
            GlobalPrefs.set(Keys.accent, nil)
            selected = .multicolor
        }
        hardwareAccent = nil
        GlobalPrefs.commit()
    }

    func openAppearanceSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.Appearance-Settings.extension") {
            NSWorkspace.shared.open(url)
        }
    }
}
