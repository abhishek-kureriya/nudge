import SwiftUI

extension View {
    /// Apply the app's preferred color scheme based on the user's appearance setting.
    func nudgeColorScheme() -> some View {
        modifier(NudgeColorSchemeModifier())
    }
}

private struct NudgeColorSchemeModifier: ViewModifier {
    @AppStorage("appearance") private var appearance: String = "system"

    func body(content: Content) -> some View {
        content.preferredColorScheme(colorScheme)
    }

    private var colorScheme: ColorScheme? {
        switch appearance {
        case "light": .light
        case "dark": .dark
        default: nil
        }
    }
}
