import Foundation

struct ParsedResume: Equatable {
    var name: String = ""
    var role: String = ""
    var bio: String = ""
    var email: String = ""
    var phone: String = ""
    var linkedin: String = ""
    var website: String = ""
    var address: String = ""
    var skills: [String] = []
    var languages: [Language] = []
    var workExperiences: [WorkExperience] = []
    var projects: [Project] = []
    var internships: [Internship] = []
    var certifications: [Certification] = []
    
    var importedItemCount: Int {
        skills.count + languages.count + workExperiences.count + projects.count + internships.count + certifications.count
    }
}

enum ResumeParser {
    private enum Section: String {
        case header, summary, work, internship, project, certification, skills, languages, education, other
    }
    
    static func parse(text raw: String) -> ParsedResume {
        let text = normalize(raw)
        var resume = ParsedResume()
        
        resume.email = firstMatch(in: text, pattern: #"[A-Z0-9._%+\-]+@[A-Z0-9.\-]+\.[A-Z]{2,}"#, options: [.caseInsensitive]) ?? ""
        resume.phone = firstMatch(in: text, pattern: #"(\+?\d[\d(). \-]{7,}\d)"#) ?? ""
        resume.linkedin = firstMatch(in: text, pattern: #"(?:https?://)?(?:www\.)?linkedin\.com/in/[A-Za-z0-9\-_/]+"#, options: [.caseInsensitive]) ?? ""
        resume.website = firstMatch(in: text, pattern: #"(?:https?://)?(?:www\.)?(?:github\.com|gitlab\.com|portfolio\.[^\s]+|[A-Za-z0-9\-]+\.(?:dev|io|com|me))[^\s]*"#, options: [.caseInsensitive]) ?? ""
        
        let sections = splitSections(text)
        let headerLines = sections[.header] ?? []
        let contactLike: (String) -> Bool = { line in
            line.contains("@") ||
            line.lowercased().contains("linkedin") ||
            line.range(of: #"\d{3}"#, options: .regularExpression) != nil
        }
        resume.name = headerLines.first(where: { !contactLike($0) && $0.split(separator: " ").count <= 6 }) ?? ""
        resume.role = headerLines.dropFirst().first(where: { !contactLike($0) && $0.count < 80 }) ?? ""
        
        let summary = (sections[.summary] ?? []).joined(separator: " ")
        resume.bio = summary
        
        resume.skills = parseSkillList(sections[.skills] ?? [])
        resume.languages = parseLanguages(sections[.languages] ?? [])
        resume.workExperiences = parseWork(sections[.work] ?? [])
        resume.internships = parseInternships(sections[.internship] ?? [])
        resume.projects = parseProjects(sections[.project] ?? [])
        resume.certifications = parseCertifications(sections[.certification] ?? [])
        
        if resume.skills.isEmpty {
            resume.skills = parseSkillList(fallbackSkills(from: text))
        }
        return resume
    }
    
    private static func normalize(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\u{00a0}", with: " ")
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .replacingOccurrences(of: #"\n{3,}"#, with: "\n\n", options: .regularExpression)
    }
    
    private static func splitSections(_ text: String) -> [Section: [String]] {
        let lines = text.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }
        var result: [Section: [String]] = [:]
        var current: Section = .header
        for line in lines {
            if let section = detectSection(line) {
                current = section
                continue
            }
            guard !line.isEmpty else { continue }
            result[current, default: []].append(line)
        }
        return result
    }
    
    private static func detectSection(_ line: String) -> Section? {
        let cleaned = line.lowercased().trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        let compact = cleaned.replacingOccurrences(of: " ", with: "")
        if compact.count > 40 { return nil }
        if matches(compact, ["workexperience", "professionalexperience", "employmenthistory", "experience"]) { return .work }
        if matches(compact, ["internship", "internships"]) { return .internship }
        if matches(compact, ["project", "projects", "personalprojects"]) { return .project }
        if matches(compact, ["certification", "certifications", "certificates", "licenses"]) { return .certification }
        if matches(compact, ["skill", "skills", "technicalskills"]) { return .skills }
        if matches(compact, ["language", "languages"]) { return .languages }
        if matches(compact, ["education", "academic"]) { return .education }
        if matches(compact, ["summary", "profile", "objective", "aboutme", "about"]) { return .summary }
        return nil
    }
    
    private static func matches(_ value: String, _ keys: [String]) -> Bool {
        keys.contains { value == $0 || value.hasPrefix($0) }
    }
    
    private static func parseSkillList(_ lines: [String]) -> [String] {
        let joined = lines.joined(separator: ",")
        let parts = joined.components(separatedBy: CharacterSet(charactersIn: ",|/•·;"))
        return Array(Set(parts.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { $0.count > 1 && $0.count < 40 })).sorted()
    }
    
    private static func fallbackSkills(from text: String) -> [String] {
        guard let range = text.range(of: #"skills[:\s]+(.+)"#, options: [.regularExpression, .caseInsensitive]) else { return [] }
        return [String(text[range])]
    }
    
    private static func parseLanguages(_ lines: [String]) -> [Language] {
        lines.compactMap { line in
            let cleaned = line.replacingOccurrences(of: "•", with: "").trimmingCharacters(in: .whitespaces)
            guard !cleaned.isEmpty else { return nil }
            let parts = cleaned.components(separatedBy: CharacterSet(charactersIn: "()–-|,"))
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            let name = parts.first ?? cleaned
            let levelText = parts.dropFirst().first?.lowercased() ?? ""
            let level: Language.ProficiencyLevel
            if levelText.contains("native") { level = .native }
            else if levelText.contains("fluent") { level = .fluent }
            else if levelText.contains("advanced") { level = .advanced }
            else if levelText.contains("intermediate") { level = .intermediate }
            else { level = .beginner }
            return Language(name: name, proficiency: level)
        }
    }
    
    private static func parseWork(_ lines: [String]) -> [WorkExperience] {
        parseDatedEntries(lines).map { entry in
            WorkExperience(
                title: entry.title,
                company: entry.company,
                location: entry.location,
                startDate: entry.start,
                endDate: entry.isCurrent ? nil : entry.end,
                isCurrent: entry.isCurrent,
                description: entry.detail,
                technologies: entry.technologies
            )
        }
    }
    
    private static func parseInternships(_ lines: [String]) -> [Internship] {
        parseDatedEntries(lines).map { entry in
            Internship(
                title: entry.title,
                role: entry.title,
                company: entry.company,
                location: entry.location,
                startDate: entry.start,
                endDate: entry.isCurrent ? nil : entry.end,
                isCurrent: entry.isCurrent,
                description: entry.detail,
                technologies: entry.technologies
            )
        }
    }
    
    private static func parseProjects(_ lines: [String]) -> [Project] {
        parseDatedEntries(lines).map { entry in
            Project(
                title: entry.title,
                role: entry.role.isEmpty ? "Contributor" : entry.role,
                company: entry.company,
                location: entry.location,
                startDate: entry.start,
                endDate: entry.isCurrent ? nil : entry.end,
                isCurrent: entry.isCurrent,
                description: entry.detail,
                technologies: entry.technologies
            )
        }
    }
    
    private static func parseCertifications(_ lines: [String]) -> [Certification] {
        parseDatedEntries(lines).map { entry in
            Certification(
                title: entry.title,
                organization: entry.company,
                location: entry.location,
                dateReceived: entry.start,
                dateExpiry: entry.end,
                description: entry.detail,
                credentialID: nil
            )
        }
    }
    
    private struct DatedEntry {
        var title: String
        var role: String
        var company: String
        var location: String
        var start: Date
        var end: Date?
        var isCurrent: Bool
        var detail: String
        var technologies: [String]?
    }
    
    private static func parseDatedEntries(_ lines: [String]) -> [DatedEntry] {
        var entries: [DatedEntry] = []
        var current: DatedEntry?
        var details: [String] = []
        
        func flush() {
            guard var item = current else { return }
            item.detail = details.joined(separator: " ")
            entries.append(item)
            current = nil
            details = []
        }
        
        for line in lines {
            if let dates = parseDateRange(line), looksLikeHeader(line) {
                flush()
                let header = stripDates(line)
                let pieces = splitHeader(header)
                current = DatedEntry(
                    title: pieces.title,
                    role: pieces.title,
                    company: pieces.company,
                    location: pieces.location,
                    start: dates.start,
                    end: dates.end,
                    isCurrent: dates.isCurrent,
                    detail: "",
                    technologies: nil
                )
            } else if current == nil && looksLikeHeader(line) {
                let pieces = splitHeader(stripDates(line))
                let dates = parseDateRange(line) ?? (start: Date(), end: nil, isCurrent: false)
                current = DatedEntry(
                    title: pieces.title,
                    role: pieces.title,
                    company: pieces.company,
                    location: pieces.location,
                    start: dates.start,
                    end: dates.end,
                    isCurrent: dates.isCurrent,
                    detail: "",
                    technologies: nil
                )
            } else if current != nil {
                details.append(line.trimmingCharacters(in: CharacterSet(charactersIn: "•-– ")))
            }
        }
        flush()
        return entries.filter { !$0.title.isEmpty }
    }
    
    private static func looksLikeHeader(_ line: String) -> Bool {
        parseDateRange(line) != nil || line.contains("|") || line.contains(" at ") || line.contains(" – ") || line.contains(" - ")
    }
    
    private static func splitHeader(_ line: String) -> (title: String, company: String, location: String) {
        let separators = [" | ", " – ", " - ", " at ", " @ "]
        for separator in separators {
            if line.contains(separator) {
                let parts = line.components(separatedBy: separator).map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                return (parts.first ?? line, parts.dropFirst().first ?? "", parts.dropFirst(2).first ?? "")
            }
        }
        return (line, "", "")
    }
    
    private static func stripDates(_ line: String) -> String {
        let stripped = line.replacingOccurrences(
            of: #"(Jan(?:uary)?|Feb(?:ruary)?|Mar(?:ch)?|Apr(?:il)?|May|Jun(?:e)?|Jul(?:y)?|Aug(?:ust)?|Sep(?:t(?:ember)?)?|Oct(?:ober)?|Nov(?:ember)?|Dec(?:ember)?)[a-z]*\.?\s*\d{4}|\d{4}|\b(?:present|current)\b"#,
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )
        return stripped.replacingOccurrences(of: #"[-–—|]+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private static func parseDateRange(_ line: String) -> (start: Date, end: Date?, isCurrent: Bool)? {
        let pattern = #"(Jan(?:uary)?|Feb(?:ruary)?|Mar(?:ch)?|Apr(?:il)?|May|Jun(?:e)?|Jul(?:y)?|Aug(?:ust)?|Sep(?:t(?:ember)?)?|Oct(?:ober)?|Nov(?:ember)?|Dec(?:ember)?)?[ .]*((?:19|20)\d{2})"#
        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let nsline = line as NSString
        let matches = regex?.matches(in: line, range: NSRange(location: 0, length: nsline.length)) ?? []
        guard let first = matches.first else {
            if line.lowercased().contains("present") { return (Date(), nil, true) }
            return nil
        }
        let start = date(from: nsline.substring(with: first.range)) ?? Date()
        let isCurrent = line.lowercased().contains("present") || line.lowercased().contains("current")
        let end: Date?
        if matches.count > 1 {
            end = date(from: nsline.substring(with: matches[1].range))
        } else {
            end = isCurrent ? nil : nil
        }
        return (start, end, isCurrent)
    }
    
    private static func date(from text: String) -> Date? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        let formats = ["MMMM yyyy", "MMM yyyy", "yyyy", "MMMM yyyy"]
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: trimmed) { return date }
        }
        return nil
    }
    
    private static func firstMatch(in text: String, pattern: String, options: NSRegularExpression.Options = []) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range),
              let swiftRange = Range(match.range, in: text) else { return nil }
        return String(text[swiftRange]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
