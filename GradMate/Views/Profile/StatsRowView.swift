import SwiftUI

struct StatsRowView: View {
    var body: some View {
        HStack(spacing: 16) {
            StatCard(title: "Projects", value: "5", icon: "folder.fill")
            StatCard(title: "Certs", value: "3", icon: "rosette")
            StatCard(title: "Internships", value: "2", icon: "briefcase.fill")
            StatCard(title: "Skills", value: "8", icon: "star.fill")
        }
        .frame(maxWidth: .infinity)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Color("appPrimaryAccent"))
            Text(value)
                .font(.title3.bold())
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("appCardBG"))
                .shadow(color: Color.black.opacity(0.04), radius: 4, y: 2)
        )
    }
} 