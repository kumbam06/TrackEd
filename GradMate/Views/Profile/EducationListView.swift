import SwiftUI

struct EducationListView: View {
    let edus = [
        (school: "Stanford University", degree: "BS Computer Science", year: "2024")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(edus, id: \.school) { edu in
                VStack(alignment: .leading, spacing: 2) {
                    Text(edu.school)
                        .font(.subheadline.bold())
                    Text(edu.degree)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(edu.year)
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