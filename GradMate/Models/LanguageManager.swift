import Foundation
import Combine

final class LanguageManager: ObservableObject {
    @Published var languages: [Language] = []
    
    private let storageKey = "userLanguages"
    
    init() {
        load()
    }
    
    func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([Language].self, from: data) else {
            languages = []
            return
        }
        languages = decoded
    }
    
    func save(_ items: [Language]) {
        languages = items
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
        NotificationCenter.default.post(name: .userPortfolioNeedsCloudSync, object: nil)
    }
    
    func replaceAll(_ items: [Language]) {
        languages = items
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
        objectWillChange.send()
    }
    
    func upsert(_ language: Language) {
        if let index = languages.firstIndex(where: { $0.id == language.id }) {
            languages[index] = language
        } else {
            languages.append(language)
        }
        save(languages)
    }
    
    func delete(_ language: Language) {
        languages.removeAll { $0.id == language.id }
        save(languages)
    }
}
