import SwiftUI
import AppKit

/// Secondary window: how the trick works, what the app changes, and credits.
struct InfoView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                InfoBlock("Where the colors come from") {
                    Text("The colorful iMacs (2021 and 2024) and the MacBook Neo have accent colors matched to their finish. Every recent copy of macOS contains them, but System Settings only offers them, as \u{201C}This Mac\u{201D}, on those models.")
                }

                InfoBlock("The two settings behind it") {
                    Text("macOS can be told to behave as if it were running on one of those Macs. Two global preferences do it: the first turns the simulation on, the second picks the color by number.")
                    CodeBox("""
                    defaults write -g NSColorSimulateHardwareAccent -bool YES
                    defaults write -g NSColorSimulatedHardwareEnclosureNumber -int 16
                    """)
                    Text("Accent Picker writes the same two preferences when you click a hardware color. Nothing is installed in the system, and no administrator password is needed.")
                }

                InfoBlock("Color numbers") {
                    SettingsGroup {
                        ForEach(Array(hardwareFamilies.enumerated()), id: \.element.id) { index, family in
                            if index > 0 { RowDivider() }
                            NumberRow(family: family)
                        }
                    }
                    Text("3–8 come from the original article. 9–17 were found later by other people: Apple doesn't document these numbers, so a macOS update could change them.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                InfoBlock("What the app changes") {
                    SettingsGroup {
                        KeyRow(choice: "Multicolor", effect: "Removes AppleAccentColor")
                        RowDivider()
                        KeyRow(choice: "System color", effect: "AppleAccentColor = −1 to 6")
                        RowDivider()
                        KeyRow(choice: "Hardware color", effect: "The two settings above")
                    }
                }

                InfoBlock("Good to know") {
                    VStack(alignment: .leading, spacing: 6) {
                        Bullet("Apps that are already open keep their old color until you quit and reopen them.")
                        Bullet("If a hardware color doesn't appear, choose \u{201C}This Mac\u{201D} once in System Settings › Appearance.")
                        Bullet("Apps that draw their own controls may ignore the accent color entirely.")
                    }
                }

                InfoBlock("Undo everything") {
                    Text("Click **Reset** in the main window, or run:")
                    CodeBox("""
                    defaults delete -g NSColorSimulateHardwareAccent
                    defaults delete -g NSColorSimulatedHardwareEnclosureNumber
                    """)
                }

                InfoBlock("Credits") {
                    Text("The trick was first described by George Garside in \u{201C}Use iMac M1 accent colours on any Mac\u{201D} (2021).")
                    HStack(spacing: 16) {
                        Link(destination: AppInfo.articleURL) {
                            Label("Read the original article", systemImage: "doc.text")
                        }
                        Link(destination: AppInfo.repoURL) {
                            Label("Source code on GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                        }
                    }
                }
            }
            .padding(30)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minWidth: 480, idealWidth: 540, minHeight: 420, idealHeight: 680)
    }

    private var hardwareFamilies: [AccentFamily] {
        [.iMac2021, .iMac2024, .macBookNeo]
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 64, height: 64)
            VStack(alignment: .leading, spacing: 3) {
                Text(AppInfo.name)
                    .font(.system(size: 20, weight: .bold))
                Text("Version \(AppInfo.version) · by \(AppInfo.author)")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Pieces

struct InfoBlock<Content: View>: View {
    let title: String
    let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.system(size: 15, weight: .semibold))
            content
        }
        .font(.system(size: 13))
        .fixedSize(horizontal: false, vertical: true)
    }
}

struct CodeBox: View {
    let code: String
    init(_ code: String) { self.code = code }

    var body: some View {
        HStack(alignment: .top) {
            Text(code)
                .font(.system(size: 11.5, design: .monospaced))
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(code, forType: .string)
            } label: {
                Image(systemName: "doc.on.doc")
            }
            .buttonStyle(.borderless)
            .help("Copy")
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.primary.opacity(0.05))
        )
    }
}

struct NumberRow: View {
    let family: AccentFamily

    var body: some View {
        HStack(alignment: .center) {
            Text(family.title.replacingOccurrences(of: " Accents", with: ""))
            Spacer(minLength: 12)
            HStack(spacing: 2) {
                ForEach(family.accents) { accent in
                    VStack(spacing: 0) {
                        Swatch(accent: accent, diameter: 20)
                        Text(accent.code.map { "\($0)" } ?? "")
                            .font(.system(size: 10, weight: .medium).monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    .help(accent.name)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }
}

struct KeyRow: View {
    let choice: String
    let effect: String

    var body: some View {
        HStack {
            Text(choice)
            Spacer(minLength: 12)
            Text(effect)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .frame(minHeight: 36)
    }
}

struct Bullet: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text("•").foregroundStyle(.secondary)
            Text(text)
        }
    }
}
