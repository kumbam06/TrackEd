import SwiftUI

struct InternshipEditView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var role: String
    @State private var company: String
    @State private var location: String
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var isCurrent: Bool
    @State private var description: String
    @State private var technologies: String
    
    let internship: Internship?
    let onSave: (Internship) -> Void
    let onCancel: () -> Void
    
    init(internship: Internship?, onSave: @escaping (Internship) -> Void, onCancel: @escaping () -> Void) {
        self.internship = internship
        self.onSave = onSave
        self.onCancel = onCancel
        _title = State(initialValue: internship?.title ?? "")
        _role = State(initialValue: internship?.role ?? "")
        _company = State(initialValue: internship?.company ?? "")
        _location = State(initialValue: internship?.location ?? "")
        _startDate = State(initialValue: internship?.startDate ?? Date())
        _endDate = State(initialValue: internship?.endDate ?? Date())
        _isCurrent = State(initialValue: internship?.isCurrent ?? false)
        _description = State(initialValue: internship?.description ?? "")
        _technologies = State(initialValue: internship?.technologies?.joined(separator: ", ") ?? "")
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("appScreenBG").ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Internship Details Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Internship Details")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color("appTextPrimary"))
                            
                            VStack(spacing: 12) {
                                CustomTextField(
                                    title: "Title",
                                    text: $title,
                                    placeholder: "Internship title"
                                )
                                
                                CustomTextField(
                                    title: "Role",
                                    text: $role,
                                    placeholder: "Your role in the internship"
                                )
                                
                                CustomTextField(
                                    title: "Company/Organization",
                                    text: $company,
                                    placeholder: "Company or organization name"
                                )
                                
                                CustomTextField(
                                    title: "Location",
                                    text: $location,
                                    placeholder: "Internship location"
                                )
                            }
                        }
                        .padding()
                        .background(Color("appCardBG"))
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color("appStrokeGray"), lineWidth: 1))
                        
                        // Dates Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Dates")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color("appTextPrimary"))
                            
                            VStack(spacing: 12) {
                                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                    .padding()
                                    .background(Color("appStrokeGray"))
                                    .cornerRadius(12)
                                
                                Toggle("Currently Working", isOn: $isCurrent)
                                    .foregroundColor(Color("appTextPrimary"))
                                    .toggleStyle(SwitchToggleStyle(tint: Color("appPrimaryAccent")))
                                    .padding()
                                    .background(Color("appStrokeGray"))
                                    .cornerRadius(12)
                                
                                if !isCurrent {
                                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                                        .datePickerStyle(.compact)
                                        .labelsHidden()
                                        .padding()
                                        .background(Color("appStrokeGray"))
                                        .cornerRadius(12)
                                }
                            }
                        }
                        .padding()
                        .background(Color("appCardBG"))
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color("appStrokeGray"), lineWidth: 1))
                        
                        // Description Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Description")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color("appTextPrimary"))
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Internship Description")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(Color("appTextSecondary"))
                                
                                TextEditor(text: $description)
                                    .frame(height: 80)
                                    .padding(12)
                                    .background(Color("appStrokeGray"))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color("appStrokeGray"), lineWidth: 1)
                                    )
                            }
                        }
                        .padding()
                        .background(Color("appCardBG"))
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color("appStrokeGray"), lineWidth: 1))
                        
                        // Technologies Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Technologies")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color("appTextPrimary"))
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Technologies Used (comma separated)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(Color("appTextSecondary"))
                                
                                TextField("e.g. Swift, Firebase, Figma", text: $technologies)
                                    .textFieldStyle(CustomTextFieldStyle())
                            }
                        }
                        .padding()
                        .background(Color("appCardBG"))
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color("appStrokeGray"), lineWidth: 1))
                    }
                    .padding()
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle(internship == nil ? "Add Internship" : "Edit Internship")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { 
                        onCancel()
                        dismiss() 
                    }
                    .foregroundColor(Color("appTextSecondary"))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let techs = technologies.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                        let newInternship = Internship(
                            id: internship?.id ?? UUID(),
                            title: title,
                            role: role,
                            company: company,
                            location: location,
                            startDate: startDate,
                            endDate: isCurrent ? nil : endDate,
                            isCurrent: isCurrent,
                            description: description,
                            technologies: techs.isEmpty ? nil : techs
                        )
                        onSave(newInternship)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(Color("appPrimaryAccent"))
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || company.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

// Note: CustomTextField and CustomTextFieldStyle are now defined in SharedFormComponents.swift

struct InternshipEditView_Previews: PreviewProvider {
    static var previews: some View {
        InternshipEditView(internship: nil, onSave: { _ in }, onCancel: {})
    }
} 