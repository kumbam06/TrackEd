import SwiftUI

struct ProjectsListView: View {
    let projects = [
        (title: "GradMate App", desc: "Student productivity app"),
        (title: "Portfolio Website", desc: "Personal branding site")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(projects, id: \.title) { proj in
                VStack(alignment: .leading, spacing: 2) {
                    Text(proj.title)
                        .font(.subheadline.bold())
                    Text(proj.desc)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color("appPrimaryAccent").opacity(0.08))
                )
            }
        }
    }
} 