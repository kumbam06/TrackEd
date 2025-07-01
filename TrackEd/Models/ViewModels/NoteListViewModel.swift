import Foundation
import Combine

class NoteListViewModel: ObservableObject {
    @Published var notes: [NoteEntity] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let noteService: NoteServiceProtocol
    
    init(noteService: NoteServiceProtocol) {
        self.noteService = noteService
        loadNotes()
    }
    
    func loadNotes() {
        isLoading = true
        noteService.fetchNotes { [weak self] notes in
            DispatchQueue.main.async {
                self?.notes = notes
                self?.isLoading = false
            }
        }
    }
    
    func addNote(title: String, content: String) {
        noteService.createNote(title: title, content: content) { [weak self] in
            self?.loadNotes()
        }
    }
    
    func updateNote(_ note: NoteEntity, title: String, content: String) {
        noteService.updateNote(note, title: title, content: content) { [weak self] in
            self?.loadNotes()
        }
    }
    
    func deleteNote(_ note: NoteEntity) {
        noteService.deleteNote(note) { [weak self] in
            self?.loadNotes()
        }
    }
} 