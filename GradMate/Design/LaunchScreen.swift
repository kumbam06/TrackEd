import SwiftUI

struct LaunchScreen: View {
    var body: some View {
        ZStack {
            Color("appScreenBG").ignoresSafeArea()
            VStack(spacing: 32) {
                Image(systemName: "star.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(Color("appPrimaryAccent"))
                Text("GradMate")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color("appPrimaryAccent"))
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color("appPrimaryAccent")))
            }
        }
    }
}

#Preview {
    Group {
        LaunchScreen()
    }
}
