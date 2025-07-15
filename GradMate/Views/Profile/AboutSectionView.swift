import SwiftUI

struct AboutSectionView: View {
    var onEdit: () -> Void

    var body: some View {
        SectionCard(title: "About Me", addAction: onEdit) {
            Text("Motivated student passionate about product management, technology, and design. Always eager to learn and grow!")
                .font(.body)
                .foregroundColor(.primary)
                .padding(.vertical, 4)
        }
    }
} 