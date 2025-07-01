import Foundation
import CoreData
import Combine

class NoteService: NoteServiceProtocol, ObservableObject {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
    }
    
    func fetchNotes(completion: @escaping ([NoteEntity]) -> Void) {
        let request: NSFetchRequest<NoteEntity> = NoteEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \NoteEntity.updatedAt, ascending: false)]
        do {
            let notes = try context.fetch(request)
            completion(notes)
        } catch {
            print("Error loading notes: \(error)")
            completion([])
        }
    }
    
    func createNote(title: String, content: String, completion: (() -> Void)?) {
        let note = NoteEntity(context: context)
        note.id = UUID()
        note.title = title
        note.content = content
        note.createdAt = Date()
        note.updatedAt = Date()
        save()
        completion?()
    }
    
    func updateNote(_ note: NoteEntity, title: String, content: String, completion: (() -> Void)?) {
        note.title = title
        note.content = content
        note.updatedAt = Date()
        save()
        completion?()
    }
    
    func deleteNote(_ note: NoteEntity, completion: (() -> Void)?) {
        context.delete(note)
        save()
        completion?()
    }
    
    private func save() {
        do {
            try context.save()
        } catch {
            print("Error saving note: \(error)")
        }
    }
} 