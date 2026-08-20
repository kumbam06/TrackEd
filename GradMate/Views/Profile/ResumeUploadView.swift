import SwiftUI
import PDFKit
import UniformTypeIdentifiers

struct ResumeUploadView: View {
    @EnvironmentObject var profileManager: ProfileManager
    @EnvironmentObject var skillManager: SkillManager
    @EnvironmentObject var careerDataService: CareerDataService
    @EnvironmentObject var languageManager: LanguageManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingFileImporter = false
    @State private var extractedResumeText = ""
    @State private var parsed = ParsedResume()
    @State private var showReview = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isImporting = false
    @State private var didImport = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("appScreenBG").ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        Text("Upload a PDF resume to fill your profile, skills, work experience, internships, projects, certifications, and languages.")
                            .font(.subheadline)
                            .foregroundColor(Color("appTextSecondary"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button(action: { showingFileImporter = true }) {
                            HStack {
                                Image(systemName: "doc.fill")
                                Text("Choose Resume (PDF)")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("appPrimaryAccent"))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        
                        if !extractedResumeText.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Extracted text preview")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color("appTextSecondary"))
                                Text(extractedResumeText.prefix(600) + (extractedResumeText.count > 600 ? "…" : ""))
                                    .font(.caption)
                                    .foregroundColor(Color("appTextPrimary"))
                                    .padding()
                                    .background(Color("appCardBG"))
                                    .cornerRadius(12)
                            }
                            
                            Button("Review imported fields") {
                                parsed = ResumeParser.parse(text: extractedResumeText)
                                showReview = true
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("appSuccess"))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Upload Resume")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .fileImporter(
                isPresented: $showingFileImporter,
                allowedContentTypes: [.pdf, .plainText],
                allowsMultipleSelection: false
            ) { result in
                handleImport(result)
            }
            .sheet(isPresented: $showReview) {
                ResumeImportReviewView(parsed: $parsed) {
                    applyParsedResume()
                }
            }
            .alert("Resume Upload", isPresented: $showAlert) {
                Button("OK") {
                    if didImport { dismiss() }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            let accessed = url.startAccessingSecurityScopedResource()
            defer { if accessed { url.stopAccessingSecurityScopedResource() } }
            extractText(from: url)
        case .failure(let error):
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
    
    private func extractText(from url: URL) {
        if url.pathExtension.lowercased() == "pdf" {
            guard let pdf = PDFDocument(url: url) else {
                alertMessage = "Could not open that PDF. Export a text-based PDF from Word or Google Docs and try again."
                showAlert = true
                return
            }
            var fullText = ""
            for index in 0..<pdf.pageCount {
                fullText += (pdf.page(at: index)?.string ?? "") + "\n"
            }
            extractedResumeText = fullText
            if fullText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                alertMessage = "No selectable text was found. Image-only scans cannot be imported."
                showAlert = true
            } else {
                parsed = ResumeParser.parse(text: fullText)
                showReview = true
            }
        } else if let text = try? String(contentsOf: url, encoding: .utf8) {
            extractedResumeText = text
            parsed = ResumeParser.parse(text: text)
            showReview = true
        } else {
            alertMessage = "Could not read that file."
            showAlert = true
        }
    }
    
    private func applyParsedResume() {
        isImporting = true
        profileManager.applyImportedProfile(
            name: parsed.name,
            role: parsed.role,
            email: parsed.email,
            phone: parsed.phone,
            bio: parsed.bio,
            linkedin: parsed.linkedin,
            website: parsed.website,
            address: parsed.address
        )
        for skill in parsed.skills {
            skillManager.addSkill(name: skill, category: "Imported", description: "Imported from resume", proficiency: 3)
        }
        for language in parsed.languages {
            languageManager.upsert(language)
        }
        careerDataService.importResume(parsed)
        isImporting = false
        didImport = true
        showReview = false
        alertMessage = "Imported \(parsed.importedItemCount) items into your profile. Open Build Resume to preview and share."
        showAlert = true
    }
}

struct ResumeImportReviewView: View {
    @Binding var parsed: ParsedResume
    var onImport: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Profile") {
                    TextField("Name", text: $parsed.name)
                    TextField("Role / Title", text: $parsed.role)
                    TextField("Email", text: $parsed.email)
                    TextField("Phone", text: $parsed.phone)
                    TextField("LinkedIn", text: $parsed.linkedin)
                    TextField("Website", text: $parsed.website)
                    TextField("Address", text: $parsed.address)
                    TextField("Summary", text: $parsed.bio, axis: .vertical)
                        .lineLimit(3...6)
                }
                Section("Skills (\(parsed.skills.count))") {
                    TextField("Comma-separated skills", text: Binding(
                        get: { parsed.skills.joined(separator: ", ") },
                        set: { parsed.skills = $0.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty } }
                    ))
                }
                Section("Work experience (\(parsed.workExperiences.count))") {
                    ForEach(parsed.workExperiences) { item in
                        VStack(alignment: .leading) {
                            Text(item.title).font(.headline)
                            Text(item.company).font(.subheadline).foregroundColor(.secondary)
                        }
                    }
                    if parsed.workExperiences.isEmpty { Text("None detected").foregroundColor(.secondary) }
                }
                Section("Internships (\(parsed.internships.count))") {
                    ForEach(parsed.internships) { item in
                        Text("\(item.title) — \(item.company)")
                    }
                    if parsed.internships.isEmpty { Text("None detected").foregroundColor(.secondary) }
                }
                Section("Projects (\(parsed.projects.count))") {
                    ForEach(parsed.projects) { item in
                        Text(item.title)
                    }
                    if parsed.projects.isEmpty { Text("None detected").foregroundColor(.secondary) }
                }
                Section("Certifications (\(parsed.certifications.count))") {
                    ForEach(parsed.certifications) { item in
                        Text("\(item.title) — \(item.organization)")
                    }
                    if parsed.certifications.isEmpty { Text("None detected").foregroundColor(.secondary) }
                }
                Section("Languages (\(parsed.languages.count))") {
                    ForEach(parsed.languages) { item in
                        Text("\(item.name) (\(item.proficiency.rawValue))")
                    }
                    if parsed.languages.isEmpty { Text("None detected").foregroundColor(.secondary) }
                }
            }
            .navigationTitle("Review Import")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Import All") {
                        onImport()
                    }
                }
            }
        }
    }
}
