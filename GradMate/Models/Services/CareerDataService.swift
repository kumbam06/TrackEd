import Foundation
import CoreData
import Combine

class CareerDataService: ObservableObject {
    @Published var projects: [ProjectEntity] = []
    @Published var internships: [InternshipEntity] = []
    @Published var certifications: [CertificationEntity] = []
    @Published var workExperiences: [WorkExperienceEntity] = []
    
    var certificationModels: [Certification] {
        convertToCertificationModels()
    }
    
    var projectModels: [Project] {
        convertToProjectModels()
    }
    
    var internshipModels: [Internship] {
        convertToInternshipModels()
    }
    
    var workExperienceModels: [WorkExperience] {
        convertToWorkExperienceModels()
    }
    
    var careerCompletionRatio: Double {
        let hasWork = !workExperiences.isEmpty
        let hasProjects = !projects.isEmpty
        let hasInternships = !internships.isEmpty
        let hasCerts = !certifications.isEmpty
        let filled = [hasWork, hasProjects, hasInternships, hasCerts].filter { $0 }.count
        return Double(filled) / 4.0
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
        entity.role = project.role
        entity.company = project.company
        entity.location = project.location
        entity.projectDescription = project.description
        entity.technologies = project.technologies as? NSArray
        entity.startDate = project.startDate
        entity.endDate = project.endDate
        entity.isCurrent = project.isCurrent
        entity.createdAt = Date()
        entity.updatedAt = Date()
        
        save()
        loadProjects()
        notifyCloudSync()
    }
    
    func updateProject(_ project: Project) {
        let request: NSFetchRequest<ProjectEntity> = ProjectEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", project.id as CVarArg)
        
        do {
            let results = try context.fetch(request)
            if let entity = results.first {
                entity.title = project.title
                entity.role = project.role
                entity.company = project.company
                entity.location = project.location
                entity.projectDescription = project.description
                entity.technologies = project.technologies as? NSArray
                entity.startDate = project.startDate
                entity.endDate = project.endDate
                entity.isCurrent = project.isCurrent
                entity.updatedAt = Date()
                
                save()
                loadProjects()
                notifyCloudSync()
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
                notifyCloudSync()
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
        entity.role = internship.role
        entity.company = internship.company
        entity.location = internship.location
        entity.internshipDescription = internship.description
        entity.startDate = internship.startDate
        entity.endDate = internship.endDate
        entity.isCurrent = internship.isCurrent
        entity.technologies = internship.technologies as? NSArray
        entity.createdAt = Date()
        entity.updatedAt = Date()
        
        save()
        loadInternships()
        notifyCloudSync()
    }
    
    func updateInternship(_ internship: Internship) {
        let request: NSFetchRequest<InternshipEntity> = InternshipEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", internship.id as CVarArg)
        
        do {
            let results = try context.fetch(request)
            if let entity = results.first {
                entity.title = internship.title
                entity.role = internship.role
                entity.company = internship.company
                entity.location = internship.location
                entity.internshipDescription = internship.description
                entity.startDate = internship.startDate
                entity.endDate = internship.endDate
                entity.isCurrent = internship.isCurrent
                entity.technologies = internship.technologies as? NSArray
                entity.updatedAt = Date()
                
                save()
                loadInternships()
                notifyCloudSync()
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
                notifyCloudSync()
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
        entity.location = certification.location
        entity.certDescription = certification.description
        entity.issueDate = certification.dateReceived
        entity.expiryDate = certification.dateExpiry
        entity.credentialId = certification.credentialID
        entity.createdAt = Date()
        entity.updatedAt = Date()
        
        save()
        loadCertifications()
        notifyCloudSync()
    }
    
    func updateCertification(_ certification: Certification) {
        let request: NSFetchRequest<CertificationEntity> = CertificationEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", certification.id as CVarArg)
        
        do {
            let results = try context.fetch(request)
            if let entity = results.first {
                entity.name = certification.title
                entity.issuingOrganization = certification.organization
                entity.location = certification.location
                entity.certDescription = certification.description
                entity.issueDate = certification.dateReceived
                entity.expiryDate = certification.dateExpiry
                entity.credentialId = certification.credentialID
                entity.updatedAt = Date()
                
                save()
                loadCertifications()
                notifyCloudSync()
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
                notifyCloudSync()
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
        entity.technologies = workExperience.technologies as? NSArray
        entity.createdAt = Date()
        entity.updatedAt = Date()
        
        save()
        loadWorkExperiences()
        notifyCloudSync()
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
                entity.technologies = workExperience.technologies as? NSArray
                entity.updatedAt = Date()
                
                save()
                loadWorkExperiences()
                notifyCloudSync()
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
                notifyCloudSync()
            }
        } catch {
            print("Error deleting work experience: \(error)")
        }
    }
    
    func reload() {
        loadAllData()
        objectWillChange.send()
    }
    
    // MARK: - Helper Methods
    func loadAllData() {
        loadProjects()
        loadInternships()
        loadCertifications()
        loadWorkExperiences()
    }
    
    func importResume(_ parsed: ParsedResume) {
        for experience in parsed.workExperiences {
            if !workExperienceModels.contains(where: { $0.title.caseInsensitiveCompare(experience.title) == .orderedSame && $0.company.caseInsensitiveCompare(experience.company) == .orderedSame }) {
                createWorkExperience(experience)
            }
        }
        for project in parsed.projects {
            if !projectModels.contains(where: { $0.title.caseInsensitiveCompare(project.title) == .orderedSame }) {
                createProject(project)
            }
        }
        for internship in parsed.internships {
            if !internshipModels.contains(where: { $0.title.caseInsensitiveCompare(internship.title) == .orderedSame && $0.company.caseInsensitiveCompare(internship.company) == .orderedSame }) {
                createInternship(internship)
            }
        }
        for certification in parsed.certifications {
            if !certificationModels.contains(where: { $0.title.caseInsensitiveCompare(certification.title) == .orderedSame }) {
                createCertification(certification)
            }
        }
        notifyCloudSync()
    }
    
    func replaceAll(
        workExperiences: [WorkExperience],
        projects: [Project],
        internships: [Internship],
        certifications: [Certification]
    ) {
        deleteAll(ProjectEntity.fetchRequest())
        deleteAll(InternshipEntity.fetchRequest())
        deleteAll(CertificationEntity.fetchRequest())
        deleteAll(WorkExperienceEntity.fetchRequest())
        save()
        for item in projects { insertProject(item) }
        for item in internships { insertInternship(item) }
        for item in certifications { insertCertification(item) }
        for item in workExperiences { insertWorkExperience(item) }
        save()
        loadAllData()
        objectWillChange.send()
    }
    
    private func deleteAll<T: NSManagedObject>(_ request: NSFetchRequest<T>) {
        (try? context.fetch(request))?.forEach { context.delete($0) }
    }
    
    private func insertProject(_ project: Project) {
        let entity = ProjectEntity(context: context)
        entity.id = project.id
        entity.title = project.title
        entity.role = project.role
        entity.company = project.company
        entity.location = project.location
        entity.projectDescription = project.description
        entity.technologies = project.technologies as? NSArray
        entity.startDate = project.startDate
        entity.endDate = project.endDate
        entity.isCurrent = project.isCurrent
        entity.createdAt = Date()
        entity.updatedAt = Date()
    }
    
    private func insertInternship(_ internship: Internship) {
        let entity = InternshipEntity(context: context)
        entity.id = internship.id
        entity.title = internship.title
        entity.role = internship.role
        entity.company = internship.company
        entity.location = internship.location
        entity.internshipDescription = internship.description
        entity.startDate = internship.startDate
        entity.endDate = internship.endDate
        entity.isCurrent = internship.isCurrent
        entity.technologies = internship.technologies as? NSArray
        entity.createdAt = Date()
        entity.updatedAt = Date()
    }
    
    private func insertCertification(_ certification: Certification) {
        let entity = CertificationEntity(context: context)
        entity.id = certification.id
        entity.name = certification.title
        entity.issuingOrganization = certification.organization
        entity.location = certification.location
        entity.certDescription = certification.description
        entity.issueDate = certification.dateReceived
        entity.expiryDate = certification.dateExpiry
        entity.credentialId = certification.credentialID
        entity.createdAt = Date()
        entity.updatedAt = Date()
    }
    
    private func insertWorkExperience(_ workExperience: WorkExperience) {
        let entity = WorkExperienceEntity(context: context)
        entity.id = workExperience.id
        entity.title = workExperience.title
        entity.company = workExperience.company
        entity.location = workExperience.location
        entity.workDescription = workExperience.description
        entity.startDate = workExperience.startDate
        entity.endDate = workExperience.endDate
        entity.isCurrent = workExperience.isCurrent
        entity.technologies = workExperience.technologies as? NSArray
        entity.createdAt = Date()
        entity.updatedAt = Date()
    }
    
    private func save() {
        do {
            try context.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
    
    private func notifyCloudSync() {
        NotificationCenter.default.post(name: .userPortfolioNeedsCloudSync, object: nil)
    }
    
    // MARK: - Conversion Methods
    func convertToWorkExperienceModels() -> [WorkExperience] {
        return workExperiences.compactMap { entity in
            let identifier = entity.id ?? UUID()
            if entity.id == nil { entity.id = identifier }
            return WorkExperience(
                id: identifier,
                title: entity.title ?? "",
                company: entity.company ?? "",
                location: entity.location ?? "",
                startDate: entity.startDate ?? Date(),
                endDate: entity.endDate,
                isCurrent: entity.isCurrent,
                description: entity.workDescription ?? "",
                technologies: entity.technologies as? [String]
            )
        }
    }
    
    func convertToProjectModels() -> [Project] {
        return projects.compactMap { entity in
            let identifier = entity.id ?? UUID()
            if entity.id == nil { entity.id = identifier }
            return Project(
                id: identifier,
                title: entity.title ?? "",
                role: entity.role ?? "",
                company: entity.company ?? "",
                location: entity.location ?? "",
                startDate: entity.startDate ?? Date(),
                endDate: entity.endDate,
                isCurrent: entity.isCurrent,
                description: entity.projectDescription ?? "",
                technologies: entity.technologies as? [String]
            )
        }
    }
    
    func convertToInternshipModels() -> [Internship] {
        return internships.compactMap { entity in
            let identifier = entity.id ?? UUID()
            if entity.id == nil { entity.id = identifier }
            return Internship(
                id: identifier,
                title: entity.title ?? "",
                role: entity.role ?? "",
                company: entity.company ?? "",
                location: entity.location ?? "",
                startDate: entity.startDate ?? Date(),
                endDate: entity.endDate,
                isCurrent: entity.isCurrent,
                description: entity.internshipDescription ?? "",
                technologies: entity.technologies as? [String]
            )
        }
    }
    
    func convertToCertificationModels() -> [Certification] {
        return certifications.compactMap { entity in
            let identifier = entity.id ?? UUID()
            if entity.id == nil { entity.id = identifier }
            return Certification(
                id: identifier,
                title: entity.name ?? "",
                organization: entity.issuingOrganization ?? "",
                location: entity.location ?? "",
                dateReceived: entity.issueDate ?? Date(),
                dateExpiry: entity.expiryDate,
                description: entity.certDescription ?? "",
                credentialID: entity.credentialId
            )
        }
    }
} 