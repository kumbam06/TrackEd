//
//  EditProfileView.swift
//  TrackEd
//
//  Created by Pradeep Reddy Kumbam on 23/06/2025.
//

import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var profileManager: ProfileManager
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var role = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var bio = ""
    @State private var linkedin = ""
    @State private var website = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImage: UIImage?
    @State private var username = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        profilePhotoSection
                        basicInfoSection
                        contactInfoSection
                        socialLinksSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("EDIT PROFILE")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("CANCEL") {
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.7))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("SAVE") {
                        saveProfile()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(.accentColor)
                    .disabled(firstName.isEmpty || lastName.isEmpty || role.isEmpty)
                }
            }
            .onAppear {
                loadProfileData()
            }
            .onChange(of: selectedPhoto) {
                Task {
                    if let data = try? await selectedPhoto?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        profileImage = image
                    }
                }
            }
        }
    }
    
    private var profilePhotoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("PROFILE PHOTO")
                .font(.headline)
                .fontWeight(.heavy)
                .foregroundColor(.white)
                .kerning(1)
            
            HStack {
                Spacer()
                
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    if let profileImage = profileImage {
                        Image(uiImage: profileImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .strokeBorder(LinearGradient(colors: [.accentColor, .primary], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 3)
                            )
                            .shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                    } else if let photoData = profileManager.currentProfile?.photoData,
                              let uiImage = UIImage(data: photoData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .strokeBorder(LinearGradient(colors: [.accentColor, .primary], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 3)
                            )
                            .shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                    } else {
                        ZStack {
                            Circle()
                                .fill(Color(.secondarySystemBackground).opacity(0.3))
                                .frame(width: 120, height: 120)
                                .overlay(
                                    Circle()
                                        .stroke(Color.accentColor.opacity(0.2), lineWidth: 1)
                                )
                            
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 80, height: 80)
                                .foregroundColor(.accentColor)
                                .shadow(color: .accentColor, radius: 6, x: 0, y: 0)
                        }
                    }
                }
                
                Spacer()
            }
        }
        .padding(20)
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(.separator), lineWidth: 1))
    }
    
    private var basicInfoSection: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                Text("BASIC INFORMATION")
                    .font(.headline)
                    .fontWeight(.heavy)
                    .foregroundColor(.primary)
                    .kerning(1)
                TextField("USERNAME", text: $username)
                    .autocapitalization(.none)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                HStack(spacing: 12) {
                    TextField("FIRST NAME", text: $firstName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    TextField("LAST NAME", text: $lastName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                TextField("ROLE/TITLE", text: $role)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                TextEditor(text: $bio)
                    .frame(height: 100)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
            }
        }
    }
    
    private var contactInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("CONTACT INFORMATION")
                .font(.headline)
                .fontWeight(.heavy)
                .foregroundColor(.white)
                .kerning(1)
            
            VStack(spacing: 16) {
                TextField("EMAIL", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                
                TextField("PHONE", text: $phone)
                    .keyboardType(.phonePad)
            }
        }
        .padding(20)
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(.separator), lineWidth: 1))
    }
    
    private var socialLinksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("SOCIAL LINKS")
                .font(.headline)
                .fontWeight(.heavy)
                .foregroundColor(.white)
                .kerning(1)
            
            VStack(spacing: 16) {
                TextField("LINKEDIN", text: $linkedin)
                    .autocapitalization(.none)
                
                TextField("WEBSITE", text: $website)
                    .autocapitalization(.none)
            }
        }
        .padding(20)
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(.separator), lineWidth: 1))
    }
    
    private func loadProfileData() {
        guard let profile = profileManager.currentProfile else { return }
        let nameParts = (profile.name ?? "").split(separator: " ", maxSplits: 1).map(String.init)
        firstName = nameParts.first ?? ""
        lastName = nameParts.count > 1 ? nameParts[1] : ""
        role = profile.role ?? ""
        email = profile.email ?? ""
        phone = profile.phone ?? ""
        bio = profile.bio ?? ""
        linkedin = profile.linkedin ?? ""
        website = profile.website ?? ""
        username = profile.username ?? ""
    }
    
    private func saveProfile() {
        guard username.range(of: "^[A-Za-z0-9]{4,}$", options: .regularExpression) != nil else {
            // Show error or alert for invalid username
            return
        }
        let fullName = firstName + (lastName.isEmpty ? "" : " " + lastName)
        profileManager.updateProfile(
            name: fullName,
            role: role,
            email: email,
            phone: phone,
            bio: bio,
            linkedin: linkedin,
            website: website,
            username: username
        )
        
        if let profileImage = profileImage {
            profileManager.updateProfilePhoto(profileImage)
        }
        
        dismiss()
    }
} 