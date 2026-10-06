import SwiftUI

/// One selectable accent color.
struct Accent: Identifiable, Hashable {
    enum Kind: Hashable {
        /// No `AppleAccentColor` key (each app uses its own accent).
        case multicolor
        /// A regular accent, stored as `AppleAccentColor`.
        case system(Int)
        /// A hardware accent, stored as `NSColorSimulatedHardwareEnclosureNumber`.
        case hardware(Int)
    }

    let name: String
    /// Approximate sRGB value, used for drawing the swatch and the preview.
    let hex: UInt32
    let kind: Kind

    var id: Kind { kind }

    var color: Color { Color(hex: hex) }

    var isMulticolor: Bool { kind == .multicolor }

    var isHardware: Bool {
        if case .hardware = kind { return true }
        return false
    }

    /// The NSColorSimulatedHardwareEnclosureNumber of a hardware accent.
    var code: Int? {
        if case .hardware(let number) = kind { return number }
        return nil
    }

    var fill: AnyShapeStyle {
        isMulticolor ? AnyShapeStyle(Self.multicolorGradient) : AnyShapeStyle(color)
    }

    var ring: AnyShapeStyle {
        isMulticolor ? AnyShapeStyle(Color.secondary.opacity(0.45)) : AnyShapeStyle(color.opacity(0.5))
    }

    /// Color for glyphs/text drawn on top of the accent (checkmarks, selected rows…).
    var onColor: Color {
        luminance > 0.45 ? Color.black.opacity(0.85) : .white
    }

    private var luminance: Double {
        func linear(_ c: Double) -> Double {
            c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        return 0.2126 * linear(r) + 0.7152 * linear(g) + 0.0722 * linear(b)
    }

    /// The pie-slice "multicolor" swatch.
    static let multicolorGradient: AngularGradient = {
        let colors: [UInt32] = [0xFCB827, 0x62BA46, 0x007AFF, 0x953D96, 0xF74F9E, 0xE0383E, 0xF7821B]
        var stops: [Gradient.Stop] = []
        for (index, hex) in colors.enumerated() {
            let start = Double(index) / Double(colors.count)
            let end = Double(index + 1) / Double(colors.count)
            stops.append(.init(color: Color(hex: hex), location: start))
            stops.append(.init(color: Color(hex: hex), location: end))
        }
        return AngularGradient(stops: stops, center: .center,
                               startAngle: .degrees(-90), endAngle: .degrees(270))
    }()
}

struct AccentFamily: Identifiable {
    let title: String
    let accents: [Accent]
    var id: String { title }
}

extension AccentFamily {
    static let system = AccentFamily(title: "System Accents", accents: [
        Accent(name: "Multicolor", hex: 0x007AFF, kind: .multicolor),
        Accent(name: "Blue",       hex: 0x007AFF, kind: .system(4)),
        Accent(name: "Purple",     hex: 0x953D96, kind: .system(5)),
        Accent(name: "Pink",       hex: 0xF74F9E, kind: .system(6)),
        Accent(name: "Red",        hex: 0xE0383E, kind: .system(0)),
        Accent(name: "Orange",     hex: 0xF7821B, kind: .system(1)),
        Accent(name: "Yellow",     hex: 0xFCB827, kind: .system(2)),
        Accent(name: "Green",      hex: 0x62BA46, kind: .system(3)),
        Accent(name: "Graphite",   hex: 0x8C8C8C, kind: .system(-1)),
    ])

    static let iMac2021 = AccentFamily(title: "iMac 2021 Accents", accents: [
        Accent(name: "Yellow", hex: 0xD9A342, kind: .hardware(3)),
        Accent(name: "Green",  hex: 0x3D666A, kind: .hardware(4)),
        Accent(name: "Blue",   hex: 0x46627B, kind: .hardware(5)),
        Accent(name: "Pink",   hex: 0xBC413E, kind: .hardware(6)),
        Accent(name: "Purple", hex: 0x494D79, kind: .hardware(7)),
        Accent(name: "Orange", hex: 0xB05A38, kind: .hardware(8)),
    ])

    // Approximated from screenshots; macOS draws the real shade once applied.
    static let iMac2024 = AccentFamily(title: "iMac 2024 Accents", accents: [
        Accent(name: "Yellow", hex: 0xD6C463, kind: .hardware(9)),
        Accent(name: "Green",  hex: 0x5A8054, kind: .hardware(10)),
        Accent(name: "Blue",   hex: 0x546896, kind: .hardware(11)),
        Accent(name: "Pink",   hex: 0xAB5757, kind: .hardware(12)),
        Accent(name: "Purple", hex: 0x5D5B8B, kind: .hardware(13)),
        Accent(name: "Orange", hex: 0xC4794D, kind: .hardware(14)),
    ])

    static let macBookNeo = AccentFamily(title: "MacBook Neo 2026 Accents", accents: [
        Accent(name: "Indigo", hex: 0x9BA8D5, kind: .hardware(15)),
        Accent(name: "Citrus", hex: 0xBBD56C, kind: .hardware(16)),
        Accent(name: "Blush",  hex: 0xEF869A, kind: .hardware(17)),
    ])

    static let all: [AccentFamily] = [.system, .iMac2021, .iMac2024, .macBookNeo]
}

extension Accent {
    static let all: [Accent] = AccentFamily.all.flatMap(\.accents)
    static let knownSystemValues: Set<Int> = [-1, 0, 1, 2, 3, 4, 5, 6]

    static func find(_ kind: Kind) -> Accent {
        if let accent = all.first(where: { $0.kind == kind }) { return accent }
        if case .hardware(let number) = kind {
            return Accent(name: "This Mac (\(number))", hex: 0x8C8C8C, kind: kind)
        }
        return all[0]
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: 1)
    }
}
