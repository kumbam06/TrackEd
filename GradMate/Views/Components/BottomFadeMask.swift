import SwiftUI

extension View {
    func bottomFadeMask(fadeHeight: CGFloat = 24) -> some View {
        self.mask(
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: .white, location: 0),
                    .init(color: .white, location: 1 - (fadeHeight / 300)),
                    .init(color: .white.opacity(0.5), location: 1 - (fadeHeight / 600)),
                    .init(color: .clear, location: 1)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
} 