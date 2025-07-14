import SwiftUI

struct CertificationListView: View {
    @EnvironmentObject private var careerDataService: CareerDataService
    @State private var showingEdit = false
    @State private var editingCertification: Certification? = nil
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if careerDataService.certificationModels.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "rosette")
                            .font(.system(size: 48))
                            .foregroundColor(.accentColor)
                        Text("No Certifications Yet")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text("Add your certifications to strengthen your resume.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button(action: { editingCertification = nil; showingEdit = true }) {
                            Label("Add Certification", systemImage: "plus")
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
                        ForEach(careerDataService.certificationModels) { cert in
                            Button(action: { editingCertification = cert; showingEdit = true }) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(cert.title)
                                        .font(.headline)
                                    Text(cert.organization)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    if let id = cert.credentialID, !id.isEmpty {
                                        Text("ID: \(id)")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    careerDataService.deleteCertification(cert)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .navigationTitle("Certifications")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: { editingCertification = nil; showingEdit = true }) {
                                Image(systemName: "plus")
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showingEdit) {
                CertificationEditView(
                    certification: editingCertification,
                    onSave: { newCert in
                        if editingCertification != nil {
                            careerDataService.updateCertification(newCert)
                        } else {
                            careerDataService.createCertification(newCert)
                        }
                        showingEdit = false
                    },
                    onCancel: { showingEdit = false }
                )
            }
        }
    }
}

struct CertificationListView_Previews: PreviewProvider {
    static var previews: some View {
        CertificationListView()
            .environmentObject(CareerDataService())
    }
} 