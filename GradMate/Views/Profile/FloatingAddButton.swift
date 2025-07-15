import SwiftUI

struct FloatingAddButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .padding()
                .background(Circle().fill(Color("appPrimaryAccent")))
                .shadow(radius: 8)
        }
        .padding(.trailing, 24)
        .padding(.bottom, 24)
    }
} 