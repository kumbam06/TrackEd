import Foundation
import CoreData
import Combine

class CareerDataService: ObservableObject {
    @Published var projects: [ProjectEntity] = []
    @Published var internships: [InternshipEntity] = []
    @Published var certifications: [CertificationEntity] = []
    @Published var workExperiences: [WorkExperienceEntity] = []
    
    // Computed properties for model objects
    var certificationModels: [Certification] {
        certifications.compactMap { entity in
            guard let id = entity.id,
                  let name = entity.name,
                  let issuingOrganization = entity.issuingOrganization,
                  let issueDate = entity.issueDate else {
                return nil
            }
            
            return Certification(
                id: id,
                title: name,
                organization: issuingOrganization,
                location: "", // Not stored in Core Data
                dateReceived: issueDate,
                dateExpiry: entity.expiryDate,
                description: "", // Not stored in Core Data
                credentialID: entity.credentialId
            )
        }
    }
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
        loadAllData()
    }
    
    // MARK: - Projects
    func loadProjects() {
        let request: NSFetchRequest<ProjectEntity> = ProjectEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ProjectEntity.startDate, ascending: false)]
        
        do {
            projects = try context.fetch(request)
        } catch {
            print("Error loading projects: \(error)")
        }
    }
    
    func createProject(_ project: Project) {
        let entity = ProjectEntity(context: context)
        entity.id = project.id
        entity.title = project.title
        entity.projectDescription = project.description
        entity.technologies = project.technologies
        entity.startDate = project.startDate
        entity.endDate = project.endDate
        entity.isCurrent = project.isCurrent
        entity.createdAt = Date()
        entity.updatedAt = Date()
        
        save()
        loadProjects()
    }
    
    func updateProject(_ project: Project) {
        let request: NSFetchRequest<ProjectEntity> = ProjectEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", project.id as CVarArg)
        
        do {
            let results = try context.fetch(request)
            if let entity = results.first {
                entity.title = project.title
                entity.projectDescription = project.description
                entity.technologies = project.technologies
                entity.startDate = project.startDate
                entity.endDate = project.endDate
                entity.isCurrent = project.isCurrent
                entity.updatedAt = Date()
                
                save()
                loadProjects()
            }
        } catch {
            print("Error updating project: \(error)")
        }
    }
    
    func deleteProject(_ project: Project) {
        let request: NSFetchRequest<ProjectEntity> = ProjectEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", project.id as CVarArg)
        
        do {
            let results = try context.fetch(request)
            if let entity = results.first {
                context.delete(entity)
                save()
                loadProjects()
            }
        } catch {
            print("Error deleting project: \(error)")
        }
    }
    
    // MARK: - Internships
    func loadInternships() {
        let request: NSFetchRequest<InternshipEntity> = InternshipEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \InternshipEntity.startDate, ascending: false)]
        
        do {
            internships = try context.fetch(request)
        } catch {
            print("Error loading internships: \(error)")
        }
    }
    
    func createInternship(_ internship: Internship) {
        let entity = InternshipEntity(context: context)
        entity.id = internship.id
        entity.title = internship.title
        entity.company = internship.company
        entity.location = internship.location
        entity.internshipDescription = internship.description
        entity.startDate = internship.startDate
        entity.endDate = internship.endDate
        entity.isCurrent = internship.isCurrent
        entity.technologies = internship.technologies
        entity.createdAt = Date()
        entity.updatedAt = Date()
        
        save()
        loadInternships()
    }
    
    func updateInternship(_ internship: Internship) {
        let request: NSFetchRequest<InternshipEntity> = InternshipEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", internship.id as CVarArg)
        
        do {
            let results = try context.fetch(request)
            if let entity = results.first {
                entity.title = internship.title
                entity.company = internship.company
                entity.location = internship.location
                entity.internshipDescription = internship.description
                entity.startDate = internship.startDate
                entity.endDate = internship.endDate
                entity.isCurrent = internship.isCurrent
                entity.technologies = internship.technologies
                entity.updatedAt = Date()
                
                save()
                loadInternships()
            }
        } catch {
            print("Error updating internship: \(error)")
        }
    }
    
    func deleteInternship(_ internship: Internship) {
        let request: NSFetchRequest<InternshipEntity> = InternshipEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", internship.id as CVarArg)
        
        do {
            let results = try context.fetch(request)
            if let entity = results.first {
                context.delete(entity)
                save()
                loadInternships()
            }
        } catch {
            print("Error deleting internship: \(error)")
        }
    }
    
    // MARK: - Certifications
    func loadCertifications() {
        let request: NSFetchRequest<CertificationEntity> = CertificationEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CertificationEntity.issueDate, ascending: false)]
        
        do {
            certifications = try context.fetch(request)
        } catch {
            print("Error loading certifications: \(error)")
        }
    }
    
    func createCertification(_ certification: Certification) {
        let entity = CertificationEntity(context: context)
        entity.id = certification.id
        entity.name = certification.title
        entity.issuingOrganization = certification.organization
        entity.issueDate = certification.dateReceived
        entity.expiryDate = certification.dateExpiry
        entity.credentialId = certification.credentialID
        entity.createdAt = Date()
        entity.updatedAt = Date()
        
        save()
        loadCertifications()
    }
    
    func updateCertification(_ certification: Certification) {
        let request: NSFetchRequest<CertificationEntity> = CertificationEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", certification.id as CVarArg)
        
        do {
            let results = try context.fetch(request)
            if let entity = results.first {
                entity.name = certification.title
                entity.issuingOrganization = certification.organization
                entity.issueDate = certification.dateReceived
                entity.expiryDate = certification.dateExpiry
                entity.credentialId = certification.credentialID
                entity.updatedAt = Date()
                
                save()
                loadCertifications()
            }
        } catch {
            print("Error updating certification: \(error)")
        }
    }
    
    func deleteCertification(_ certification: Certification) {
        let request: NSFetchRequest<CertificationEntity> = CertificationEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", certification.id as CVarArg)
        
        do {
            let results = try context.fetch(request)
            if let entity = results.first {
                context.delete(entity)
                save()
                loadCertifications()
            }
        } catch {
            print("Error deleting certification: \(error)")
        }
    }
    
    // MARK: - Work Experience
    func loadWorkExperiences() {
        let request: NSFetchRequest<WorkExperienceEntity> = WorkExperienceEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WorkExperienceEntity.startDate, ascending: false)]
        
        do {
            workExperiences = try context.fetch(request)
        } catch {
            print("Error loading work experiences: \(error)")
        }
    }
    
    func createWorkExperience(_ workExperience: WorkExperience) {
        let entity = WorkExperienceEntity(context: context)
        entity.id = workExperience.id
        entity.title = workExperience.title
        entity.company = workExperience.company
        entity.location = workExperience.location
        entity.workDescription = workExperience.description
        entity.startDate = workExperience.startDate
        entity.endDate = workExperience.endDate
        entity.isCurrent = workExperience.isCurrent
        entity.technologies = workExperience.technologies
        entity.createdAt = Date()
        entity.updatedAt = Date()
        
        save()
        loadWorkExperiences()
    }
    
    func updateWorkExperience(_ workExperience: WorkExperience) {
        let request: NSFetchRequest<WorkExperienceEntity> = WorkExperienceEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", workExperience.id as CVarArg)
        
        do {
            let results = try context.fetch(request)
            if let entity = results.first {
                entity.title = workExperience.title
                entity.company = workExperience.company
                entity.location = workExperience.location
                entity.workDescription = workExperience.description
                entity.startDate = workExperience.startDate
                entity.endDate = workExperience.endDate
                entity.isCurrent = workExperience.isCurrent
                entity.technologies = workExperience.technologies
                entity.updatedAt = Date()
                
                save()
                loadWorkExperiences()
            }
        } catch {
            print("Error updating work experience: \(error)")
        }
    }
    
    func deleteWorkExperience(_ workExperience: WorkExperience) {
        let request: NSFetchRequest<WorkExperienceEntity> = WorkExperienceEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", workExperience.id as CVarArg)
        
        do {
            let results = try context.fetch(request)
            if let entity = results.first {
                context.delete(entity)
                save()
                loadWorkExperiences()
            }
        } catch {
            print("Error deleting work experience: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    private func loadAllData() {
        loadProjects()
        loadInternships()
        loadCertifications()
        loadWorkExperiences()
    }
    
    private func save() {
        do {
            try context.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
} 