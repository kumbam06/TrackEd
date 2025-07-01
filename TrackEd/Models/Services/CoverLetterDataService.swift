import Foundation
import CoreData
import Combine

class CoverLetterDataService: ObservableObject {
    @Published var coverLetters: [CoverLetterEntity] = []
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
        loadCoverLetters()
    }
    
    func loadCoverLetters() {
        let request: NSFetchRequest<CoverLetterEntity> = CoverLetterEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CoverLetterEntity.updatedAt, ascending: false)]
        
        do {
            coverLetters = try context.fetch(request)
        } catch {
            print("Error loading cover letters: \(error)")
        }
    }
    
    func createCoverLetter(_ coverLetter: CoverLetter) {
        let entity = CoverLetterEntity(context: context)
        entity.id = coverLetter.id
        entity.name = coverLetter.name
        entity.template = coverLetter.template
        entity.companyName = coverLetter.companyName
        entity.positionTitle = coverLetter.positionTitle
        entity.hiringManagerName = coverLetter.hiringManagerName
        entity.companyAddress = coverLetter.companyAddress
        entity.openingParagraph = coverLetter.openingParagraph
        entity.bodyParagraphs = coverLetter.bodyParagraphs
        entity.closingParagraph = coverLetter.closingParagraph
        entity.createdAt = Date()
        entity.updatedAt = Date()
        
        save()
        loadCoverLetters()
    }
    
    func updateCoverLetter(_ coverLetter: CoverLetter) {
        let request: NSFetchRequest<CoverLetterEntity> = CoverLetterEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", coverLetter.id as CVarArg)
        
        do {
            let results = try context.fetch(request)
            if let entity = results.first {
                entity.name = coverLetter.name
                entity.template = coverLetter.template
                entity.companyName = coverLetter.companyName
                entity.positionTitle = coverLetter.positionTitle
                entity.hiringManagerName = coverLetter.hiringManagerName
                entity.companyAddress = coverLetter.companyAddress
                entity.openingParagraph = coverLetter.openingParagraph
                entity.bodyParagraphs = coverLetter.bodyParagraphs
                entity.closingParagraph = coverLetter.closingParagraph
                entity.updatedAt = Date()
                
                save()
                loadCoverLetters()
            }
        } catch {
            print("Error updating cover letter: \(error)")
        }
    }
    
    func deleteCoverLetter(_ coverLetter: CoverLetter) {
        let request: NSFetchRequest<CoverLetterEntity> = CoverLetterEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", coverLetter.id as CVarArg)
        
        do {
            let results = try context.fetch(request)
            if let entity = results.first {
                context.delete(entity)
                save()
                loadCoverLetters()
            }
        } catch {
            print("Error deleting cover letter: \(error)")
        }
    }
    
    func getCoverLetter(by id: UUID) -> CoverLetterEntity? {
        let request: NSFetchRequest<CoverLetterEntity> = CoverLetterEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            let results = try context.fetch(request)
            return results.first
        } catch {
            print("Error fetching cover letter: \(error)")
            return nil
        }
    }
    
    private func save() {
        do {
            try context.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
}

// MARK: - Cover Letter Model
struct CoverLetter: Identifiable, Codable {
    let id: UUID
    var name: String
    var template: String
    var companyName: String
    var positionTitle: String
    var hiringManagerName: String
    var companyAddress: String
    var openingParagraph: String
    var bodyParagraphs: [String]
    var closingParagraph: String
    
    init(
        id: UUID = UUID(),
        name: String = "",
        template: String = "standard",
        companyName: String = "",
        positionTitle: String = "",
        hiringManagerName: String = "",
        companyAddress: String = "",
        openingParagraph: String = "",
        bodyParagraphs: [String] = [""],
        closingParagraph: String = ""
    ) {
        self.id = id
        self.name = name
        self.template = template
        self.companyName = companyName
        self.positionTitle = positionTitle
        self.hiringManagerName = hiringManagerName
        self.companyAddress = companyAddress
        self.openingParagraph = openingParagraph
        self.bodyParagraphs = bodyParagraphs
        self.closingParagraph = closingParagraph
    }
} 