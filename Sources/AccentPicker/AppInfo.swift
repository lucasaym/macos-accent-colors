import AppKit
import SwiftUI

/// Name, author and links, shown in the main window, the About panel and the info window.
enum AppInfo {
    static let name = "Accent Picker"
    static let author = "Lucas Aymard"
    static let repoURL = URL(string: "https://github.com/lucasaym/macos-accent-colors")!
    static let articleURL = URL(string: "https://georgegarside.com/blog/macos/imac-m1-accent-colours-any-mac/")!

    static var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    static func open(_ url: URL) {
        NSWorkspace.shared.open(url)
    }

    static func showAbout() {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let base: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize),
            .foregroundColor: NSColor.secondaryLabelColor,
            .paragraphStyle: paragraph,
        ]
        let credits = NSMutableAttributedString(string: "Made by \(author)\n", attributes: base)
        var link = base
        link[.link] = repoURL
        credits.append(NSAttributedString(string: "Source code on GitHub", attributes: link))

        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: name,
            .credits: credits,
        ])
        NSApp.activate(ignoringOtherApps: true)
    }
}

/// The "How It Works" window, built with AppKit so it needs nothing beyond the Command Line Tools.
enum InfoWindow {
    private static var window: NSWindow?

    static func show() {
        if window == nil {
            let hosting = NSHostingView(rootView: InfoView())
            hosting.sizingOptions = [.minSize]
            let newWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 540, height: 680),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            newWindow.title = "How It Works"
            newWindow.isReleasedWhenClosed = false
            newWindow.contentView = hosting
            newWindow.center()
            window = newWindow
        }
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
