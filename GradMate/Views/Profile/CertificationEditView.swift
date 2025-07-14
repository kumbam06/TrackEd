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
            Form {
                Section(header: Text("Basic Information")) {
                    TextField("Certification Title", text: $title)
                        .accessibilityLabel("Certification title")
                    
                    TextField("Issuing Organization", text: $organization)
                        .accessibilityLabel("Issuing organization")
                    
                    TextField("Location", text: $location)
                        .accessibilityLabel("Location")
                }
                
                Section(header: Text("Dates")) {
                    DatePicker("Date Received", selection: $dateReceived, displayedComponents: [.date])
                    
                    Toggle("Has Expiry Date", isOn: $hasExpiryDate)
                    
                    if hasExpiryDate {
                        DatePicker("Expiry Date", selection: $dateExpiry, displayedComponents: [.date])
                    }
                }
                
                Section(header: Text("Additional Information")) {
                    TextField("Credential ID", text: $credentialID)
                        .accessibilityLabel("Credential ID")
                    
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                        .accessibilityLabel("Description")
                }
            }
            .navigationTitle(certification == nil ? "Add Certification" : "Edit Certification")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
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

struct CertificationEditView_Previews: PreviewProvider {
    static var previews: some View {
        CertificationEditView(
            certification: nil,
            onSave: { _ in },
            onCancel: { }
        )
    }
} 