import SwiftUI
import MessageUI

extension ResumeTheme {
    static let creativeTeal = ResumeTheme(
        id: "creative-teal",
        name: "Creative Teal",
        primaryColor: Color(red: 0.08, green: 0.16, blue: 0.18),
        accentColor: Color(red: 0.09, green: 0.64, blue: 0.62),
        headerFont: .system(size: 28, weight: .bold),
        bodyFont: .system(size: 13, weight: .regular),
        sectionSpacing: 16,
        dividerColor: Color.teal.opacity(0.25),
        backgroundColor: Color.white,
        subtitleFont: .system(size: 15, weight: .medium),
        sectionTitleFont: .system(size: 14, weight: .bold),
        sectionTitleColor: Color(red: 0.09, green: 0.64, blue: 0.62),
        sectionHeaderCaps: true
    )
    
    static let boldExecutive = ResumeTheme(
        id: "bold-executive",
        name: "Bold Executive",
        primaryColor: Color(red: 0.12, green: 0.12, blue: 0.14),
        accentColor: Color(red: 0.72, green: 0.18, blue: 0.18),
        headerFont: .system(size: 27, weight: .heavy),
        bodyFont: .system(size: 12.5, weight: .regular),
        sectionSpacing: 15,
        dividerColor: Color.red.opacity(0.2),
        backgroundColor: Color.white,
        subtitleFont: .system(size: 15, weight: .semibold),
        sectionTitleFont: .system(size: 13, weight: .heavy),
        sectionTitleColor: Color(red: 0.72, green: 0.18, blue: 0.18),
        sectionHeaderCaps: true
    )
}

struct ResumeExportView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var profileManager: ProfileManager
    @EnvironmentObject private var skillManager: SkillManager
    @EnvironmentObject private var careerDataService: CareerDataService
    @EnvironmentObject private var languageManager: LanguageManager
    
    @State private var selectedTheme: ResumeTheme = .modernMinimalist
    @State private var showingShare = false
    @State private var showingMail = false
    @State private var shareURL: URL?
    @State private var isGenerating = false
    
    private var snapshot: ResumeSnapshot {
        ResumeSnapshot.current(
            profile: profileManager.currentProfile,
            skills: skillManager.skills,
            career: careerDataService,
            languages: languageManager.languages
        )
    }
    
    private var themes: [ResumeTheme] {
        [.modernMinimalist, .professionalClassic, .creativeTeal, .boldExecutive]
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("appScreenBG").ignoresSafeArea()
                VStack(spacing: 0) {
                    completenessBanner
                    themePicker
                    ScrollView {
                        ResumePaperView(snapshot: snapshot, theme: selectedTheme)
                            .padding(16)
                    }
                    actionBar
                }
            }
            .navigationTitle("Build Resume")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(isPresented: $showingShare) {
                if let shareURL {
                    ShareSheet(items: [shareURL])
                }
            }
            .sheet(isPresented: $showingMail) {
                if let shareURL {
                    MailComposer(
                        subject: "\(snapshot.name.isEmpty ? "Candidate" : snapshot.name) – Resume",
                        body: "Please find my resume attached.",
                        attachmentURL: shareURL
                    )
                }
            }
        }
    }
    
    private var completenessBanner: some View {
        let missing = missingPieces
        return Group {
            if missing.isEmpty {
                Label("Ready to share — all core sections have data", systemImage: "checkmark.seal.fill")
                    .font(.caption)
                    .foregroundColor(Color("appSuccess"))
                    .padding(12)
            } else {
                Text("Add \(missing.joined(separator: ", ")) to strengthen this resume.")
                    .font(.caption)
                    .foregroundColor(Color("appWarning"))
                    .padding(12)
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color("appCardBG"))
    }
    
    private var missingPieces: [String] {
        var items: [String] = []
        if snapshot.name.isEmpty { items.append("name") }
        if snapshot.email.isEmpty { items.append("email") }
        if snapshot.workExperiences.isEmpty && snapshot.internships.isEmpty { items.append("experience") }
        if snapshot.skillsByCategory.isEmpty { items.append("skills") }
        return items
    }
    
    private var themePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(themes) { theme in
                    Button {
                        selectedTheme = theme
                    } label: {
                        Text(theme.name)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedTheme.id == theme.id ? Color("appPrimaryAccent") : Color("appStrokeGray"))
                            .foregroundColor(selectedTheme.id == theme.id ? .white : Color("appTextPrimary"))
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }
    
    private var actionBar: some View {
        HStack(spacing: 12) {
            Button(action: shareResume) {
                label("square.and.arrow.up", isGenerating ? "Preparing…" : "Share")
            }
            .disabled(isGenerating)
            
            Button(action: emailResume) {
                label("envelope.fill", "Email recruiter")
            }
            .disabled(isGenerating || !MFMailComposeViewController.canSendMail())
        }
        .padding(16)
        .background(Color("appCardBG"))
    }
    
    private func label(_ icon: String, _ title: String) -> some View {
        HStack {
            Image(systemName: icon)
            Text(title).fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color("appPrimaryAccent"))
        .foregroundColor(.white)
        .cornerRadius(12)
    }
    
    private func preparePDF() -> URL {
        let data = ResumePDFBuilder.makePDF(snapshot: snapshot, theme: selectedTheme)
        let slug = snapshot.name.isEmpty ? "GradMate_Resume" : snapshot.name.replacingOccurrences(of: " ", with: "_")
        return ResumePDFBuilder.writeTemporaryPDF(data, named: "\(slug)_Resume.pdf")
    }
    
    private func shareResume() {
        isGenerating = true
        shareURL = preparePDF()
        isGenerating = false
        showingShare = true
    }
    
    private func emailResume() {
        isGenerating = true
        shareURL = preparePDF()
        isGenerating = false
        if MFMailComposeViewController.canSendMail() {
            showingMail = true
        } else {
            showingShare = true
        }
    }
}

struct ResumePaperView: View {
    let snapshot: ResumeSnapshot
    let theme: ResumeTheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.sectionSpacing) {
            Text(snapshot.name.isEmpty ? "Your Name" : snapshot.name)
                .font(theme.headerFont)
                .foregroundColor(theme.primaryColor)
            if !snapshot.role.isEmpty {
                Text(snapshot.role)
                    .font(theme.subtitleFont)
                    .foregroundColor(theme.accentColor)
            }
            contactRow
            if !snapshot.bio.isEmpty {
                Text(snapshot.bio)
                    .font(theme.bodyFont)
                    .foregroundColor(theme.primaryColor.opacity(0.8))
            }
            experienceSection("Work Experience", items: snapshot.workExperiences.map {
                ($0.title, $0.company, ResumePDFBuilder.dateRange($0.startDate, $0.endDate, $0.isCurrent), $0.description)
            })
            experienceSection("Internships", items: snapshot.internships.map {
                ($0.title, $0.company, ResumePDFBuilder.dateRange($0.startDate, $0.endDate, $0.isCurrent), $0.description)
            })
            experienceSection("Projects", items: snapshot.projects.map {
                ($0.title, $0.company, ResumePDFBuilder.dateRange($0.startDate, $0.endDate, $0.isCurrent), $0.description)
            })
            if !snapshot.certifications.isEmpty {
                sectionTitle("Certifications")
                ForEach(snapshot.certifications) { item in
                    Text(item.title).font(theme.bodyFont.weight(.semibold)).foregroundColor(theme.primaryColor)
                    Text(item.organization).font(.caption).foregroundColor(theme.accentColor)
                }
            }
            if snapshot.skillsByCategory.contains(where: { !$0.skills.isEmpty }) {
                sectionTitle("Skills")
                ForEach(snapshot.skillsByCategory, id: \.category) { group in
                    if !group.skills.isEmpty {
                        Text("\(group.category): \(group.skills.joined(separator: ", "))")
                            .font(theme.bodyFont)
                            .foregroundColor(theme.primaryColor.opacity(0.8))
                    }
                }
            }
            if !snapshot.languages.isEmpty {
                sectionTitle("Languages")
                Text(snapshot.languages.map { "\($0.name) (\($0.proficiency.rawValue))" }.joined(separator: "  •  "))
                    .font(theme.bodyFont)
                    .foregroundColor(theme.primaryColor.opacity(0.8))
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.backgroundColor)
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 4)
    }
    
    private var contactRow: some View {
        let parts = [snapshot.email, snapshot.phone, snapshot.linkedin, snapshot.website, snapshot.address].filter { !$0.isEmpty }
        return Text(parts.joined(separator: "  •  "))
            .font(.caption)
            .foregroundColor(theme.primaryColor.opacity(0.7))
    }
    
    private func sectionTitle(_ title: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(theme.sectionHeaderCaps ? title.uppercased() : title)
                .font(theme.sectionTitleFont)
                .foregroundColor(theme.sectionTitleColor)
            Rectangle().fill(theme.dividerColor).frame(height: 1)
        }
        .padding(.top, 6)
    }
    
    private func experienceSection(_ title: String, items: [(String, String, String, String)]) -> some View {
        Group {
            if !items.isEmpty {
                sectionTitle(title)
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(item.0).font(theme.bodyFont.weight(.semibold)).foregroundColor(theme.primaryColor)
                            Spacer()
                            Text(item.2).font(.caption).foregroundColor(theme.primaryColor.opacity(0.6))
                        }
                        Text(item.1).font(.caption).foregroundColor(theme.accentColor)
                        if !item.3.isEmpty {
                            Text(item.3).font(theme.bodyFont).foregroundColor(theme.primaryColor.opacity(0.8))
                        }
                    }
                    .padding(.bottom, 6)
                }
            }
        }
    }
}

struct MailComposer: UIViewControllerRepresentable {
    let subject: String
    let body: String
    let attachmentURL: URL
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.setSubject(subject)
        composer.setMessageBody(body, isHTML: false)
        if let data = try? Data(contentsOf: attachmentURL) {
            composer.addAttachmentData(data, mimeType: "application/pdf", fileName: attachmentURL.lastPathComponent)
        }
        composer.mailComposeDelegate = context.coordinator
        return composer
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator { Coordinator(dismiss: dismiss) }
    
    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let dismiss: DismissAction
        init(dismiss: DismissAction) { self.dismiss = dismiss }
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            dismiss()
        }
    }
}

#Preview {
    ResumeExportView()
        .environmentObject(ProfileManager())
        .environmentObject(SkillManager())
        .environmentObject(CareerDataService())
        .environmentObject(LanguageManager())
}
