import SwiftUI

struct TrackEdLoader: View {
    @State private var fillProgress: CGFloat = 0.0
    let animationDuration: Double = 1.8
    let text = "TrackEd"
    
    var body: some View {
        ZStack {
            // Background gray text
            Text(text)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(Color(.systemGray4))
                .overlay(
                    // Animated fill
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Text(text)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(Color("appPrimaryAccent"))
                                .mask(
                                    Rectangle()
                                        .frame(width: geo.size.width * fillProgress)
                                )
                        }
                    }
                )
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: animationDuration).repeatForever(autoreverses: false)) {
                fillProgress = 1.0
            }
        }
        .accessibilityLabel("Loading TrackEd")
    }
}

struct TrackEdLoader_Previews: PreviewProvider {
    static var previews: some View {
        TrackEdLoader()
            .padding()
            .previewLayout(.sizeThatFits)
    }
} 