import SwiftUI
import AppKit

@main
struct AccentPickerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Window("Accent Picker", id: "main") {
            ContentView()
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 520, height: 880)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About \(AppInfo.name)") { AppInfo.showAbout() }
            }
            CommandGroup(replacing: .help) {
                Button("How It Works") { InfoWindow.show() }
                    .keyboardShortcut("?", modifiers: .command)
                Divider()
                Button("\(AppInfo.name) on GitHub") { AppInfo.open(AppInfo.repoURL) }
                Button("Original Article by George Garside") { AppInfo.open(AppInfo.articleURL) }
            }
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Makes `swift run` behave like a real app (Dock icon, focus).
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
