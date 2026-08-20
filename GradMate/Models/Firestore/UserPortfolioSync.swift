import Foundation
import FirebaseAuth
import Combine

extension Notification.Name {
    static let userPortfolioNeedsCloudSync = Notification.Name("userPortfolioNeedsCloudSync")
}

/// Bridges local MVVM stores (Core Data / UserDefaults) with the Firestore user document.
enum UserPortfolioSync {
    private static var pendingPush: DispatchWorkItem?
    
    static func snapshot(
        profileManager: ProfileManager,
        skillManager: SkillManager,
        career: CareerDataService,
        languages: LanguageManager
    ) -> UserPortfolio {
        let profile = profileManager.currentProfile
        return UserPortfolio(
            name: profile?.name ?? "",
            role: profile?.role ?? "",
            email: profile?.email ?? "",
            phone: profile?.phone ?? "",
            bio: profile?.bio ?? "",
            linkedin: profile?.linkedin ?? "",
            website: profile?.website ?? "",
            username: profile?.username ?? "",
            address: profile?.address ?? "",
            currentCompany: profile?.currentCompany ?? "",
            photoURL: nil,
            skills: skillManager.skillRecords,
            workExperiences: career.workExperienceModels,
            projects: career.projectModels,
            internships: career.internshipModels,
            certifications: career.certificationModels,
            languages: languages.languages
        )
    }
    
    static func schedulePush(
        profileManager: ProfileManager,
        skillManager: SkillManager,
        career: CareerDataService,
        languages: LanguageManager
    ) {
        pendingPush?.cancel()
        let work = DispatchWorkItem {
            push(
                profileManager: profileManager,
                skillManager: skillManager,
                career: career,
                languages: languages
            )
        }
        pendingPush = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: work)
    }
    
    static func push(
        profileManager: ProfileManager,
        skillManager: SkillManager,
        career: CareerDataService,
        languages: LanguageManager,
        completion: ((Error?) -> Void)? = nil
    ) {
        guard Auth.auth().currentUser?.uid != nil else {
            completion?(nil)
            return
        }
        let portfolio = snapshot(
            profileManager: profileManager,
            skillManager: skillManager,
            career: career,
            languages: languages
        )
        FirestoreUserDataService.shared.savePortfolio(portfolio, completion: completion)
    }
    
    static func pullAndMerge(
        uid: String,
        profileManager: ProfileManager,
        skillManager: SkillManager,
        career: CareerDataService,
        languages: LanguageManager,
        completion: ((UserPortfolio?) -> Void)? = nil
    ) {
        FirestoreUserDataService.shared.fetchPortfolio(uid: uid) { portfolio in
            DispatchQueue.main.async {
                guard let portfolio else {
                    push(profileManager: profileManager, skillManager: skillManager, career: career, languages: languages)
                    completion?(nil)
                    return
                }
                profileManager.applyCloudProfile(portfolio)
                if !portfolio.skills.isEmpty {
                    skillManager.replaceAll(portfolio.skills)
                }
                let hasCareer = !portfolio.workExperiences.isEmpty
                    || !portfolio.projects.isEmpty
                    || !portfolio.internships.isEmpty
                    || !portfolio.certifications.isEmpty
                if hasCareer {
                    career.replaceAll(
                        workExperiences: portfolio.workExperiences,
                        projects: portfolio.projects,
                        internships: portfolio.internships,
                        certifications: portfolio.certifications
                    )
                }
                if !portfolio.languages.isEmpty {
                    languages.replaceAll(portfolio.languages)
                }
                push(profileManager: profileManager, skillManager: skillManager, career: career, languages: languages)
                completion?(portfolio)
            }
        }
    }
}
