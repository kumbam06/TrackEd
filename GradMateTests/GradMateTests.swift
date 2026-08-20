import XCTest
@testable import GradMate

final class NaturalLanguageParserTests: XCTestCase {
    private let parser = NaturalLanguageParser()
    
    func testUrgentPriorityAndTitleCleanup() {
        let parsed = parser.parseTask("Submit report urgent")
        XCTAssertEqual(parsed.priority, 3)
        XCTAssertEqual(parsed.title, "Submit report")
    }
    
    func testTomorrowKeepsTitleWithoutDateWords() {
        let parsed = parser.parseTask("Study SwiftUI at 8pm tomorrow")
        XCTAssertFalse(parsed.title.lowercased().contains("tomorrow"))
        XCTAssertFalse(parsed.title.lowercased().contains("8pm"))
        XCTAssertEqual(parsed.title.trimmingCharacters(in: .whitespaces), "Study SwiftUI")
        XCTAssertNotNil(parsed.dueDate)
        
        let hour = Calendar.current.component(.hour, from: parsed.dueDate!)
        XCTAssertEqual(hour, 20)
        
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        XCTAssertTrue(Calendar.current.isDate(parsed.dueDate!, inSameDayAs: tomorrow))
    }
    
    func testAllDayFlag() {
        let parsed = parser.parseTask("Team meeting all day Friday")
        XCTAssertTrue(parsed.isAllDay)
        XCTAssertTrue(parsed.title.lowercased().contains("team meeting"))
    }
}

final class ResumeParserTests: XCTestCase {
    func testParsesContactSkillsAndExperience() {
        let sample = """
        Jane Student
        iOS Developer
        jane@university.edu
        +1 555-010-9988
        linkedin.com/in/janestudent

        SUMMARY
        Computer science student focused on mobile apps.

        SKILLS
        Swift, SwiftUI, Python, Git

        WORK EXPERIENCE
        Software Engineer Intern | Acme Labs | Jan 2024 - Present
        Built iOS features for an education product.

        PROJECTS
        GradMate | Personal | Jun 2025 - Aug 2025
        Student productivity app in SwiftUI.

        CERTIFICATIONS
        AWS Cloud Practitioner | Amazon | Mar 2025

        LANGUAGES
        English (Fluent)
        Spanish (Intermediate)
        """
        
        let parsed = ResumeParser.parse(text: sample)
        XCTAssertEqual(parsed.name, "Jane Student")
        XCTAssertEqual(parsed.role, "iOS Developer")
        XCTAssertTrue(parsed.email.contains("jane@university.edu"))
        XCTAssertTrue(parsed.skills.contains("Swift"))
        XCTAssertFalse(parsed.workExperiences.isEmpty)
        XCTAssertEqual(parsed.workExperiences.first?.company, "Acme Labs")
        XCTAssertFalse(parsed.projects.isEmpty)
        XCTAssertFalse(parsed.certifications.isEmpty)
        XCTAssertEqual(parsed.languages.count, 2)
    }
    
    func testDoesNotTreatJobTitleAsNameWhenFallbackProvided() {
        let sample = """
        Head Of Information Security
        Senior iOS Developer
        E-mail:appu.lokeshkumar@gmail.com
        Mobile: +44 7721944933
        http://www.linkedin.com/in/kumbam06
        www.anvilabs.com
        7 Bredon close, Washington, UK

        Professional Summary
        Organized, collaborative, and highly skilled iOS developer with 7 years of experience.

        Skills
        Programming
        Swift
        Tools
        Xcode
        """
        
        let parsed = ResumeParser.parse(text: sample, fallbackName: "Pradeep Reddy Kumbam")
        XCTAssertEqual(parsed.name, "Pradeep Reddy Kumbam")
        XCTAssertFalse(parsed.name.localizedCaseInsensitiveContains("information security"))
        XCTAssertTrue(ResumeParser.looksLikeJobTitle(parsed.role) || parsed.role.lowercased().contains("ios"))
        XCTAssertTrue(parsed.email.contains("appu.lokeshkumar@gmail.com"))
        XCTAssertTrue(parsed.skills.contains("Swift"))
        XCTAssertTrue(parsed.skills.contains("Xcode"))
        XCTAssertFalse(parsed.skills.contains(where: { $0.caseInsensitiveCompare("Programming") == .orderedSame }))
    }
    
    func testLooksLikeJobTitleAndPersonName() {
        XCTAssertTrue(ResumeParser.looksLikeJobTitle("Head Of Information Security"))
        XCTAssertTrue(ResumeParser.looksLikePersonName("Pradeep Reddy Kumbam"))
        XCTAssertFalse(ResumeParser.looksLikePersonName("Head Of Information Security"))
    }
}

final class CareerModelTests: XCTestCase {
    func testWorkExperienceDefaultIdentity() {
        let first = WorkExperience(title: "Intern", company: "Acme")
        let second = WorkExperience(id: first.id, title: "Intern", company: "Acme")
        XCTAssertEqual(first, second)
    }
    
    func testLanguageRoundTrip() throws {
        let language = Language(name: "Spanish", proficiency: .fluent)
        let data = try JSONEncoder().encode([language])
        let decoded = try JSONDecoder().decode([Language].self, from: data)
        XCTAssertEqual(decoded, [language])
    }
}
