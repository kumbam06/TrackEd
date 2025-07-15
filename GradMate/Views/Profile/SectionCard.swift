import SwiftUI

struct SectionCard<Content: View>: View {
    let title: String
    let addAction: () -> Void
    let content: Content

    init(title: String, addAction: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.title = title
        self.addAction = addAction
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Button(action: addAction) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(Color("appPrimaryAccent"))
                }
            }
            content
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color("appCardBG"))
                .shadow(color: Color.black.opacity(0.03), radius: 3, y: 1)
        )
    }
} 