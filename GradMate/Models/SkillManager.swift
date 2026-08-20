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
        notifyCloudSync()
    }
    
    func updateSkill(_ skill: SkillEntity, name: String, category: String, description: String, proficiency: Int16) {
        skill.name = name
        skill.category = category
        skill.skillDescription = description
        skill.proficiency = proficiency
        
        save()
        loadSkills()
        notifyCloudSync()
    }
    
    func deleteSkill(_ skill: SkillEntity) {
        context.delete(skill)
        save()
        loadSkills()
        notifyCloudSync()
    }
    
    var skillRecords: [SkillRecord] {
        skills.compactMap { entity in
            guard let name = entity.name, !name.isEmpty else { return nil }
            return SkillRecord(
                id: entity.id ?? UUID(),
                name: name,
                category: entity.category ?? "General",
                skillDescription: entity.skillDescription ?? "",
                proficiency: Int(entity.proficiency)
            )
        }
    }
    
    func replaceAll(_ records: [SkillRecord]) {
        skills.forEach { context.delete($0) }
        for record in records where !record.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let skill = SkillEntity(context: context)
            skill.id = record.id
            skill.name = record.name
            skill.category = record.category
            skill.skillDescription = record.skillDescription
            skill.proficiency = Int16(record.proficiency)
        }
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
    
    private func notifyCloudSync() {
        NotificationCenter.default.post(name: .userPortfolioNeedsCloudSync, object: nil)
    }
} 