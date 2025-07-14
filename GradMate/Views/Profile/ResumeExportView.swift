//
//  ResumeExportView.swift
//  GradMate
//
//  Created by Pradeep Reddy Kumbam on 23/06/2025.
//

import SwiftUI
import PDFKit

struct ResumeExportView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var profileManager: ProfileManager
    @EnvironmentObject private var skillManager: SkillManager
    @StateObject private var careerDataService = CareerDataService()
    
    @State private var isGenerating = false
    @State private var pdfData: Data?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                
                VStack(spacing: 24) {
                    resumeHeader5D
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
                    .fontWeight(.bold)
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
                    .fontWeight(.heavy)
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
        VStack(alignment: .leading, spacing: 20) {
            Text("RESUME PREVIEW")
                .font(.headline)
                .fontWeight(.heavy)
                .foregroundColor(.white)
                .kerning(1)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Profile Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text(profileManager.currentProfile?.name ?? "John Doe")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text(profileManager.currentProfile?.role ?? "iOS Developer")
                            .font(.subheadline)
                            .foregroundColor(.accentColor)
                            .fontWeight(.medium)
                        
                        if let email = profileManager.currentProfile?.email {
                            Text(email)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    
                    Divider()
                        .background(Color(.secondarySystemBackground).opacity(0.3))
                    
                    // Work Experience Section
                    if !careerDataService.workExperiences.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("WORK EXPERIENCE")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            ForEach(Array(careerDataService.workExperiences.prefix(3)), id: \.id) { experience in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(experience.title ?? "")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                        Spacer()
                                        Text(formatDateRange(start: experience.startDate, end: experience.endDate, isCurrent: experience.isCurrent))
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    Text(experience.company ?? "")
                                        .font(.caption)
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                        
                        Divider()
                            .background(Color(.secondarySystemBackground).opacity(0.3))
                    }
                    
                    // Projects Section
                    if !careerDataService.projects.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("PROJECTS")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            ForEach(Array(careerDataService.projects.prefix(3)), id: \.id) { project in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(project.title ?? "")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                        Spacer()
                                        Text(formatDateRange(start: project.startDate, end: project.endDate, isCurrent: project.isCurrent))
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    if let technologies = project.technologies, !technologies.isEmpty {
                                        Text(technologies.joined(separator: ", "))
                                            .font(.caption)
                                            .foregroundColor(.accentColor)
                                    }
                                }
                            }
                        }
                        
                        Divider()
                            .background(Color(.secondarySystemBackground).opacity(0.3))
                    }
                    
                    // Internships Section
                    if !careerDataService.internships.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("INTERNSHIPS")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            ForEach(Array(careerDataService.internships.prefix(2)), id: \.id) { internship in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(internship.title ?? "")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                        Spacer()
                                        Text(formatDateRange(start: internship.startDate, end: internship.endDate, isCurrent: internship.isCurrent))
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    Text(internship.company ?? "")
                                        .font(.caption)
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                        
                        Divider()
                            .background(Color(.secondarySystemBackground).opacity(0.3))
                    }
                    
                    // Certifications Section
                    if !careerDataService.certifications.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("CERTIFICATIONS")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            ForEach(Array(careerDataService.certifications.prefix(3)), id: \.id) { certification in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(certification.name ?? "")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                    Text(certification.issuingOrganization ?? "")
                                        .font(.caption)
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                        
                        Divider()
                            .background(Color(.secondarySystemBackground).opacity(0.3))
                    }
                    
                    // Skills Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("SKILLS")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        let categories = skillManager.getCategories()
                        ForEach(categories, id: \.self) { category in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(category.uppercased())
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.accentColor)
                                    .kerning(0.5)
                                
                                let skillsInCategory = skillManager.getSkillsByCategory(category)
                                Text(skillsInCategory.map { $0.name ?? "" }.joined(separator: ", "))
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
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
                .fill(Color(.secondarySystemBackground).opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.accentColor.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: Color.accentColor.opacity(0.1), radius: 8, x: 0, y: 4)
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
            
            _ = context.cgContext
            let attributes = [
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 11),
                NSAttributedString.Key.foregroundColor: UIColor.black
            ]
            
            let titleAttributes = [
                NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 24),
                NSAttributedString.Key.foregroundColor: UIColor.black
            ]
            
            let subtitleAttributes = [
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16),
                NSAttributedString.Key.foregroundColor: UIColor.systemBlue
            ]
            
            let sectionAttributes = [
                NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 16),
                NSAttributedString.Key.foregroundColor: UIColor.black
            ]
            
            let subsectionAttributes = [
                NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 13),
                NSAttributedString.Key.foregroundColor: UIColor.black
            ]
            
            let companyAttributes = [
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12),
                NSAttributedString.Key.foregroundColor: UIColor.systemBlue
            ]
            
            let dateAttributes = [
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 10),
                NSAttributedString.Key.foregroundColor: UIColor.gray
            ]
            
            var yPosition: CGFloat = 50
            let leftMargin: CGFloat = 50
            let rightMargin: CGFloat = 545.2
            
            // Name
            let name = profileManager.currentProfile?.name ?? "John Doe"
            name.draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: titleAttributes)
            yPosition += 35
            
            // Role
            let role = profileManager.currentProfile?.role ?? "iOS Developer"
            role.draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: subtitleAttributes)
            yPosition += 25
            
            // Email
            if let email = profileManager.currentProfile?.email {
                email.draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: attributes)
                yPosition += 20
            }
            
            yPosition += 20
            
            // Work Experience Section
            if !careerDataService.workExperiences.isEmpty {
                "WORK EXPERIENCE".draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: sectionAttributes)
                yPosition += 20
                
                for experience in careerDataService.workExperiences.prefix(3) {
                    // Title and Date
                    let title = experience.title ?? ""
                    let dateRange = formatDateRange(start: experience.startDate, end: experience.endDate, isCurrent: experience.isCurrent)
                    
                    title.draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: subsectionAttributes)
                    dateRange.draw(at: CGPoint(x: rightMargin - 100, y: yPosition), withAttributes: dateAttributes)
                    yPosition += 15
                    
                    // Company
                    if let company = experience.company {
                        company.draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: companyAttributes)
                        yPosition += 15
                    }
                    
                    // Description
                    if let description = experience.workDescription, !description.isEmpty {
                        let lines = wrapText(description, maxWidth: rightMargin - leftMargin, attributes: attributes)
                        for line in lines.prefix(3) {
                            line.draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: attributes)
                            yPosition += 12
                        }
                    }
                    
                    yPosition += 8
                }
                
                yPosition += 10
            }
            
            // Projects Section
            if !careerDataService.projects.isEmpty {
                "PROJECTS".draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: sectionAttributes)
                yPosition += 20
                
                for project in careerDataService.projects.prefix(3) {
                    // Title and Date
                    let title = project.title ?? ""
                    let dateRange = formatDateRange(start: project.startDate, end: project.endDate, isCurrent: project.isCurrent)
                    
                    title.draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: subsectionAttributes)
                    dateRange.draw(at: CGPoint(x: rightMargin - 100, y: yPosition), withAttributes: dateAttributes)
                    yPosition += 15
                    
                    // Technologies
                    if let technologies = project.technologies, !technologies.isEmpty {
                        let techText = technologies.joined(separator: ", ")
                        techText.draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: companyAttributes)
                        yPosition += 15
                    }
                    
                    // Description
                    if let description = project.projectDescription, !description.isEmpty {
                        let lines = wrapText(description, maxWidth: rightMargin - leftMargin, attributes: attributes)
                        for line in lines.prefix(2) {
                            line.draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: attributes)
                            yPosition += 12
                        }
                    }
                    
                    yPosition += 8
                }
                
                yPosition += 10
            }
            
            // Internships Section
            if !careerDataService.internships.isEmpty {
                "INTERNSHIPS".draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: sectionAttributes)
                yPosition += 20
                
                for internship in careerDataService.internships.prefix(2) {
                    // Title and Date
                    let title = internship.title ?? ""
                    let dateRange = formatDateRange(start: internship.startDate, end: internship.endDate, isCurrent: internship.isCurrent)
                    
                    title.draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: subsectionAttributes)
                    dateRange.draw(at: CGPoint(x: rightMargin - 100, y: yPosition), withAttributes: dateAttributes)
                    yPosition += 15
                    
                    // Company
                    if let company = internship.company {
                        company.draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: companyAttributes)
                        yPosition += 15
                    }
                    
                    yPosition += 8
                }
                
                yPosition += 10
            }
            
            // Certifications Section
            if !careerDataService.certifications.isEmpty {
                "CERTIFICATIONS".draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: sectionAttributes)
                yPosition += 20
                
                for certification in careerDataService.certifications.prefix(3) {
                    // Title
                    let title = certification.name ?? ""
                    title.draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: subsectionAttributes)
                    yPosition += 15
                    
                    // Organization
                    if let organization = certification.issuingOrganization {
                        organization.draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: companyAttributes)
                        yPosition += 15
                    }
                    
                    yPosition += 8
                }
                
                yPosition += 10
            }
            
            // Skills Section
            "SKILLS".draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: sectionAttributes)
            yPosition += 20
            
            let categories = skillManager.getCategories()
            for category in categories {
                category.uppercased().draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: subsectionAttributes)
                yPosition += 15
                
                let skillsInCategory = skillManager.getSkillsByCategory(category)
                let skillsText = skillsInCategory.map { $0.name ?? "" }.joined(separator: ", ")
                skillsText.draw(at: CGPoint(x: leftMargin + 10, y: yPosition), withAttributes: attributes)
                yPosition += 15
            }
        }
        
        return data
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