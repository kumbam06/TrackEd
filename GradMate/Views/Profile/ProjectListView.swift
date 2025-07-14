import SwiftUI

struct ProjectListView: View {
    @State private var projects: [Project] = []
    @State private var showingEdit = false
    @State private var editingProject: Project? = nil
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if projects.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 48))
                            .foregroundColor(.accentColor)
                        Text("No Projects Yet")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text("Add your projects to showcase your work and boost your resume.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button(action: { editingProject = nil; showingEdit = true }) {
                            Label("Add Project", systemImage: "plus")
                                .font(.headline)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.top, 60)
                } else {
                    List {
                        ForEach(projects) { project in
                            Button(action: { editingProject = project; showingEdit = true }) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(project.title)
                                        .font(.headline)
                                    Text(project.company)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text(project.role)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 8)
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    if let idx = projects.firstIndex(of: project) {
                                        projects.remove(at: idx)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .navigationTitle("Projects")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: { editingProject = nil; showingEdit = true }) {
                                Image(systemName: "plus")
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showingEdit) {
                ProjectEditView(
                    project: editingProject,
                    onSave: { newProject in
                        if let idx = projects.firstIndex(where: { $0.id == newProject.id }) {
                            projects[idx] = newProject
                        } else {
                            projects.append(newProject)
                        }
                        showingEdit = false
                    },
                    onCancel: { showingEdit = false }
                )
            }
        }
    }
}

struct ProjectListView_Previews: PreviewProvider {
    static var previews: some View {
        ProjectListView()
    }
} 