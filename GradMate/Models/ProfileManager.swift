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
    
    @discardableResult
    func ensureProfile() -> Profile {
        if let currentProfile { return currentProfile }
        let profile = Profile(context: context)
        profile.id = UUID()
        currentProfile = profile
        save()
        return profile
    }
    
    func applyImportedProfile(
        name: String,
        role: String,
        email: String,
        phone: String,
        bio: String,
        linkedin: String,
        website: String,
        address: String
    ) {
        let existing = currentProfile
        let authName = Auth.auth().currentUser?.displayName ?? ""
        var resolvedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        var resolvedRole = role.trimmingCharacters(in: .whitespacesAndNewlines)
        if ResumeParser.looksLikeJobTitle(resolvedName) && !ResumeParser.looksLikePersonName(resolvedName) {
            if resolvedRole.isEmpty { resolvedRole = resolvedName }
            resolvedName = ""
        }
        if resolvedName.isEmpty {
            let existingName = existing?.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            resolvedName = existingName.isEmpty ? authName : existingName
        }
        updateProfile(
            name: resolvedName,
            role: resolvedRole.isEmpty ? (existing?.role ?? "") : resolvedRole,
            email: email.isEmpty ? (existing?.email ?? "") : email,
            phone: phone.isEmpty ? (existing?.phone ?? "") : phone,
            bio: bio.isEmpty ? (existing?.bio ?? "") : bio,
            linkedin: linkedin.isEmpty ? (existing?.linkedin ?? "") : linkedin,
            website: website.isEmpty ? (existing?.website ?? "") : website,
            username: existing?.username ?? "",
            dob: existing?.dob,
            address: address.isEmpty ? (existing?.address ?? "") : address,
            currentCompany: existing?.currentCompany ?? ""
        )
    }
    
    func applyCloudProfile(_ portfolio: UserPortfolio) {
        let profile = ensureProfile()
        if !portfolio.name.isEmpty {
            if ResumeParser.looksLikeJobTitle(portfolio.name) && !ResumeParser.looksLikePersonName(portfolio.name) {
                if (profile.role ?? "").isEmpty && portfolio.role.isEmpty {
                    profile.role = portfolio.name
                }
            } else {
                profile.name = portfolio.name
            }
        }
        if !portfolio.role.isEmpty { profile.role = portfolio.role }
        if !portfolio.email.isEmpty { profile.email = portfolio.email }
        if !portfolio.phone.isEmpty { profile.phone = portfolio.phone }
        if !portfolio.bio.isEmpty { profile.bio = portfolio.bio }
        if !portfolio.linkedin.isEmpty { profile.linkedin = portfolio.linkedin }
        if !portfolio.website.isEmpty { profile.website = portfolio.website }
        if !portfolio.username.isEmpty { profile.username = portfolio.username }
        if !portfolio.address.isEmpty { profile.address = portfolio.address }
        if !portfolio.currentCompany.isEmpty { profile.currentCompany = portfolio.currentCompany }
        save()
        publish(profile)
        if let photoURL = portfolio.photoURL, let url = URL(string: photoURL) {
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                guard let self, let data else { return }
                DispatchQueue.main.async {
                    profile.photoData = data
                    self.save()
                    self.publish(profile)
                }
            }.resume()
        }
    }
    
    func updateProfile(name: String, role: String, email: String, phone: String, bio: String, linkedin: String, website: String, username: String, dob: Date?, address: String, currentCompany: String) {
        let profile = ensureProfile()
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
        publish(profile)
        persistProfileToFirestore(
            name: name,
            role: role,
            email: email,
            phone: phone,
            bio: bio,
            linkedin: linkedin,
            website: website,
            username: username,
            dob: dob,
            address: address,
            currentCompany: currentCompany
        )
    }
    
    private func publish(_ profile: Profile) {
        let apply = {
            self.objectWillChange.send()
            self.currentProfile = profile
        }
        if Thread.isMainThread {
            apply()
        } else {
            DispatchQueue.main.async(execute: apply)
        }
    }
    
    private func persistProfileToFirestore(
        name: String,
        role: String,
        email: String,
        phone: String,
        bio: String,
        linkedin: String,
        website: String,
        username: String,
        dob: Date?,
        address: String,
        currentCompany: String
    ) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let write: () -> Void = {
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
            if let dob {
                userData["dob"] = Timestamp(date: dob)
            }
            db.collection("users").document(userId).setData(userData, merge: true)
        }
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedUsername.isEmpty else {
            write()
            return
        }
        db.collection("users").whereField("username", isEqualTo: trimmedUsername).getDocuments { snapshot, _ in
            if let docs = snapshot?.documents, !docs.isEmpty {
                if !(docs.count == 1 && docs.first?.documentID == userId) {
                    print("Username already taken.")
                    write()
                    return
                }
            }
            write()
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
        FirestoreUserDataService.shared.fetchPortfolio(uid: uid) { [weak self] portfolio in
            guard let self else {
                completion?(nil)
                return
            }
            guard let portfolio else {
                completion?(nil)
                return
            }
            self.applyCloudProfile(portfolio)
            completion?(self.currentProfile)
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
