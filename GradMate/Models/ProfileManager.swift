//
//  ProfileManager.swift
//  GradMate
//
//  Created by Pradeep Reddy Kumbam on 23/06/2025.
//

import SwiftUI
import CoreData
import Combine
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

class ProfileManager: ObservableObject {
    @Published var currentProfile: Profile?
    @Published var isLoading = false
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
        Task {
            await loadProfileAsync()
        }
    }
    
    @MainActor
    func loadProfileAsync() async {
        isLoading = true
        let request: NSFetchRequest<Profile> = Profile.fetchRequest()
        request.fetchLimit = 1
        do {
            let profiles = try await context.perform {
                try request.execute()
            }
            if let profile = profiles.first {
                currentProfile = profile
            } else {
                createDefaultProfile()
            }
        } catch {
            print("Error loading profile: \(error)")
            createDefaultProfile()
        }
        isLoading = false
    }
    
    func loadProfile() {
        Task { await loadProfileAsync() }
    }
    
    private func createDefaultProfile() {
        currentProfile = nil
    }
    
    func updateProfile(name: String, role: String, email: String, phone: String, bio: String, linkedin: String, website: String, username: String, dob: Date?, address: String, currentCompany: String) {
        guard let profile = currentProfile else { return }
        profile.name = name
        profile.role = role
        profile.email = email
        profile.phone = phone
        profile.bio = bio
        profile.linkedin = linkedin
        profile.website = website
        profile.username = username
        profile.dob = dob
        profile.address = address
        profile.currentCompany = currentCompany
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
                var userData: [String: Any] = [
                    "name": name,
                    "role": role,
                    "email": email,
                    "phone": phone,
                    "bio": bio,
                    "linkedin": linkedin,
                    "website": website,
                    "username": username,
                    "address": address,
                    "currentCompany": currentCompany
                ]
                if let dob = dob {
                    userData["dob"] = Timestamp(date: dob)
                }
                db.collection("users").document(userId).setData(userData, merge: true)
            }
        }
    }
    
    func updateProfilePhoto(_ image: UIImage) {
        guard let profile = currentProfile else { return }
        profile.photoData = image.jpegData(compressionQuality: 0.8)
        save()
        // Upload to Firebase Storage and update Firestore
        if let userId = Auth.auth().currentUser?.uid, let imageData = image.jpegData(compressionQuality: 0.8) {
            print("[DEBUG] Starting upload to Firebase Storage for userId: \(userId)")
            let storageRef = Storage.storage().reference().child("profile_photos/\(userId)")
            storageRef.putData(imageData, metadata: nil) { metadata, error in
                if let error = error {
                    print("[DEBUG] Failed to upload profile photo: \(error.localizedDescription)")
                    return
                }
                print("[DEBUG] Profile photo uploaded successfully. Getting download URL...")
                storageRef.downloadURL { url, error in
                    if let error = error {
                        print("[DEBUG] Failed to get download URL: \(error.localizedDescription)")
                        return
                    }
                    guard let url = url else {
                        print("[DEBUG] Download URL is nil")
                        return
                    }
                    print("[DEBUG] Got download URL: \(url.absoluteString)")
                    let db = Firestore.firestore()
                    db.collection("users").document(userId).setData(["photoURL": url.absoluteString], merge: true) { error in
                        if let error = error {
                            print("[DEBUG] Failed to update Firestore with photoURL: \(error.localizedDescription)")
                        } else {
                            print("[DEBUG] photoURL successfully saved to Firestore.")
                        }
                    }
                }
            }
        } else {
            print("[DEBUG] Could not get userId or imageData for profile photo upload.")
        }
    }
    
    private func save() {
        do {
            try context.save()
        } catch {
            print("Error saving profile: \(error)")
        }
    }
    
    func loadProfileFromFirestore(uid: String, completion: ((Profile?) -> Void)? = nil) {
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { [weak self] doc, error in
            guard let self = self else {
                completion?(nil)
                return
            }
            
            if let error = error {
                print("Error loading profile from Firestore: \(error)")
                completion?(nil)
                return
            }
            
            guard let data = doc?.data() else {
                // No profile found in Firestore
                completion?(nil)
                return
            }
            
            // Update or create local Core Data profile
            let request: NSFetchRequest<Profile> = Profile.fetchRequest()
            request.fetchLimit = 1
            let profile: Profile
            if let existing = try? self.context.fetch(request).first {
                profile = existing
            } else {
                profile = Profile(context: self.context)
                profile.id = UUID()
            }
            
            profile.name = data["name"] as? String ?? ""
            profile.role = data["role"] as? String ?? ""
            profile.email = data["email"] as? String ?? ""
            profile.phone = data["phone"] as? String ?? ""
            profile.bio = data["bio"] as? String ?? ""
            profile.linkedin = data["linkedin"] as? String ?? ""
            profile.website = data["website"] as? String ?? ""
            profile.username = data["username"] as? String ?? ""
            profile.address = data["address"] as? String ?? ""
            profile.currentCompany = data["currentCompany"] as? String ?? ""
            
            if let dobTimestamp = data["dob"] as? Timestamp {
                profile.dob = dobTimestamp.dateValue()
            } else {
                profile.dob = nil
            }
            
            if let photoURL = data["photoURL"] as? String, let url = URL(string: photoURL) {
                // Download the image data
                URLSession.shared.dataTask(with: url) { data, response, error in
                    if let data = data {
                        DispatchQueue.main.async {
                            profile.photoData = data
                            self.currentProfile = profile
                            self.save()
                            completion?(profile)
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.currentProfile = profile
                            self.save()
                            completion?(profile)
                        }
                    }
                }.resume()
            } else {
                self.currentProfile = profile
                self.save()
                completion?(profile)
            }
        }
    }

    func clearLocalProfile() {
        let request: NSFetchRequest<Profile> = Profile.fetchRequest()
        if let profiles = try? context.fetch(request) {
            for profile in profiles {
                context.delete(profile)
            }
            save()
            currentProfile = nil
        }
    }

    /// Loads profile from local Core Data if available, otherwise fetches from Firestore. Use for optimized loading.
    func loadProfileIfNeededOrRefresh(forceRefresh: Bool = false) {
        let request: NSFetchRequest<Profile> = Profile.fetchRequest()
        request.fetchLimit = 1
        let hasLocalProfile: Bool
        if let profiles = try? context.fetch(request), let profile = profiles.first {
            hasLocalProfile = true
            currentProfile = profile
        } else {
            hasLocalProfile = false
        }
        // Only fetch from Firestore if no local profile or forceRefresh is true
        if !hasLocalProfile || forceRefresh {
            if let uid = Auth.auth().currentUser?.uid {
                loadProfileFromFirestore(uid: uid) { _ in
                    // Profile loaded, no additional action needed
                }
            }
        }
    }
} 
