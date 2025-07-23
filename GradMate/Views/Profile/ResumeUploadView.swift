import SwiftUI
import PDFKit
import UniformTypeIdentifiers

struct ResumeUploadView: View {
    @EnvironmentObject var profileManager: ProfileManager
    @EnvironmentObject var skillManager: SkillManager
    @State private var showingFileImporter = false
    @State private var extractedResumeText: String = ""
    @State private var parsedName: String = ""
    @State private var parsedEmail: String = ""
    @State private var parsedPhone: String = ""
    @State private var parsedSkills: String = ""
    @State private var showReview = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        VStack(spacing: 24) {
            Button(action: { showingFileImporter = true }) {
                HStack {
                    Image(systemName: "doc.fill")
                    Text("Upload Resume (PDF)")
                }
                .font(.headline)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .fileImporter(
                isPresented: $showingFileImporter,
                allowedContentTypes: [.pdf],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        extractTextFromPDF(url: url)
                    }
                case .failure(let error):
                    print("Failed to import file: \(error)")
                }
            }
            if !extractedResumeText.isEmpty {
                Button("Review & Import Data") {
                    parseAndShowReview()
                }
                .padding(.top, 8)
            }
        }
        .sheet(isPresented: $showReview) {
            ResumeReviewView(
                name: $parsedName,
                email: $parsedEmail,
                phone: $parsedPhone,
                skills: $parsedSkills
            ) { name, email, phone, skills in
                // Save to profileManager
                if !name.isEmpty { profileManager.currentProfile?.name = name }
                if !email.isEmpty { profileManager.currentProfile?.email = email }
                if !phone.isEmpty { profileManager.currentProfile?.phone = phone }
                if !skills.isEmpty {
                    let skillNames = skills.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                    for skill in skillNames where !skill.isEmpty {
                        skillManager.addSkill(name: skill, category: "Imported", description: "", proficiency: 3)
                    }
                }
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Resume Upload"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    func extractTextFromPDF(url: URL) {
        print("[ResumeUpload] Selected PDF URL: \(url)")
        print("[ResumeUpload] File exists: \(FileManager.default.fileExists(atPath: url.path))")
        if let pdf = PDFDocument(url: url) {
            var fullText = ""
            for i in 0..<pdf.pageCount {
                if let page = pdf.page(at: i), let text = page.string {
                    fullText += text + "\n"
                }
            }
            print("[ResumeUpload] Extracted text: \n\(fullText)")
            extractedResumeText = fullText
            if fullText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                alertMessage = "No text could be extracted from the PDF. This may be an image-only or encrypted PDF. Please try a different, text-based PDF (e.g., exported from Word or Google Docs).\n\nSample: https://www.africau.edu/images/default/sample.pdf"
                showAlert = true
            }
        } else {
            alertMessage = "Failed to open PDF. Please try again.\n\nSample: https://www.africau.edu/images/default/sample.pdf"
            showAlert = true
        }
    }
    
    func parseAndShowReview() {
        let (name, email, phone, skills) = parseResumeText(extractedResumeText)
        print("[ResumeUpload] Parsed name: \(name ?? "")")
        print("[ResumeUpload] Parsed email: \(email ?? "")")
        print("[ResumeUpload] Parsed phone: \(phone ?? "")")
        print("[ResumeUpload] Parsed skills: \(skills)")
        parsedName = name ?? ""
        parsedEmail = email ?? ""
        parsedPhone = phone ?? ""
        parsedSkills = skills.joined(separator: ", ")
        showReview = true // Always show review, even if fields are empty
    }
    
    func parseResumeText(_ text: String) -> (String?, String?, String?, [String]) {
        let lines = text.components(separatedBy: .newlines)
        let email = lines.first(where: { $0.contains("@") })
        let phone = lines.first(where: { $0.range(of: #"(\+?\d[\d -]{7,}\d)"#, options: .regularExpression) != nil })
        let name = lines.first
        let skillsLine = lines.first(where: { $0.lowercased().contains("skills") })
        let skills = skillsLine?.components(separatedBy: ":").last?.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) } ?? []
        return (name, email, phone, skills)
    }
}

struct ResumeReviewView: View {
    @Binding var name: String
    @Binding var email: String
    @Binding var phone: String
    @Binding var skills: String
    var onSave: (String, String, String, String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Name")) {
                    TextField("Name", text: $name)
                }
                Section(header: Text("Email")) {
                    TextField("Email", text: $email)
                }
                Section(header: Text("Phone")) {
                    TextField("Phone", text: $phone)
                }
                Section(header: Text("Skills (comma separated)")) {
                    TextField("Skills", text: $skills)
                }
            }
            .navigationTitle("Review Resume Data")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(name, email, phone, skills)
                        dismiss()
                    }
                }
            }
        }
    }
} 