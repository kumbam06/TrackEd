import SwiftUI

struct ProfileHeaderView: View {
    var onEdit: () -> Void

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Optional: Cover image
            RoundedRectangle(cornerRadius: 24)
                .fill(Color("appPrimaryAccent").opacity(0.18))
                .frame(height: 120)
                .blur(radius: 6)
                .offset(y: 40)

            VStack(spacing: 10) {
                ZStack(alignment: .bottomTrailing) {
                    Image("profile_photo_placeholder")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 96, height: 96)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color("appPrimaryAccent"), lineWidth: 3))

                    Button(action: onEdit) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(Color("appPrimaryAccent"))
                            .background(Circle().fill(Color(.systemBackground)))
                    }
                    .offset(x: 8, y: 8)
                }
                Text("Jane Doe")
                    .font(.title.bold())
                Text("Aspiring Product Manager • San Francisco, CA")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 16)
        }
    }
} 