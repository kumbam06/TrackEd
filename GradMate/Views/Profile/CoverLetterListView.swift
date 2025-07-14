import SwiftUI

struct CoverLetterListView: View {
    @EnvironmentObject private var coverLetterDataService: CoverLetterDataService
    @Environment(\.dismiss) private var dismiss
    @State private var showingComposer = false
    @State private var editingCoverLetter: CoverLetterEntity? = nil
    @State private var showingDeleteAlert = false
    @State private var coverLetterToDelete: CoverLetterEntity? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if coverLetterDataService.coverLetters.isEmpty {
                    emptyStateView
                } else {
                    coverLettersList
                }
            }
            .navigationTitle("Cover Letters")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingComposer = true }) {
                        Image(systemName: "plus")
                            .font(.title3)
                            .foregroundColor(.accentColor)
                    }
                }
            }
            .sheet(isPresented: $showingComposer) {
                CoverLetterComposerView()
                    .environmentObject(coverLetterDataService)
            }
            .alert("Delete Cover Letter", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let coverLetter = coverLetterToDelete {
                        deleteCoverLetter(coverLetter)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this cover letter? This action cannot be undone.")
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.accentColor.opacity(0.1),
                                Color.accentColor.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "doc.text")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(.accentColor)
            }
            
            VStack(spacing: 8) {
                Text("No Cover Letters Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Create your first cover letter to streamline your job applications")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: { showingComposer = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Create Your First Cover Letter")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [.accentColor, .accentColor.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                )
            }
            
            Spacer()
        }
        .padding(.horizontal, 40)
    }
    
    private var coverLettersList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(coverLetterDataService.coverLetters, id: \.id) { coverLetter in
                    CoverLetterCard(coverLetter: coverLetter) {
                        // View cover letter
                        editingCoverLetter = coverLetter
                        showingComposer = true
                    }
                    .contextMenu {
                        Button(action: {
                            editingCoverLetter = coverLetter
                            showingComposer = true
                        }) {
                            Label("Edit", systemImage: "pencil")
                        }
                        
                        Button(action: {
                            coverLetterToDelete = coverLetter
                            showingDeleteAlert = true
                        }) {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }
    
    private func deleteCoverLetter(_ coverLetter: CoverLetterEntity) {
        let coverLetterModel = CoverLetter(
            id: coverLetter.id ?? UUID(),
            name: coverLetter.name ?? "",
            template: coverLetter.template ?? "",
            companyName: coverLetter.companyName ?? "",
            positionTitle: coverLetter.positionTitle ?? "",
            hiringManagerName: coverLetter.hiringManagerName ?? "",
            companyAddress: coverLetter.companyAddress ?? "",
            openingParagraph: coverLetter.openingParagraph ?? "",
            bodyParagraphs: coverLetter.bodyParagraphs ?? [""],
            closingParagraph: coverLetter.closingParagraph ?? ""
        )
        
        coverLetterDataService.deleteCoverLetter(coverLetterModel)
    }
}

struct CoverLetterCard: View {
    let coverLetter: CoverLetterEntity
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(coverLetter.name ?? "Untitled Cover Letter")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        if let updatedAt = coverLetter.updatedAt {
                            Text(formattedDate(updatedAt))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Company and Position
                VStack(alignment: .leading, spacing: 4) {
                    if let companyName = coverLetter.companyName, !companyName.isEmpty {
                        Text(companyName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    
                    if let positionTitle = coverLetter.positionTitle, !positionTitle.isEmpty {
                        Text(positionTitle)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                }
                
                // Preview
                if let openingParagraph = coverLetter.openingParagraph, !openingParagraph.isEmpty {
                    Text(openingParagraph)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

#Preview {
    CoverLetterListView()
        .environmentObject(CoverLetterDataService())
} 