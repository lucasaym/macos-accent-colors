import SwiftUI
import AppKit
import Combine

struct ContentView: View {
    @StateObject var store = AccentStore()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(AccentFamily.all.enumerated()), id: \.element.id) { index, family in
                    if index > 0 { SectionDivider() }
                    FamilySection(family: family)
                }
                SectionDivider()
                FooterSection()
                SectionDivider()
                PreviewSection()
                CreditsFooter()
            }
            .padding(.horizontal, 30)
            .padding(.top, 14)
            .padding(.bottom, 30)
        }
        .frame(width: 520)
        .frame(minHeight: 480, idealHeight: 880, maxHeight: .infinity)
        .environmentObject(store)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            store.reload()
        }
    }
}

// MARK: - Sections

struct SectionDivider: View {
    var body: some View {
        Divider().padding(.vertical, 18)
    }
}

struct SectionTitle: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text).font(.system(size: 15, weight: .semibold))
    }
}

struct FamilySection: View {
    @EnvironmentObject var store: AccentStore
    let family: AccentFamily

    private var caption: String {
        if let hovered = store.hovered, family.accents.contains(hovered) { return hovered.name }
        if let selected = family.accents.first(where: { $0.kind == store.selected }) { return selected.name }
        return ""
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(family.title)
            HStack(spacing: 2) {
                ForEach(family.accents) { accent in
                    SwatchButton(accent: accent)
                }
                Text(caption)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .padding(.leading, 10)
                    .animation(nil, value: caption)
            }
            .padding(.leading, -5) // align the swatch (not its ring frame) with the title
        }
    }
}

struct FooterSection: View {
    @EnvironmentObject var store: AccentStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Apps currently open will need to be restarted to use iMac/MacBook Neo colors.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if store.needsThisMacHint {
                Label("If it isn't already, choose \u{201C}This Mac\u{201D} once in Appearance settings.",
                      systemImage: "info.circle")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack {
                Button("How It Works\u{2026}") { InfoWindow.show() }
                Spacer()
                Button("Reset") { store.reset() }
                    .disabled(!store.hardwareEnabled)
                    .help("Remove the hardware accent preferences")
                Button("Appearance Settings\u{2026}") { store.openAppearanceSettings() }
            }
        }
    }
}

struct CreditsFooter: View {
    var body: some View {
        HStack(spacing: 6) {
            Text("\(AppInfo.name) \(AppInfo.version) · by \(AppInfo.author)")
            Spacer()
            Link(destination: AppInfo.repoURL) {
                Label("GitHub", systemImage: "arrow.up.right.square")
            }
        }
        .font(.system(size: 11))
        .foregroundStyle(.secondary)
        .padding(.top, 26)
    }
}

// MARK: - Swatches

struct Swatch: View {
    let accent: Accent
    var diameter: CGFloat = 28
    var isSelected = false
    var isHovered = false

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(accent.ring, lineWidth: 2.5)
                .opacity(isSelected ? 1 : 0)
                .scaleEffect(isSelected ? 1 : 0.85)

            Circle()
                .fill(accent.fill)
                .overlay(
                    Circle().fill(LinearGradient(colors: [.white.opacity(0.16), .clear],
                                                 startPoint: .top, endPoint: .bottom))
                )
                .overlay(Circle().strokeBorder(Color.black.opacity(0.12), lineWidth: 0.5))
                .frame(width: diameter, height: diameter)
                .shadow(color: .black.opacity(0.12), radius: 1, y: 0.5)
                .scaleEffect(isHovered && !isSelected ? 1.08 : 1)
        }
        .frame(width: diameter + 10, height: diameter + 10)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
        .animation(.easeOut(duration: 0.12), value: isHovered)
    }
}

struct SwatchButton: View {
    @EnvironmentObject var store: AccentStore
    let accent: Accent
    var diameter: CGFloat = 28

    var body: some View {
        let isSelected = store.selected == accent.kind
        Button {
            store.select(accent)
        } label: {
            Swatch(accent: accent, diameter: diameter,
                   isSelected: isSelected, isHovered: store.hovered == accent)
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .onHover { inside in
            if inside {
                store.hovered = accent
            } else if store.hovered == accent {
                store.hovered = nil
            }
        }
        .help(accent.name)
        .accessibilityLabel(accent.name)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
