import SwiftUI

struct CertificationEditView: View {
    let certification: Certification?
    let onSave: (Certification) -> Void
    let onCancel: () -> Void
    
    @State private var title: String = ""
    @State private var organization: String = ""
    @State private var location: String = ""
    @State private var dateReceived: Date = Date()
    @State private var dateExpiry: Date = Date()
    @State private var hasExpiryDate: Bool = false
    @State private var description: String = ""
    @State private var credentialID: String = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("appScreenBG").ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Basic Information Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Basic Information")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color("appTextPrimary"))
                            
                            VStack(spacing: 12) {
                                CustomTextField(
                                    title: "Certification Title",
                                    text: $title,
                                    placeholder: "e.g., AWS Certified Solutions Architect"
                                )
                                
                                CustomTextField(
                                    title: "Issuing Organization",
                                    text: $organization,
                                    placeholder: "e.g., Amazon Web Services"
                                )
                                
                                CustomTextField(
                                    title: "Location",
                                    text: $location,
                                    placeholder: "e.g., Online"
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
                                DatePicker("Date Received", selection: $dateReceived, displayedComponents: [.date])
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                    .padding()
                                    .background(Color("appStrokeGray"))
                                    .cornerRadius(12)
                                
                                Toggle("Has Expiry Date", isOn: $hasExpiryDate)
                                    .foregroundColor(Color("appTextPrimary"))
                                    .toggleStyle(SwitchToggleStyle(tint: Color("appPrimaryAccent")))
                                    .padding()
                                    .background(Color("appStrokeGray"))
                                    .cornerRadius(12)
                                
                                if hasExpiryDate {
                                    DatePicker("Expiry Date", selection: $dateExpiry, displayedComponents: [.date])
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
                        
                        // Additional Information Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Additional Information")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color("appTextPrimary"))
                            
                            VStack(spacing: 12) {
                                CustomTextField(
                                    title: "Credential ID",
                                    text: $credentialID,
                                    placeholder: "e.g., AWS-123456"
                                )
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Description")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(Color("appTextSecondary"))
                                    
                                    TextField("Description", text: $description, axis: .vertical)
                                        .lineLimit(3...6)
                                        .textFieldStyle(CustomTextFieldStyle())
                                }
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
            .navigationTitle(certification == nil ? "Add Certification" : "Edit Certification")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .foregroundColor(Color("appTextSecondary"))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let newCertification = Certification(
                            id: certification?.id ?? UUID(),
                            title: title,
                            organization: organization,
                            location: location,
                            dateReceived: dateReceived,
                            dateExpiry: hasExpiryDate ? dateExpiry : nil,
                            description: description,
                            credentialID: credentialID.isEmpty ? nil : credentialID
                        )
                        onSave(newCertification)
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(Color("appPrimaryAccent"))
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || 
                             organization.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                if let cert = certification {
                    title = cert.title
                    organization = cert.organization
                    location = cert.location
                    dateReceived = cert.dateReceived
                    if let expiry = cert.dateExpiry {
                        dateExpiry = expiry
                        hasExpiryDate = true
                    }
                    description = cert.description
                    credentialID = cert.credentialID ?? ""
                }
            }
        }
    }
}

// Note: CustomTextField and CustomTextFieldStyle are now defined in SharedFormComponents.swift

struct CertificationEditView_Previews: PreviewProvider {
    static var previews: some View {
        CertificationEditView(
            certification: nil,
            onSave: { _ in },
            onCancel: { }
        )
    }
} 