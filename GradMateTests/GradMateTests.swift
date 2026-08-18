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
