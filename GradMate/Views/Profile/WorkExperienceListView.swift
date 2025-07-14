import SwiftUI

struct WorkExperienceListView: View {
    @State private var workExperiences: [WorkExperience] = []
    @State private var showingAddWorkExperience = false
    @State private var selectedWorkExperience: WorkExperience?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("appScreenBG")
                    .ignoresSafeArea()
                
                if workExperiences.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "briefcase.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Work Experience Yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(Color("appTextPrimary"))
                        
                        Text("Add your work experience to build a comprehensive resume")
                            .font(.body)
                            .foregroundColor(Color("appTextSecondary"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Button(action: {
                            showingAddWorkExperience = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Work Experience")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color("appPrimaryAccent"))
                            .cornerRadius(12)
                        }
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(workExperiences) { workExperience in
                                WorkExperienceCard(workExperience: workExperience) {
                                    selectedWorkExperience = workExperience
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Work Experience")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddWorkExperience = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(Color("appPrimaryAccent"))
                    }
                }
            }
            .sheet(isPresented: $showingAddWorkExperience) {
                WorkExperienceEditView(workExperience: nil) { newWorkExperience in
                    workExperiences.append(newWorkExperience)
                }
            }
            .sheet(item: $selectedWorkExperience) { workExperience in
                WorkExperienceEditView(workExperience: workExperience) { updatedWorkExperience in
                    if let index = workExperiences.firstIndex(where: { $0.id == workExperience.id }) {
                        workExperiences[index] = updatedWorkExperience
                    }
                }
            }
        }
        .onAppear {
            loadWorkExperiences()
        }
    }
    
    private func loadWorkExperiences() {
        // TODO: Load from Core Data or other storage
        // For now, using sample data
        workExperiences = [
            WorkExperience(
                title: "Software Engineer Intern",
                company: "Tech Corp",
                location: "San Francisco, CA",
                startDate: Date().addingTimeInterval(-6 * 30 * 24 * 60 * 60), // 6 months ago
                endDate: Date(),
                isCurrent: true,
                description: "Developed and maintained web applications using React and Node.js. Collaborated with cross-functional teams to deliver high-quality software solutions.",
                technologies: ["React", "Node.js", "JavaScript", "MongoDB"]
            ),
            WorkExperience(
                title: "Research Assistant",
                company: "University Lab",
                location: "Boston, MA",
                startDate: Date().addingTimeInterval(-12 * 30 * 24 * 60 * 60), // 1 year ago
                endDate: Date().addingTimeInterval(-6 * 30 * 24 * 60 * 60), // 6 months ago
                isCurrent: false,
                description: "Conducted research on machine learning algorithms and data analysis. Published findings in academic journals.",
                technologies: ["Python", "TensorFlow", "Pandas", "Scikit-learn"]
            )
        ]
    }
}

struct WorkExperienceCard: View {
    let workExperience: WorkExperience
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(workExperience.title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color("appTextPrimary"))
                        
                        Text(workExperience.company)
                            .font(.subheadline)
                            .foregroundColor(Color("appPrimaryAccent"))
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                    
                    if workExperience.isCurrent {
                        Text("Current")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color("appSuccess"))
                            .cornerRadius(8)
                    }
                }
                
                HStack {
                    Image(systemName: "location.fill")
                        .font(.caption)
                        .foregroundColor(Color("appTextSecondary"))
                    
                    Text(workExperience.location)
                        .font(.caption)
                        .foregroundColor(Color("appTextSecondary"))
                    
                    Spacer()
                    
                    Text(formatDateRange(start: workExperience.startDate, end: workExperience.endDate, isCurrent: workExperience.isCurrent))
                        .font(.caption)
                        .foregroundColor(Color("appTextSecondary"))
                }
                
                if !workExperience.description.isEmpty {
                    Text(workExperience.description)
                        .font(.body)
                        .foregroundColor(Color("appTextSecondary"))
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
                
                if let technologies = workExperience.technologies, !technologies.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(technologies, id: \.self) { technology in
                                Text(technology)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(Color("appPrimaryAccent"))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color("appPrimaryAccent").opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color("appCardBG"))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatDateRange(start: Date, end: Date?, isCurrent: Bool) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM yyyy"
        
        let startString = dateFormatter.string(from: start)
        let endString = isCurrent || end == nil ? "Present" : dateFormatter.string(from: end!)
        
        return "\(startString) - \(endString)"
    }
}

#Preview {
    WorkExperienceListView()
} 
