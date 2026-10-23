import SwiftUI

/// A styled card container used throughout the app.
struct NudgeCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(Theme.cardPadding)
            .background(NudgeColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
    }
}
