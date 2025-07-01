import Foundation

protocol NoteServiceProtocol {
    func fetchNotes(completion: @escaping ([NoteEntity]) -> Void)
    func createNote(title: String, content: String, completion: (() -> Void)?)
    func updateNote(_ note: NoteEntity, title: String, content: String, completion: (() -> Void)?)
    func deleteNote(_ note: NoteEntity, completion: (() -> Void)?)
} 