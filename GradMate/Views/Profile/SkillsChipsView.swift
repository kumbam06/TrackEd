import SwiftUI

struct SkillsChipsView: View {
    let skills = ["Swift", "UI/UX", "Leadership", "Python", "Figma"]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(skills, id: \.self) { skill in
                    Text(skill)
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color("appPrimaryAccent").opacity(0.12))
                        )
                }
            }
        }
    }
} 