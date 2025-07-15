import SwiftUI

struct ExperienceListView: View {
    let experiences = [
        (role: "Product Intern", company: "TechCorp", period: "2023"),
        (role: "UX Designer", company: "Designify", period: "2022")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(experiences, id: \.role) { exp in
                VStack(alignment: .leading, spacing: 2) {
                    Text(exp.role)
                        .font(.subheadline.bold())
                    Text("@ " + exp.company)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(exp.period)
                        .font(.caption2)
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