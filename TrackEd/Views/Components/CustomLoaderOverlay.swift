import SwiftUI

struct CustomLoaderOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.18)
                .ignoresSafeArea()
            VStack(spacing: 18) {
                TrackEdLoader()
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(.systemBackground).opacity(0.95))
                    .shadow(color: Color.accentColor.opacity(0.12), radius: 16, y: 4)
            )
        }
    }
} 