//
//  ProfileManager.swift
//  TrackEd
//
//  Created by Pradeep Reddy Kumbam on 23/06/2025.
//

import SwiftUI
import CoreData
import Combine
import FirebaseFirestore
import FirebaseAuth

class ProfileManager: ObservableObject {
    @Published var currentProfile: Profile?
    @Published var isLoading = false
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
        loadProfile()
    }
    
    func loadProfile() {
        let request: NSFetchRequest<Profile> = Profile.fetchRequest()
        request.fetchLimit = 1
        
        do {
            let profiles = try context.fetch(request)
            if let profile = profiles.first {
                currentProfile = profile
            } else {
                createDefaultProfile()
            }
        } catch {
            print("Error loading profile: \(error)")
            createDefaultProfile()
        }
    }
    
    private func createDefaultProfile() {
        let profile = Profile(context: context)
        profile.id = UUID()
        profile.name = "John Doe"
        profile.role = "iOS Developer"
        profile.email = "john.doe@example.com"
        profile.phone = "+1 (555) 123-4567"
        profile.bio = "Passionate iOS developer with expertise in SwiftUI and Core Data."
        profile.linkedin = "linkedin.com/in/johndoe"
        profile.website = "johndoe.dev"
        
        currentProfile = profile
        save()
    }
    
    func updateProfile(name: String, role: String, email: String, phone: String, bio: String, linkedin: String, website: String, username: String) {
        guard let profile = currentProfile else { return }
        profile.name = name
        profile.role = role
        profile.email = email
        profile.phone = phone
        profile.bio = bio
        profile.linkedin = linkedin
        profile.website = website
        profile.username = username
        save()
        // Firestore sync
        if let userId = Auth.auth().currentUser?.uid {
            let db = Firestore.firestore()
            // Check username uniqueness before updating
            db.collection("users").whereField("username", isEqualTo: username).getDocuments { snapshot, error in
                if let docs = snapshot?.documents, !docs.isEmpty {
                    // If the username is already taken by another user, do not update
                    if !(docs.count == 1 && docs.first?.documentID == userId) {
                        // Optionally show an error to the user
                        print("Username already taken.")
                        return
                    }
                }
                db.collection("users").document(userId).updateData(["username": username])
            }
        }
    }
    
    func updateProfilePhoto(_ image: UIImage) {
        guard let profile = currentProfile else { return }
        profile.photoData = image.jpegData(compressionQuality: 0.8)
        save()
    }
    
    private func save() {
        do {
            try context.save()
        } catch {
            print("Error saving profile: \(error)")
        }
    }
} 