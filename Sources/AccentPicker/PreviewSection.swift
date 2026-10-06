import SwiftUI
import AppKit
import Combine

/// Bottom preview: a replica of System Settings › Appearance › Theme,
/// followed by common controls drawn in the previewed accent.
/// Hovering a swatch previews it without applying anything.
struct PreviewSection: View {
    @EnvironmentObject var store: AccentStore

    var body: some View {
        let accent = store.previewAccent
        VStack(alignment: .leading, spacing: 16) {
            SectionTitle("Preview")
            ThemePreview(accent: accent)
            ControlsPreview(accent: accent)
        }
        .animation(.easeOut(duration: 0.15), value: accent.id)
    }
}

// MARK: - System Settings building blocks

struct SettingsGroup<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0, content: content)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.primary.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.05), lineWidth: 0.5)
            )
    }
}

struct SettingsRow<Trailing: View>: View {
    let title: String
    var alignment: VerticalAlignment = .center
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(alignment: alignment) {
            Text(title)
                .padding(.top, alignment == .top ? 8 : 0)
            Spacer(minLength: 16)
            trailing()
        }
        .font(.system(size: 13))
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(minHeight: 40)
    }
}

struct RowDivider: View {
    var body: some View {
        Divider().padding(.horizontal, 10)
    }
}

struct GroupHeader: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .padding(.leading, 2)
    }
}

// MARK: - Theme (System Settings replica)

struct ThemePreview: View {
    @EnvironmentObject var store: AccentStore
    let accent: Accent

    /// The "This Mac" swatch: the previewed hardware accent, or the one currently enabled.
    private var thisMac: Accent? { accent.isHardware ? accent : store.hardwareAccent }

    private var highlightName: String {
        if accent.isHardware { return "This Mac" }
        if accent.isMulticolor { return "Accent Color" }
        return accent.name
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            GroupHeader("Theme")
            SettingsGroup {
                SettingsRow(title: "Color", alignment: .top) {
                    HStack(alignment: .top, spacing: 0) {
                        ForEach(AccentFamily.system.accents) { item in
                            MiniSwatch(accent: item,
                                       isSelected: accent.kind == item.kind,
                                       caption: item.name)
                        }
                        if let thisMac {
                            MiniSwatch(accent: thisMac,
                                       isSelected: accent.kind == thisMac.kind,
                                       caption: "This Mac")
                        }
                    }
                    .padding(.bottom, 14) // room for the caption under the selected swatch
                }
                RowDivider()
                SettingsRow(title: "Text highlight color") {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(accent.isMulticolor ? Color(hex: 0x007AFF).opacity(0.3) : accent.color.opacity(0.3))
                            .overlay(Circle().strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5))
                            .frame(width: 18, height: 18)
                        Text(highlightName)
                        PopupChevron()
                    }
                }
            }
        }
    }
}

struct MiniSwatch: View {
    @EnvironmentObject var store: AccentStore
    let accent: Accent
    let isSelected: Bool
    let caption: String

    var body: some View {
        Button {
            store.select(accent)
        } label: {
            Swatch(accent: accent, diameter: 22, isSelected: isSelected)
                .overlay(alignment: .bottom) {
                    if isSelected {
                        Text(caption)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .fixedSize()
                            .offset(y: 14)
                    }
                }
        }
        .buttonStyle(.plain)
        .help(caption)
    }
}

struct PopupChevron: View {
    var body: some View {
        Image(systemName: "chevron.up.chevron.down")
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(.secondary)
            .frame(width: 22, height: 22)
            .background(Circle().fill(Color.primary.opacity(0.07)))
    }
}

// MARK: - Controls

struct ControlsPreview: View {
    let accent: Accent

    // @State is a compiler macro in the macOS 27 SDK, and its plugin only ships with full Xcode.
    // A plain ObservableObject works with the Command Line Tools alone.
    @StateObject var model = ControlsModel()

    private let sidebarItems: [(icon: String, title: String)] = [
        ("circle.lefthalf.filled", "Appearance"),
        ("menubar.dock.rectangle", "Desktop & Dock"),
        ("sun.max", "Displays"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            GroupHeader("Controls")
            SettingsGroup {
                SettingsRow(title: "Pop-up button") {
                    Picker("", selection: $model.popup) {
                        Text("Selected").tag("Selected")
                        Text("Another option").tag("Another option")
                    }
                    .labelsHidden()
                    .fixedSize()
                }
                RowDivider()
                SettingsRow(title: "Checkbox") {
                    PreviewCheckbox(accent: accent, isOn: $model.checked, title: "Checked")
                }
                RowDivider()
                SettingsRow(title: "Radio buttons", alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        PreviewRadio(accent: accent, isOn: model.radio == 0, title: "Selected") { model.radio = 0 }
                        PreviewRadio(accent: accent, isOn: model.radio == 1, title: "Not selected") { model.radio = 1 }
                    }
                    .padding(.vertical, 4)
                }
                RowDivider()
                SettingsRow(title: "Switch") {
                    PreviewSwitch(accent: accent, isOn: $model.switchOn)
                }
                RowDivider()
                SettingsRow(title: "Slider") {
                    PreviewSlider(accent: accent, value: $model.slider)
                }
                RowDivider()
                SettingsRow(title: "Progress") {
                    PreviewProgress(accent: accent, value: model.slider)
                }
                RowDivider()
                SettingsRow(title: "Text selection") {
                    HStack(spacing: 0) {
                        Text("Some ")
                        Text("selected text")
                            .padding(.horizontal, 1)
                            .background(
                                (accent.isMulticolor ? Color(hex: 0x007AFF) : accent.color).opacity(0.3)
                            )
                        Text(" here")
                    }
                }
            }

            SettingsGroup {
                VStack(spacing: 2) {
                    ForEach(Array(sidebarItems.enumerated()), id: \.offset) { index, item in
                        let isSelected = model.listSelection == index
                        HStack(spacing: 8) {
                            Image(systemName: item.icon)
                                .frame(width: 18)
                            Text(item.title)
                            Spacer()
                        }
                        .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(isSelected ? accent.onColor : Color.primary)
                        .padding(.horizontal, 8)
                        .frame(height: 28)
                        .background(
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(isSelected ? AnyShapeStyle(accent.color) : AnyShapeStyle(Color.clear))
                        )
                        .contentShape(Rectangle())
                        .onTapGesture { model.listSelection = index }
                    }
                }
                .padding(6)
            }
            .padding(.top, 8)
        }
    }
}

final class ControlsModel: ObservableObject {
    @Published var popup = "Selected"
    @Published var checked = true
    @Published var radio = 0
    @Published var switchOn = true
    @Published var slider = 0.62
    @Published var listSelection = 0
}

// MARK: - Custom-drawn controls (so they show the *previewed* accent, not the app's live one)

struct PreviewCheckbox: View {
    let accent: Accent
    @Binding var isOn: Bool
    let title: String

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            HStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(isOn ? AnyShapeStyle(accent.color) : AnyShapeStyle(Color(nsColor: .controlBackgroundColor)))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .strokeBorder(Color.primary.opacity(isOn ? 0.06 : 0.25), lineWidth: 0.5)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 0.5, y: 0.5)
                    if isOn {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(accent.onColor)
                    }
                }
                .frame(width: 14, height: 14)
                Text(title)
            }
        }
        .buttonStyle(.plain)
    }
}

struct PreviewRadio: View {
    let accent: Accent
    let isOn: Bool
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(isOn ? AnyShapeStyle(accent.color) : AnyShapeStyle(Color(nsColor: .controlBackgroundColor)))
                        .overlay(Circle().strokeBorder(Color.primary.opacity(isOn ? 0.06 : 0.25), lineWidth: 0.5))
                        .shadow(color: .black.opacity(0.1), radius: 0.5, y: 0.5)
                    if isOn {
                        Circle().fill(accent.onColor).frame(width: 6, height: 6)
                    }
                }
                .frame(width: 14, height: 14)
                Text(title)
            }
        }
        .buttonStyle(.plain)
    }
}

struct PreviewSwitch: View {
    let accent: Accent
    @Binding var isOn: Bool

    var body: some View {
        Capsule()
            .fill(isOn ? AnyShapeStyle(accent.color) : AnyShapeStyle(Color.primary.opacity(0.12)))
            .frame(width: 34, height: 20)
            .overlay(alignment: isOn ? .trailing : .leading) {
                Circle()
                    .fill(.white)
                    .shadow(color: .black.opacity(0.25), radius: 1, y: 0.5)
                    .padding(2)
            }
            .contentShape(Capsule())
            .onTapGesture {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) { isOn.toggle() }
            }
    }
}

struct PreviewSlider: View {
    let accent: Accent
    @Binding var value: Double
    private let knobWidth: CGFloat = 22

    var body: some View {
        GeometryReader { geo in
            let travel = geo.size.width - knobWidth
            let x = travel * value
            ZStack(alignment: .leading) {
                Capsule().fill(Color.primary.opacity(0.12)).frame(height: 4)
                Capsule().fill(accent.color).frame(width: x + knobWidth / 2, height: 4)
                Capsule()
                    .fill(.white)
                    .overlay(Capsule().strokeBorder(Color.black.opacity(0.08), lineWidth: 0.5))
                    .shadow(color: .black.opacity(0.22), radius: 1.5, y: 0.5)
                    .frame(width: knobWidth, height: 14)
                    .offset(x: x)
            }
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0).onChanged { drag in
                    value = min(max((drag.location.x - knobWidth / 2) / travel, 0), 1)
                }
            )
        }
        .frame(width: 180, height: 20)
    }
}

struct PreviewProgress: View {
    let accent: Accent
    let value: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.primary.opacity(0.1))
                Capsule().fill(accent.color).frame(width: geo.size.width * value)
            }
        }
        .frame(width: 180, height: 6)
    }
}
