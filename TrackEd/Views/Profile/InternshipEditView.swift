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
            Form {
                Section(header: Text("Internship Details")) {
                    TextField("Title", text: $title)
                    TextField("Role", text: $role)
                    TextField("Company/Organization", text: $company)
                    TextField("Location", text: $location)
                }
                Section(header: Text("Dates")) {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    if !isCurrent {
                        DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                    }
                    Toggle("Currently Working", isOn: $isCurrent)
                }
                Section(header: Text("Description")) {
                    TextEditor(text: $description)
                        .frame(height: 80)
                }
                Section(header: Text("Technologies (comma separated)")) {
                    TextField("e.g. Swift, Firebase, Figma", text: $technologies)
                }
            }
            .navigationTitle(internship == nil ? "Add Internship" : "Edit Internship")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancel(); dismiss() }
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
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || company.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

struct InternshipEditView_Previews: PreviewProvider {
    static var previews: some View {
        InternshipEditView(internship: nil, onSave: { _ in }, onCancel: {})
    }
} 