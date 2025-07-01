import SwiftUI

struct LaunchScreen: View {
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack(spacing: 32) {
                Image(systemName: "star.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.accentColor)
                Text("TrackEd")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.accentColor)
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
            }
        }
    }
}

#Preview {
    Group {
        LaunchScreen()
    }
}
