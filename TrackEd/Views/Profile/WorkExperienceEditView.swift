import SwiftUI

struct WorkExperienceEditView: View {
    let workExperience: WorkExperience?
    let onSave: (WorkExperience) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var company = ""
    @State private var location = ""
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var isCurrent = false
    @State private var description = ""
    @State private var technologies: [String] = []
    @State private var newTechnology = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("appScreenBG")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Basic Information
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Basic Information")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color("appTextPrimary"))
                            
                            VStack(spacing: 12) {
                                CustomTextField(
                                    title: "Job Title",
                                    text: $title,
                                    placeholder: "e.g., Software Engineer"
                                )
                                
                                CustomTextField(
                                    title: "Company",
                                    text: $company,
                                    placeholder: "e.g., Google"
                                )
                                
                                CustomTextField(
                                    title: "Location",
                                    text: $location,
                                    placeholder: "e.g., San Francisco, CA"
                                )
                            }
                        }
                        .padding()
                        .background(Color("appCardBG"))
                        .cornerRadius(16)
                        
                        // Duration
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Duration")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color("appTextPrimary"))
                            
                            VStack(spacing: 12) {
                                DatePicker("Start Date", selection: $startDate, displayedComponents: [.date])
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                    .padding()
                                    .background(Color("appScreenBG"))
                                    .cornerRadius(12)
                                
                                Toggle("I currently work here", isOn: $isCurrent)
                                    .foregroundColor(Color("appTextPrimary"))
                                    .padding()
                                    .background(Color("appScreenBG"))
                                    .cornerRadius(12)
                                
                                if !isCurrent {
                                    DatePicker("End Date", selection: $endDate, displayedComponents: [.date])
                                        .datePickerStyle(.compact)
                                        .labelsHidden()
                                        .padding()
                                        .background(Color("appScreenBG"))
                                        .cornerRadius(12)
                                }
                            }
                        }
                        .padding()
                        .background(Color("appCardBG"))
                        .cornerRadius(16)
                        
                        // Description
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Description")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color("appTextPrimary"))
                            
                            TextEditor(text: $description)
                                .frame(minHeight: 120)
                                .padding()
                                .background(Color("appScreenBG"))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color("appStrokeGray"), lineWidth: 1)
                                )
                        }
                        .padding()
                        .background(Color("appCardBG"))
                        .cornerRadius(16)
                        
                        // Technologies
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Technologies & Skills")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color("appTextPrimary"))
                            
                            VStack(spacing: 12) {
                                HStack {
                                    TextField("Add technology", text: $newTechnology)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                    
                                    Button(action: addTechnology) {
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundColor(Color("appPrimaryAccent"))
                                            .font(.title2)
                                    }
                                    .disabled(newTechnology.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                }
                                
                                if !technologies.isEmpty {
                                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                                        ForEach(technologies, id: \.self) { technology in
                                            HStack {
                                                Text(technology)
                                                    .font(.caption)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(Color("appPrimaryAccent"))
                                                
                                                Spacer()
                                                
                                                Button(action: {
                                                    removeTechnology(technology)
                                                }) {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .foregroundColor(.red)
                                                        .font(.caption)
                                                }
                                            }
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
                    }
                    .padding()
                }
            }
            .navigationTitle(workExperience == nil ? "Add Work Experience" : "Edit Work Experience")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color("appTextSecondary"))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveWorkExperience()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(Color("appPrimaryAccent"))
                    .disabled(title.isEmpty || company.isEmpty)
                }
            }
        }
        .onAppear {
            loadWorkExperience()
        }
    }
    
    private func loadWorkExperience() {
        guard let workExperience = workExperience else { return }
        
        title = workExperience.title
        company = workExperience.company
        location = workExperience.location
        startDate = workExperience.startDate
        endDate = workExperience.endDate ?? Date()
        isCurrent = workExperience.isCurrent
        description = workExperience.description
        technologies = workExperience.technologies ?? []
    }
    
    private func addTechnology() {
        let trimmedTechnology = newTechnology.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTechnology.isEmpty && !technologies.contains(trimmedTechnology) {
            technologies.append(trimmedTechnology)
            newTechnology = ""
        }
    }
    
    private func removeTechnology(_ technology: String) {
        technologies.removeAll { $0 == technology }
    }
    
    private func saveWorkExperience() {
        let workExperience = WorkExperience(
            id: workExperience?.id ?? UUID(),
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            company: company.trimmingCharacters(in: .whitespacesAndNewlines),
            location: location.trimmingCharacters(in: .whitespacesAndNewlines),
            startDate: startDate,
            endDate: isCurrent ? Date() : endDate,
            isCurrent: isCurrent,
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            technologies: technologies
        )
        
        onSave(workExperience)
        dismiss()
    }
}

struct CustomTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Color("appTextPrimary"))
            
            TextField(placeholder, text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}

#Preview {
    WorkExperienceEditView(workExperience: nil) { _ in }
} 