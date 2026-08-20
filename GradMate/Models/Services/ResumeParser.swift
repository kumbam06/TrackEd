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
    
    static func parse(text raw: String, fallbackName: String = "", fallbackEmail: String = "") -> ParsedResume {
        let text = normalize(raw)
        var resume = ParsedResume()
        
        resume.email = firstMatch(in: text, pattern: #"[A-Z0-9._%+\-]+@[A-Z0-9.\-]+\.[A-Z]{2,}"#, options: [.caseInsensitive]) ?? fallbackEmail
        if resume.email.isEmpty {
            resume.email = firstMatch(in: text, pattern: #"(?:e-?mail)\s*:?\s*([A-Z0-9._%+\-]+@[A-Z0-9.\-]+\.[A-Z]{2,})"#, options: [.caseInsensitive]) ?? fallbackEmail
        }
        resume.phone = sanitizePhone(firstMatch(in: text, pattern: #"(\+?\d[\d(). \-]{7,}\d)"#) ?? "")
        resume.linkedin = firstMatch(in: text, pattern: #"(?:https?://)?(?:www\.)?linkedin\.com/in/[A-Za-z0-9\-_/]+"#, options: [.caseInsensitive]) ?? ""
        if let site = firstMatch(in: text, pattern: #"(?:https?://)?(?:www\.)?(?:github\.com|gitlab\.com|[A-Za-z0-9\-]+\.(?:dev|io|com|me|uk|co\.uk))[^\s]*"#, options: [.caseInsensitive]),
           !site.lowercased().contains("linkedin") {
            resume.website = site
        }
        resume.address = firstAddress(in: text)
        
        let sections = splitSections(text)
        let headerLines = sections[.header] ?? []
        let identity = resolveIdentity(headerLines: headerLines, fallbackName: fallbackName)
        resume.name = identity.name
        resume.role = identity.role
        
        let summary = (sections[.summary] ?? []).joined(separator: " ")
        resume.bio = summary
        
        resume.skills = parseSkillList(sections[.skills] ?? [])
        resume.languages = parseLanguages(sections[.languages] ?? [])
        resume.workExperiences = parseWork(sections[.work] ?? [])
        resume.internships = parseInternships(sections[.internship] ?? [])
        resume.projects = parseProjects(sections[.project] ?? [])
        resume.certifications = parseCertifications(sections[.certification] ?? [])
        
        if resume.workExperiences.isEmpty {
            let datedLines = text.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            resume.workExperiences = parseWork(datedLines.filter { parseDateRange($0) != nil })
        }
        if resume.skills.isEmpty {
            resume.skills = parseSkillList(fallbackSkills(from: text))
        }
        return resume
    }
    
    static func looksLikeJobTitle(_ line: String) -> Bool {
        let tokens = line.lowercased().split(whereSeparator: { !$0.isLetter }).map(String.init)
        let jobTokens: Set<String> = [
            "head", "chief", "director", "manager", "engineer", "developer", "intern",
            "consultant", "lead", "principal", "officer", "analyst", "architect",
            "security", "specialist", "designer", "administrator", "executive",
            "president", "founder", "senior", "junior", "staff", "ios", "android",
            "information", "ciso", "cto", "ceo", "cfo", "product", "mobile"
        ]
        let hits = tokens.filter { jobTokens.contains($0) }.count
        return hits >= 2
    }
    
    static func looksLikePersonName(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        let tokens = trimmed.split(separator: " ")
        guard (2...4).contains(tokens.count), trimmed.count <= 40 else { return false }
        guard !looksLikeJobTitle(trimmed) else { return false }
        return tokens.allSatisfy { token in
            let value = String(token).replacingOccurrences(of: "-", with: "")
            return value.first?.isUppercase == true && value.unicodeScalars.allSatisfy { CharacterSet.letters.contains($0) }
        }
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
        guard compact.count <= 32 else { return nil }
        let headers: [String: Section] = [
            "workexperience": .work,
            "professionalexperience": .work,
            "employmenthistory": .work,
            "employment": .work,
            "experience": .work,
            "internship": .internship,
            "internships": .internship,
            "project": .project,
            "projects": .project,
            "personalprojects": .project,
            "certification": .certification,
            "certifications": .certification,
            "certificates": .certification,
            "licenses": .certification,
            "skill": .skills,
            "skills": .skills,
            "technicalskills": .skills,
            "skillset": .skills,
            "language": .languages,
            "languages": .languages,
            "education": .education,
            "academic": .education,
            "summary": .summary,
            "profile": .summary,
            "objective": .summary,
            "aboutme": .summary,
            "about": .summary,
            "professionalsummary": .summary,
            "contact": .header,
            "contactinformation": .header,
            "contactdetails": .header
        ]
        return headers[compact]
    }
    
    private static func resolveIdentity(headerLines: [String], fallbackName: String) -> (name: String, role: String) {
        let contactLike: (String) -> Bool = { line in
            line.contains("@") ||
            line.lowercased().contains("linkedin") ||
            line.lowercased().contains("http") ||
            line.range(of: #"\d{3}"#, options: .regularExpression) != nil
        }
        let candidates = headerLines.filter { !contactLike($0) && $0.count < 80 }
        let personName = candidates.first(where: looksLikePersonName)
            ?? (looksLikePersonName(fallbackName) ? fallbackName : "")
        let role = candidates.first(where: { looksLikeJobTitle($0) && $0.caseInsensitiveCompare(personName) != .orderedSame })
            ?? candidates.first(where: { $0 != personName })
            ?? ""
        let name = personName.isEmpty ? (looksLikeJobTitle(fallbackName) ? "" : fallbackName) : personName
        return (name, role)
    }
    
    private static func sanitizePhone(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private static func firstAddress(in text: String) -> String {
        let lines = text.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }
        return lines.first(where: {
            let lower = $0.lowercased()
            return lower.contains("street") || lower.contains("road") || lower.contains("close") ||
                lower.contains("avenue") || lower.contains("uk") || lower.contains("usa") ||
                (lower.contains(",") && $0.split(separator: " ").count >= 3 && $0.count < 80 && !$0.contains("@"))
        }) ?? ""
    }
    
    private static func parseSkillList(_ lines: [String]) -> [String] {
        let joined = lines.joined(separator: ",")
        let parts = joined.components(separatedBy: CharacterSet(charactersIn: ",|/•·;"))
        let noise: Set<String> = [
            "programming", "tools", "frameworks", "technologies", "technical",
            "soft", "skills", "skillset", "languages", "language", "category",
            "item"
        ]
        return Array(Set(parts.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter {
            $0.count > 1 && $0.count < 40 && !noise.contains($0.lowercased())
        })).sorted()
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
        let entries = parseDatedEntries(lines)
        let source = entries.isEmpty ? parseUndatedJobLines(lines) : entries
        return source.map { entry in
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
    
    private static func parseUndatedJobLines(_ lines: [String]) -> [DatedEntry] {
        lines.compactMap { line in
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard (8..<120).contains(trimmed.count) else { return nil }
            guard looksLikeJobTitle(trimmed) || trimmed.contains("|") || trimmed.localizedCaseInsensitiveContains(" at ") else { return nil }
            let pieces = splitHeader(stripDates(trimmed))
            return DatedEntry(
                title: pieces.title,
                role: pieces.title,
                company: pieces.company,
                location: pieces.location,
                start: Date(),
                end: nil,
                isCurrent: false,
                detail: "",
                technologies: nil
            )
        }
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
