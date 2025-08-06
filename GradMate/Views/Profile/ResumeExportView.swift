//
//  ResumeExportView.swift
//  GradMate
//
//  Created by Pradeep Reddy Kumbam on 23/06/2025.
//

import SwiftUI
import PDFKit

// MARK: - Resume Theme System
struct ResumeTheme: Identifiable, Equatable {
    let id: String
    let name: String
    let primaryColor: Color
    let accentColor: Color
    let headerFont: Font
    let bodyFont: Font
    let sectionSpacing: CGFloat
    let dividerColor: Color
    let backgroundColor: Color
    let subtitleFont: Font
    let sectionTitleFont: Font
    let sectionTitleColor: Color
    let sectionHeaderCaps: Bool
}

extension ResumeTheme {
    static let modernMinimalist = ResumeTheme(
        id: "modern-minimalist",
        name: "Modern Minimalist",
        primaryColor: .black,
        accentColor: .blue,
        headerFont: .system(size: 28, weight: .bold),
        bodyFont: .system(size: 13, weight: .regular),
        sectionSpacing: 18,
        dividerColor: Color.gray.opacity(0.18),
        backgroundColor: Color.white,
        subtitleFont: .system(size: 16, weight: .medium),
        sectionTitleFont: .system(size: 15, weight: .semibold),
        sectionTitleColor: .blue,
        sectionHeaderCaps: true
    )
    static let professionalClassic = ResumeTheme(
        id: "professional-classic",
        name: "Professional Classic",
        primaryColor: .black,
        accentColor: .gray,
        headerFont: .system(size: 26, weight: .bold, design: .serif),
        bodyFont: .system(size: 12, weight: .regular, design: .serif),
        sectionSpacing: 16,
        dividerColor: Color.gray.opacity(0.3),
        backgroundColor: Color.white,
        subtitleFont: .system(size: 15, weight: .medium, design: .serif),
        sectionTitleFont: .system(size: 14, weight: .bold, design: .serif),
        sectionTitleColor: .black,
        sectionHeaderCaps: false
    )
    static let allThemes: [ResumeTheme] = [modernMinimalist, professionalClassic]
}

struct ResumeExportView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var profileManager: ProfileManager
    @EnvironmentObject private var skillManager: SkillManager
    @StateObject private var careerDataService = CareerDataService()
    
    @State private var isGenerating = false
    @State private var pdfData: Data?
    @State private var selectedTheme: ResumeTheme = .modernMinimalist
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                
                VStack(spacing: 24) {
                    resumeHeader5D
                    themePicker
                    resumePreview5D
                    Spacer()
                    exportButton5D
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .navigationTitle("RESUME EXPORT")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("CANCEL") {
                        dismiss()
                    }
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.7))
                }
            }
        }
    }
    
    private var resumeHeader5D: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.accentColor)
                    .shadow(color: .accentColor, radius: 8, x: 0, y: 0)
            }
            
            VStack(spacing: 8) {
                Text("EXPORT RESUME")
                    .font(.title2)
                    .foregroundColor(.white)
                    .kerning(1)
                
                Text("Generate a professional PDF resume")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 20)
    }
    
    private var resumePreview5D: some View {
        VStack(alignment: .leading, spacing: selectedTheme.sectionSpacing) {
            Text("RESUME PREVIEW")
                .font(selectedTheme.sectionTitleFont)
                .foregroundColor(selectedTheme.sectionTitleColor)
                .kerning(1)
            ScrollView {
                VStack(alignment: .leading, spacing: selectedTheme.sectionSpacing) {
                    // Profile Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text(profileManager.currentProfile?.name ?? "John Doe")
                            .font(selectedTheme.headerFont)
                            .foregroundColor(selectedTheme.primaryColor)
                        Text(profileManager.currentProfile?.role ?? "iOS Developer")
                            .font(selectedTheme.subtitleFont)
                            .foregroundColor(selectedTheme.accentColor)
                        if let bio = profileManager.currentProfile?.bio, !bio.isEmpty {
                            Text(bio)
                                .font(selectedTheme.bodyFont)
                                .foregroundColor(selectedTheme.primaryColor.opacity(0.8))
                        }
                        HStack(spacing: 12) {
                            if let email = profileManager.currentProfile?.email, !email.isEmpty {
                                Label(email, systemImage: "envelope.fill")
                                    .font(.caption)
                                    .foregroundColor(selectedTheme.primaryColor.opacity(0.7))
                            }
                            if let phone = profileManager.currentProfile?.phone, !phone.isEmpty {
                                Label(phone, systemImage: "phone.fill")
                                    .font(.caption)
                                    .foregroundColor(selectedTheme.primaryColor.opacity(0.7))
                            }
                        }
                        HStack(spacing: 12) {
                            if let linkedin = profileManager.currentProfile?.linkedin, !linkedin.isEmpty {
                                Label(linkedin, systemImage: "link")
                                    .font(.caption)
                                    .foregroundColor(selectedTheme.accentColor)
                            }
                            if let website = profileManager.currentProfile?.website, !website.isEmpty {
                                Label(website, systemImage: "globe")
                                    .font(.caption)
                                    .foregroundColor(selectedTheme.accentColor)
                            }
                        }
                        if let address = profileManager.currentProfile?.address, !address.isEmpty {
                            Label(address, systemImage: "location.fill")
                                .font(.caption)
                                .foregroundColor(selectedTheme.primaryColor.opacity(0.7))
                        }
                    }
                    Divider().background(selectedTheme.dividerColor)
                    // Work Experience Section
                    if !careerDataService.workExperiences.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            let workExpTitle = selectedTheme.sectionHeaderCaps ? "WORK EXPERIENCE" : "Work Experience"
                            Text(workExpTitle)
                                .font(selectedTheme.sectionTitleFont)
                                .foregroundColor(selectedTheme.sectionTitleColor)
                            ForEach(careerDataService.workExperiences, id: \.id) { experience in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(experience.title ?? "")
                                            .font(selectedTheme.bodyFont.weight(.semibold))
                                            .foregroundColor(selectedTheme.primaryColor)
                                        Spacer()
                                        Text(formatDateRange(start: experience.startDate, end: experience.endDate, isCurrent: experience.isCurrent))
                                            .font(.caption)
                                            .foregroundColor(selectedTheme.primaryColor.opacity(0.6))
                                    }
                                    Text(experience.company ?? "")
                                        .font(.caption)
                                        .foregroundColor(selectedTheme.accentColor)
                                    if let description = experience.workDescription, !description.isEmpty {
                                        Text(description)
                                            .font(selectedTheme.bodyFont)
                                            .foregroundColor(selectedTheme.primaryColor.opacity(0.8))
                                    }
                                }
                            }
                        }
                        Divider().background(selectedTheme.dividerColor)
                    }
                    // Projects Section
                    if !careerDataService.projects.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            let projectsTitle = selectedTheme.sectionHeaderCaps ? "PROJECTS" : "Projects"
                            Text(projectsTitle)
                                .font(selectedTheme.sectionTitleFont)
                                .foregroundColor(selectedTheme.sectionTitleColor)
                            ForEach(careerDataService.projects, id: \.id) { project in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(project.title ?? "")
                                            .font(selectedTheme.bodyFont.weight(.semibold))
                                            .foregroundColor(selectedTheme.primaryColor)
                                        Spacer()
                                        Text(formatDateRange(start: project.startDate, end: project.endDate, isCurrent: project.isCurrent))
                                            .font(.caption)
                                            .foregroundColor(selectedTheme.primaryColor.opacity(0.6))
                                    }
                                    if let technologies = project.technologies as? [String], !technologies.isEmpty {
                                        Text(technologies.joined(separator: ", "))
                                            .font(.caption)
                                            .foregroundColor(selectedTheme.accentColor)
                                    }
                                    if let description = project.projectDescription, !description.isEmpty {
                                        Text(description)
                                            .font(selectedTheme.bodyFont)
                                            .foregroundColor(selectedTheme.primaryColor.opacity(0.8))
                                    }
                                }
                            }
                        }
                        Divider().background(selectedTheme.dividerColor)
                    }
                    // Internships Section
                    if !careerDataService.internships.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            let internshipsTitle = selectedTheme.sectionHeaderCaps ? "INTERNSHIPS" : "Internships"
                            Text(internshipsTitle)
                                .font(selectedTheme.sectionTitleFont)
                                .foregroundColor(selectedTheme.sectionTitleColor)
                            ForEach(careerDataService.internships, id: \.id) { internship in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(internship.title ?? "")
                                            .font(selectedTheme.bodyFont.weight(.semibold))
                                            .foregroundColor(selectedTheme.primaryColor)
                                        Spacer()
                                        Text(formatDateRange(start: internship.startDate, end: internship.endDate, isCurrent: internship.isCurrent))
                                            .font(.caption)
                                            .foregroundColor(selectedTheme.primaryColor.opacity(0.6))
                                    }
                                    Text(internship.company ?? "")
                                        .font(.caption)
                                        .foregroundColor(selectedTheme.accentColor)
                                    if let description = internship.internshipDescription, !description.isEmpty {
                                        Text(description)
                                            .font(selectedTheme.bodyFont)
                                            .foregroundColor(selectedTheme.primaryColor.opacity(0.8))
                                    }
                                }
                            }
                        }
                        Divider().background(selectedTheme.dividerColor)
                    }
                    // Certifications Section
                    if !careerDataService.certifications.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            let certificationsTitle = selectedTheme.sectionHeaderCaps ? "CERTIFICATIONS" : "Certifications"
                            Text(certificationsTitle)
                                .font(selectedTheme.sectionTitleFont)
                                .foregroundColor(selectedTheme.sectionTitleColor)
                            ForEach(careerDataService.certifications, id: \.id) { certification in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(certification.name ?? "")
                                        .font(selectedTheme.bodyFont.weight(.semibold))
                                        .foregroundColor(selectedTheme.primaryColor)
                                    Text(certification.issuingOrganization ?? "")
                                        .font(.caption)
                                        .foregroundColor(selectedTheme.accentColor)
                                }
                            }
                        }
                        Divider().background(selectedTheme.dividerColor)
                    }
                    // Skills Section
                    VStack(alignment: .leading, spacing: 8) {
                        let skillsTitle = selectedTheme.sectionHeaderCaps ? "SKILLS" : "Skills"
                        Text(skillsTitle)
                            .font(selectedTheme.sectionTitleFont)
                            .foregroundColor(selectedTheme.sectionTitleColor)
                        let categories = skillManager.getCategories()
                        ForEach(categories, id: \.self) { category in
                            VStack(alignment: .leading, spacing: 4) {
                                let categoryTitle = selectedTheme.sectionHeaderCaps ? category.uppercased() : category
                                Text(categoryTitle)
                                    .font(selectedTheme.bodyFont.weight(.medium))
                                    .foregroundColor(selectedTheme.accentColor)
                                    .kerning(0.5)
                                let skillsInCategory = skillManager.getSkillsByCategory(category)
                                Text(skillsInCategory.map { $0.name ?? "" }.joined(separator: ", "))
                                    .font(.caption)
                                    .foregroundColor(selectedTheme.primaryColor.opacity(0.7))
                            }
                        }
                    }
                    // Languages Section
                    let languages = loadLanguages()
                    if !languages.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            let languagesTitle = selectedTheme.sectionHeaderCaps ? "LANGUAGES" : "Languages"
                            Text(languagesTitle)
                                .font(selectedTheme.sectionTitleFont)
                                .foregroundColor(selectedTheme.sectionTitleColor)
                            ForEach(languages) { lang in
                                HStack {
                                    Text(lang.name)
                                        .font(selectedTheme.bodyFont.weight(.medium))
                                        .foregroundColor(selectedTheme.primaryColor)
                                    Spacer()
                                    Text(lang.proficiency.rawValue)
                                        .font(.caption)
                                        .foregroundColor(selectedTheme.accentColor)
                                }
                            }
                        }
                    }
                }
            }
            .frame(maxHeight: 400)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(selectedTheme.backgroundColor.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(selectedTheme.accentColor.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: selectedTheme.accentColor.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private var themePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("RESUME THEME")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.accentColor)
            HStack(spacing: 12) {
                ForEach(ResumeTheme.allThemes) { theme in
                    Button(action: { selectedTheme = theme }) {
                        Text(theme.name)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(selectedTheme == theme ? .white : .accentColor)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(selectedTheme == theme ? .accentColor : Color(.systemGray5))
                            .clipShape(Capsule())
                            .shadow(radius: selectedTheme == theme ? 3 : 0)
                    }
                }
            }
        }
        .padding(.bottom, 8)
    }
    
    private var exportButton5D: some View {
        Button(action: generateResume) {
            HStack(spacing: 12) {
                if isGenerating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "doc.text.fill")
                        .font(.headline)
                }
                
                Text(isGenerating ? "GENERATING..." : "GENERATE RESUME")
                    .font(.headline)
                    .fontWeight(.bold)
                    .kerning(1)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isGenerating ?
                        LinearGradient(colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                        LinearGradient(colors: [.accentColor, .primary], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .shadow(color: isGenerating ? Color.clear : Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
            )
        }
        .disabled(isGenerating)
        .buttonStyle(PlainButtonStyle())
        .padding(.bottom, 20)
    }
    
    private func formatDateRange(start: Date?, end: Date?, isCurrent: Bool) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        
        guard let startDate = start else { return "Present" }
        let startString = formatter.string(from: startDate)
        
        if isCurrent {
            return "\(startString) - Present"
        } else if let endDate = end {
            let endString = formatter.string(from: endDate)
            return "\(startString) - \(endString)"
        } else {
            return startString
        }
    }
    
    private func generateResume() {
        isGenerating = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let pdfData = createResumePDF()
            
            DispatchQueue.main.async {
                self.pdfData = pdfData
                self.isGenerating = false
                self.shareResume()
            }
        }
    }
    
    private func shareResume() {
        guard let pdfData = pdfData else { return }
        
        let activityVC = UIActivityViewController(activityItems: [pdfData], applicationActivities: nil)
        
        // Get the window scene
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            // Present the activity view controller
            if let rootVC = window.rootViewController {
                // Find the topmost view controller
                var topVC = rootVC
                while let presentedVC = topVC.presentedViewController {
                    topVC = presentedVC
                }
                topVC.present(activityVC, animated: true)
            }
        }
    }
    
    private func createResumePDF() -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "GradMate",
            kCGPDFContextAuthor: profileManager.currentProfile?.name ?? "Student"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4 size
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        let data = renderer.pdfData { context in
            context.beginPage()
            let leftMargin: CGFloat = 50
            let rightMargin: CGFloat = 545.2
            var yPosition: CGFloat = 50

            // Theme-driven fonts/colors
            let theme = selectedTheme
            let nameFont = UIFont.systemFont(ofSize: 28, weight: .bold)
            let roleFont = UIFont.systemFont(ofSize: 16, weight: .medium)
            let sectionFont = UIFont.systemFont(ofSize: 15, weight: .semibold)
            let bodyFont = UIFont.systemFont(ofSize: 13, weight: .regular)
            let captionFont = UIFont.systemFont(ofSize: 11, weight: .regular)
            let accentColor = UIColor(theme.accentColor)
            let primaryColor = UIColor(theme.primaryColor)
            let sectionTitleColor = UIColor(theme.sectionTitleColor)

            // Name
            let name = profileManager.currentProfile?.name ?? "John Doe"
            name.draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: [
                .font: nameFont,
                .foregroundColor: primaryColor
            ])
            yPosition += 35

            // Role
            let role = profileManager.currentProfile?.role ?? "iOS Developer"
            role.draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: [
                .font: roleFont,
                .foregroundColor: accentColor
            ])
            yPosition += 25

            // Bio
            if let bio = profileManager.currentProfile?.bio, !bio.isEmpty {
                let lines = wrapText(bio, maxWidth: rightMargin - leftMargin, attributes: [
                    .font: bodyFont,
                    .foregroundColor: primaryColor.withAlphaComponent(0.8)
                ])
                for line in lines {
                    line.draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: [
                        .font: bodyFont,
                        .foregroundColor: primaryColor.withAlphaComponent(0.8)
                    ])
                    yPosition += 14
                }
                yPosition += 6
            }

            // Contact Info
            var contactY = yPosition
            if let email = profileManager.currentProfile?.email, !email.isEmpty {
                ("Email: " + email).draw(at: CGPoint(x: leftMargin, y: contactY), withAttributes: [
                    .font: captionFont,
                    .foregroundColor: primaryColor.withAlphaComponent(0.7)
                ])
                contactY += 13
            }
            if let phone = profileManager.currentProfile?.phone, !phone.isEmpty {
                ("Phone: " + phone).draw(at: CGPoint(x: leftMargin, y: contactY), withAttributes: [
                    .font: captionFont,
                    .foregroundColor: primaryColor.withAlphaComponent(0.7)
                ])
                contactY += 13
            }
            if let linkedin = profileManager.currentProfile?.linkedin, !linkedin.isEmpty {
                ("LinkedIn: " + linkedin).draw(at: CGPoint(x: leftMargin, y: contactY), withAttributes: [
                    .font: captionFont,
                    .foregroundColor: accentColor
                ])
                contactY += 13
            }
            if let website = profileManager.currentProfile?.website, !website.isEmpty {
                ("Website: " + website).draw(at: CGPoint(x: leftMargin, y: contactY), withAttributes: [
                    .font: captionFont,
                    .foregroundColor: accentColor
                ])
                contactY += 13
            }
            if let address = profileManager.currentProfile?.address, !address.isEmpty {
                ("Address: " + address).draw(at: CGPoint(x: leftMargin, y: contactY), withAttributes: [
                    .font: captionFont,
                    .foregroundColor: primaryColor.withAlphaComponent(0.7)
                ])
                contactY += 13
            }
            yPosition = max(yPosition, contactY) + 18

            // Work Experience Section
            if !careerDataService.workExperiences.isEmpty {
                let workExpTitle = theme.sectionHeaderCaps ? "WORK EXPERIENCE" : "Work Experience"
                workExpTitle.draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: [
                    .font: sectionFont,
                    .foregroundColor: sectionTitleColor
                ])
                yPosition += 20
                for experience in careerDataService.workExperiences {
                    let title = experience.title ?? ""
                    let dateRange = formatDateRange(start: experience.startDate, end: experience.endDate, isCurrent: experience.isCurrent)
                    title.draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: [
                        .font: bodyFont,
                        .foregroundColor: primaryColor
                    ])
                    dateRange.draw(at: CGPoint(x: rightMargin - 100, y: yPosition), withAttributes: [
                        .font: captionFont,
                        .foregroundColor: primaryColor.withAlphaComponent(0.6)
                    ])
                    yPosition += 15
                    if let company = experience.company {
                        company.draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: [
                            .font: captionFont,
                            .foregroundColor: accentColor
                        ])
                        yPosition += 13
                    }
                    if let description = experience.workDescription, !description.isEmpty {
                        let lines = wrapText(description, maxWidth: rightMargin - leftMargin, attributes: [
                            .font: bodyFont,
                            .foregroundColor: primaryColor.withAlphaComponent(0.8)
                        ])
                        for line in lines {
                            line.draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: [
                                .font: bodyFont,
                                .foregroundColor: primaryColor.withAlphaComponent(0.8)
                            ])
                            yPosition += 12
                        }
                    }
                    yPosition += 8
                }
                yPosition += 10
            }

            // Projects Section
            if !careerDataService.projects.isEmpty {
                let projectsTitle = theme.sectionHeaderCaps ? "PROJECTS" : "Projects"
                projectsTitle.draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: [
                    .font: sectionFont,
                    .foregroundColor: sectionTitleColor
                ])
                yPosition += 20
                for project in careerDataService.projects {
                    let title = project.title ?? ""
                    let dateRange = formatDateRange(start: project.startDate, end: project.endDate, isCurrent: project.isCurrent)
                    title.draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: [
                        .font: bodyFont,
                        .foregroundColor: primaryColor
                    ])
                    dateRange.draw(at: CGPoint(x: rightMargin - 100, y: yPosition), withAttributes: [
                        .font: captionFont,
                        .foregroundColor: primaryColor.withAlphaComponent(0.6)
                    ])
                    yPosition += 15
                    if let technologies = project.technologies as? [String], !technologies.isEmpty {
                        let techText = technologies.joined(separator: ", ")
                        techText.draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: [
                            .font: captionFont,
                            .foregroundColor: accentColor
                        ])
                        yPosition += 13
                    }
                    if let description = project.projectDescription, !description.isEmpty {
                        let lines = wrapText(description, maxWidth: rightMargin - leftMargin, attributes: [
                            .font: bodyFont,
                            .foregroundColor: primaryColor.withAlphaComponent(0.8)
                        ])
                        for line in lines {
                            line.draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: [
                                .font: bodyFont,
                                .foregroundColor: primaryColor.withAlphaComponent(0.8)
                            ])
                            yPosition += 12
                        }
                    }
                    yPosition += 8
                }
                yPosition += 10
            }

            // Internships Section
            if !careerDataService.internships.isEmpty {
                let internshipsTitle = theme.sectionHeaderCaps ? "INTERNSHIPS" : "Internships"
                internshipsTitle.draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: [
                    .font: sectionFont,
                    .foregroundColor: sectionTitleColor
                ])
                yPosition += 20
                for internship in careerDataService.internships {
                    let title = internship.title ?? ""
                    let dateRange = formatDateRange(start: internship.startDate, end: internship.endDate, isCurrent: internship.isCurrent)
                    title.draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: [
                        .font: bodyFont,
                        .foregroundColor: primaryColor
                    ])
                    dateRange.draw(at: CGPoint(x: rightMargin - 100, y: yPosition), withAttributes: [
                        .font: captionFont,
                        .foregroundColor: primaryColor.withAlphaComponent(0.6)
                    ])
                    yPosition += 15
                    if let company = internship.company {
                        company.draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: [
                            .font: captionFont,
                            .foregroundColor: accentColor
                        ])
                        yPosition += 13
                    }
                    if let description = internship.internshipDescription, !description.isEmpty {
                        let lines = wrapText(description, maxWidth: rightMargin - leftMargin, attributes: [
                            .font: bodyFont,
                            .foregroundColor: primaryColor.withAlphaComponent(0.8)
                        ])
                        for line in lines {
                            line.draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: [
                                .font: bodyFont,
                                .foregroundColor: primaryColor.withAlphaComponent(0.8)
                            ])
                            yPosition += 12
                        }
                    }
                    yPosition += 8
                }
                yPosition += 10
            }

            // Certifications Section
            if !careerDataService.certifications.isEmpty {
                let certificationsTitle = theme.sectionHeaderCaps ? "CERTIFICATIONS" : "Certifications"
                certificationsTitle.draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: [
                    .font: sectionFont,
                    .foregroundColor: sectionTitleColor
                ])
                yPosition += 20
                for certification in careerDataService.certifications {
                    let title = certification.name ?? ""
                    title.draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: [
                        .font: bodyFont,
                        .foregroundColor: primaryColor
                    ])
                    yPosition += 15
                    if let organization = certification.issuingOrganization {
                        organization.draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: [
                            .font: captionFont,
                            .foregroundColor: accentColor
                        ])
                        yPosition += 13
                    }
                    yPosition += 8
                }
                yPosition += 10
            }

            // Skills Section
            let skillsTitle = theme.sectionHeaderCaps ? "SKILLS" : "Skills"
            skillsTitle.draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: [
                .font: sectionFont,
                .foregroundColor: sectionTitleColor
            ])
            yPosition += 20
            let categories = skillManager.getCategories()
            for category in categories {
                let catTitle = theme.sectionHeaderCaps ? category.uppercased() : category
                catTitle.draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: [
                    .font: bodyFont,
                    .foregroundColor: accentColor
                ])
                yPosition += 15
                let skillsInCategory = skillManager.getSkillsByCategory(category)
                let skillsText = skillsInCategory.map { $0.name ?? "" }.joined(separator: ", ")
                skillsText.draw(at: CGPoint(x: leftMargin + 10, y: yPosition), withAttributes: [
                    .font: captionFont,
                    .foregroundColor: primaryColor.withAlphaComponent(0.7)
                ])
                yPosition += 15
            }
            // Languages Section
            let languages = loadLanguages()
            if !languages.isEmpty {
                let languagesTitle = theme.sectionHeaderCaps ? "LANGUAGES" : "Languages"
                languagesTitle.draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: [
                    .font: sectionFont,
                    .foregroundColor: sectionTitleColor
                ])
                yPosition += 20
                for lang in languages {
                    lang.name.draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: [
                        .font: bodyFont,
                        .foregroundColor: primaryColor
                    ])
                    lang.proficiency.rawValue.draw(at: CGPoint(x: rightMargin - 120, y: yPosition), withAttributes: [
                        .font: captionFont,
                        .foregroundColor: accentColor
                    ])
                    yPosition += 15
                }
            }
        }
        return data
    }
    
    private func loadLanguages() -> [Language] {
        if let data = UserDefaults.standard.data(forKey: "userLanguages"),
           let decoded = try? JSONDecoder().decode([Language].self, from: data) {
            return decoded
        }
        return []
    }
    
    private func wrapText(_ text: String, maxWidth: CGFloat, attributes: [NSAttributedString.Key: Any]) -> [String] {
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let framesetter = CTFramesetterCreateWithAttributedString(attributedString)
        let path = CGPath(rect: CGRect(x: 0, y: 0, width: maxWidth, height: CGFloat.greatestFiniteMagnitude), transform: nil)
        let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, nil)
        
        let lines = CTFrameGetLines(frame) as! [CTLine]
        var wrappedLines: [String] = []
        
        for line in lines {
            let lineRange = CTLineGetStringRange(line)
            let lineString = (text as NSString).substring(with: NSRange(location: lineRange.location, length: lineRange.length))
            wrappedLines.append(lineString)
        }
        
        return wrappedLines
    }
}

#Preview {
    ResumeExportView()
        .environmentObject(ProfileManager())
        .environmentObject(SkillManager())
} 