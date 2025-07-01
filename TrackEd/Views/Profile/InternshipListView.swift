import SwiftUI

struct InternshipListView: View {
    @State private var internships: [Internship] = []
    @State private var showingEdit = false
    @State private var editingInternship: Internship? = nil
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if internships.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "briefcase.badge.plus")
                            .font(.system(size: 48))
                            .foregroundColor(.accentColor)
                        Text("No Internships Yet")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text("Add your internships to showcase your experience and boost your resume.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button(action: { editingInternship = nil; showingEdit = true }) {
                            Label("Add Internship", systemImage: "plus")
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
                        ForEach(internships) { internship in
                            Button(action: { editingInternship = internship; showingEdit = true }) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(internship.title)
                                        .font(.headline)
                                    Text(internship.company)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text(internship.role)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 8)
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    if let idx = internships.firstIndex(of: internship) {
                                        internships.remove(at: idx)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .navigationTitle("Internships")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: { editingInternship = nil; showingEdit = true }) {
                                Image(systemName: "plus")
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showingEdit) {
                InternshipEditView(
                    internship: editingInternship,
                    onSave: { newInternship in
                        if let idx = internships.firstIndex(where: { $0.id == newInternship.id }) {
                            internships[idx] = newInternship
                        } else {
                            internships.append(newInternship)
                        }
                        showingEdit = false
                    },
                    onCancel: { showingEdit = false }
                )
            }
        }
    }
}

struct InternshipListView_Previews: PreviewProvider {
    static var previews: some View {
        InternshipListView()
    }
} 