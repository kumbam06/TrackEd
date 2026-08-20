import UIKit
import SwiftUI

struct ResumeSnapshot {
    var name: String
    var role: String
    var bio: String
    var email: String
    var phone: String
    var linkedin: String
    var website: String
    var address: String
    var workExperiences: [WorkExperience]
    var projects: [Project]
    var internships: [Internship]
    var certifications: [Certification]
    var skillsByCategory: [(category: String, skills: [String])]
    var languages: [Language]
    
    static func current(
        profile: Profile?,
        skills: [SkillEntity],
        career: CareerDataService,
        languages: [Language]
    ) -> ResumeSnapshot {
        let grouped = Dictionary(grouping: skills) { $0.category ?? "General" }
        let skillPairs = grouped.keys.sorted().map { category in
            (category: category, skills: grouped[category]?.compactMap(\.name) ?? [])
        }
        return ResumeSnapshot(
            name: profile?.name ?? "",
            role: profile?.role ?? "",
            bio: profile?.bio ?? "",
            email: profile?.email ?? "",
            phone: profile?.phone ?? "",
            linkedin: profile?.linkedin ?? "",
            website: profile?.website ?? "",
            address: profile?.address ?? "",
            workExperiences: career.workExperienceModels,
            projects: career.projectModels,
            internships: career.internshipModels,
            certifications: career.certificationModels,
            skillsByCategory: skillPairs,
            languages: languages
        )
    }
    
    var hasContent: Bool {
        !name.isEmpty || !workExperiences.isEmpty || !projects.isEmpty || !skillsByCategory.isEmpty
    }
}

enum ResumePDFBuilder {
    static func makePDF(snapshot: ResumeSnapshot, theme: ResumeTheme) -> Data {
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextCreator: "GradMate",
            kCGPDFContextAuthor: snapshot.name.isEmpty ? "Student" : snapshot.name
        ] as [String: Any]
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        let primary = UIColor(theme.primaryColor)
        let accent = UIColor(theme.accentColor)
        let sectionColor = UIColor(theme.sectionTitleColor)
        
        return renderer.pdfData { context in
            context.beginPage()
            var y: CGFloat = 48
            let left: CGFloat = 48
            let width: CGFloat = pageRect.width - 96
            
            func newPageIfNeeded(_ needed: CGFloat) {
                if y + needed > pageRect.height - 48 {
                    context.beginPage()
                    y = 48
                }
            }
            
            func draw(_ text: String, font: UIFont, color: UIColor, x: CGFloat = left) {
                newPageIfNeeded(font.lineHeight + 4)
                text.draw(at: CGPoint(x: x, y: y), withAttributes: [
                    .font: font,
                    .foregroundColor: color
                ])
                y += font.lineHeight + 2
            }
            
            func drawWrapped(_ text: String, font: UIFont, color: UIColor) {
                let paragraph = NSMutableParagraphStyle()
                paragraph.lineSpacing = 2
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: color,
                    .paragraphStyle: paragraph
                ]
                let attributed = NSAttributedString(string: text, attributes: attributes)
                let box = attributed.boundingRect(with: CGSize(width: width, height: .greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
                newPageIfNeeded(box.height + 6)
                attributed.draw(in: CGRect(x: left, y: y, width: width, height: ceil(box.height)))
                y += ceil(box.height) + 6
            }
            
            func section(_ title: String) {
                y += 8
                let label = theme.sectionHeaderCaps ? title.uppercased() : title
                draw(label, font: .systemFont(ofSize: 13, weight: .semibold), color: sectionColor)
                let path = UIBezierPath()
                path.move(to: CGPoint(x: left, y: y))
                path.addLine(to: CGPoint(x: left + width, y: y))
                accent.withAlphaComponent(0.35).setStroke()
                path.lineWidth = 1
                path.stroke()
                y += 10
            }
            
            let displayName = snapshot.name.isEmpty ? "Your Name" : snapshot.name
            draw(displayName, font: .systemFont(ofSize: 26, weight: .bold), color: primary)
            if !snapshot.role.isEmpty {
                draw(snapshot.role, font: .systemFont(ofSize: 14, weight: .medium), color: accent)
            }
            
            let contacts: [(String, String)] = [
                ("Email", snapshot.email),
                ("Phone", snapshot.phone),
                ("LinkedIn", snapshot.linkedin),
                ("Website", snapshot.website),
                ("Address", snapshot.address)
            ].filter { !$0.1.isEmpty }
            if !contacts.isEmpty {
                for contact in contacts {
                    draw("\(contact.0): \(contact.1)", font: .systemFont(ofSize: 10), color: primary.withAlphaComponent(0.7))
                }
                y += 4
            }
            if !snapshot.bio.isEmpty {
                drawWrapped(snapshot.bio, font: .systemFont(ofSize: 11), color: primary.withAlphaComponent(0.85))
            }
            
            func drawExperience(title: String, company: String, location: String, dates: String, detail: String, tech: [String]?) {
                newPageIfNeeded(40)
                draw(title.isEmpty ? company : title, font: .systemFont(ofSize: 12, weight: .semibold), color: primary)
                let meta = [company, location, dates].filter { !$0.isEmpty && $0 != title }.joined(separator: "  •  ")
                if !meta.isEmpty {
                    draw(meta, font: .systemFont(ofSize: 10), color: accent)
                }
                if !detail.isEmpty {
                    drawWrapped(detail, font: .systemFont(ofSize: 11), color: primary.withAlphaComponent(0.8))
                }
                if let tech, !tech.isEmpty {
                    drawWrapped(tech.joined(separator: ", "), font: .systemFont(ofSize: 10), color: accent)
                }
            }
            
            if !snapshot.workExperiences.isEmpty {
                section("Work Experience")
                for item in snapshot.workExperiences {
                    drawExperience(title: item.title, company: item.company, location: item.location, dates: dateRange(item.startDate, item.endDate, item.isCurrent), detail: item.description, tech: item.technologies)
                }
            }
            if !snapshot.internships.isEmpty {
                section("Internships")
                for item in snapshot.internships {
                    drawExperience(title: item.title, company: item.company, location: item.location, dates: dateRange(item.startDate, item.endDate, item.isCurrent), detail: item.description, tech: item.technologies)
                }
            }
            if !snapshot.projects.isEmpty {
                section("Projects")
                for item in snapshot.projects {
                    drawExperience(title: item.title, company: item.company, location: item.location, dates: dateRange(item.startDate, item.endDate, item.isCurrent), detail: item.description, tech: item.technologies)
                }
            }
            if !snapshot.certifications.isEmpty {
                section("Certifications")
                for item in snapshot.certifications {
                    newPageIfNeeded(28)
                    draw(item.title, font: .systemFont(ofSize: 12, weight: .semibold), color: primary)
                    let org = [item.organization, dateRange(item.dateReceived, item.dateExpiry, false)].filter { !$0.isEmpty }.joined(separator: "  •  ")
                    if !org.isEmpty {
                        draw(org, font: .systemFont(ofSize: 10), color: accent)
                    }
                }
            }
            if snapshot.skillsByCategory.contains(where: { !$0.skills.isEmpty }) {
                section("Skills")
                for group in snapshot.skillsByCategory where !group.skills.isEmpty {
                    drawWrapped("\(group.category): \(group.skills.joined(separator: ", "))", font: .systemFont(ofSize: 11), color: primary.withAlphaComponent(0.85))
                }
            }
            if !snapshot.languages.isEmpty {
                section("Languages")
                drawWrapped(snapshot.languages.map { "\($0.name) (\($0.proficiency.rawValue))" }.joined(separator: "  •  "), font: .systemFont(ofSize: 11), color: primary.withAlphaComponent(0.85))
            }
        }
    }
    
    static func dateRange(_ start: Date?, _ end: Date?, _ isCurrent: Bool) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        guard let start else { return isCurrent ? "Present" : "" }
        let startText = formatter.string(from: start)
        if isCurrent { return "\(startText) – Present" }
        if let end { return "\(startText) – \(formatter.string(from: end))" }
        return startText
    }
    
    static func writeTemporaryPDF(_ data: Data, named fileName: String) -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try? data.write(to: url, options: .atomic)
        return url
    }
}
