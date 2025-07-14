import SwiftUI

struct ProjectEditView: View {
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
    
    let project: Project?
    let onSave: (Project) -> Void
    let onCancel: () -> Void
    
    init(project: Project?, onSave: @escaping (Project) -> Void, onCancel: @escaping () -> Void) {
        self.project = project
        self.onSave = onSave
        self.onCancel = onCancel
        _title = State(initialValue: project?.title ?? "")
        _role = State(initialValue: project?.role ?? "")
        _company = State(initialValue: project?.company ?? "")
        _location = State(initialValue: project?.location ?? "")
        _startDate = State(initialValue: project?.startDate ?? Date())
        _endDate = State(initialValue: project?.endDate ?? Date())
        _isCurrent = State(initialValue: project?.isCurrent ?? false)
        _description = State(initialValue: project?.description ?? "")
        _technologies = State(initialValue: project?.technologies?.joined(separator: ", ") ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Project Details")) {
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
            .navigationTitle(project == nil ? "Add Project" : "Edit Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancel(); dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let techs = technologies.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                        let newProject = Project(
                            id: project?.id ?? UUID(),
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
                        onSave(newProject)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || company.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

struct ProjectEditView_Previews: PreviewProvider {
    static var previews: some View {
        ProjectEditView(project: nil, onSave: { _ in }, onCancel: {})
    }
} 