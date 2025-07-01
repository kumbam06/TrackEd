import SwiftUI

struct SplashView: View {
    var body: some View {
        VStack {
            Spacer()
            ProgressView("Loading...")
                .progressViewStyle(CircularProgressViewStyle())
                .padding()
            Spacer()
        }
    }
} 