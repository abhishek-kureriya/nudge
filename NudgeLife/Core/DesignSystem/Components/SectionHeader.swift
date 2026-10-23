import SwiftUI

/// A styled section header for grouped lists.
struct SectionHeader: View {
    let title: String
    var color: Color = NudgeColors.textPrimary

    var body: some View {
        Text(title)
            .font(NudgeTypography.sectionHeader)
            .foregroundStyle(color)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
