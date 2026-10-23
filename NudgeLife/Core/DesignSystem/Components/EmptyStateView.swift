import SwiftUI

/// A reusable empty state view with an SF Symbol, title, and optional message.
struct EmptyStateView: View {
    let symbol: String
    let title: String
    var message: String?

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: symbol)
        } description: {
            if let message {
                Text(message)
            }
        }
    }
}
