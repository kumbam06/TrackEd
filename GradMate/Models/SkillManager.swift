//
//  SkillManager.swift
//  GradMate
//
//  Created by Pradeep Reddy Kumbam on 23/06/2025.
//

import SwiftUI
import CoreData
import Combine

class SkillManager: ObservableObject {
    @Published var skills: [SkillEntity] = []
    @Published var isLoading = false
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
        loadSkills()
    }
    
    func loadSkills() {
        let request: NSFetchRequest<SkillEntity> = SkillEntity.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \SkillEntity.category, ascending: true),
            NSSortDescriptor(keyPath: \SkillEntity.name, ascending: true)
        ]
        
        do {
            skills = try context.fetch(request)
        } catch {
            print("Error loading skills: \(error)")
        }
    }
    
    func addSkill(name: String, category: String, description: String = "", proficiency: Int16 = 1) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if skills.contains(where: { ($0.name ?? "").caseInsensitiveCompare(trimmed) == .orderedSame }) {
            return
        }
        let skill = SkillEntity(context: context)
        skill.id = UUID()
        skill.name = trimmed
        skill.category = category
        skill.skillDescription = description
        skill.proficiency = proficiency
        
        save()
        loadSkills()
    }
    
    func updateSkill(_ skill: SkillEntity, name: String, category: String, description: String, proficiency: Int16) {
        skill.name = name
        skill.category = category
        skill.skillDescription = description
        skill.proficiency = proficiency
        
        save()
        loadSkills()
    }
    
    func deleteSkill(_ skill: SkillEntity) {
        context.delete(skill)
        save()
        loadSkills()
    }
    
    func getSkillsByCategory(_ category: String) -> [SkillEntity] {
        return skills.filter { $0.category == category }
    }
    
    func getCategories() -> [String] {
        return Array(Set(skills.compactMap { $0.category })).sorted()
    }
    
    private func save() {
        do {
            try context.save()
        } catch {
            print("Error saving skill: \(error)")
        }
    }
} 