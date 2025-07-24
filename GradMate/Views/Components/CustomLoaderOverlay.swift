import SwiftUI

struct CustomLoaderOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.18)
                .ignoresSafeArea()
            VStack(spacing: 18) {
                GradMateLoader()
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color("appCardBG"))
                    .shadow(color: Color("appPrimaryAccent").opacity(0.12), radius: 16, x: 0, y: 4)
            )
        }
    }
} 