//
//  EditProfileView.swift
//  GradMate
//
//  Created by Pradeep Reddy Kumbam on 23/06/2025.
//

import SwiftUI
import PhotosUI
import Firebase
import FirebaseAuth
import SDWebImageSwiftUI

@available(iOS 16.0, *)
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
    @State private var dob: Date = Date()
    @State private var address: String = ""
    @State private var currentCompany = ""
    @State private var debouncedUsername = ""
    @State private var debouncedFirstName = ""
    @State private var debouncedLastName = ""
    @State private var debouncedRole = ""
    @State private var debouncedBio = ""
    @State private var debouncedEmail = ""
    @State private var debouncedPhone = ""
    @State private var debouncedLinkedin = ""
    @State private var debouncedWebsite = ""
    @State private var debouncedAddress = ""
    @State private var debouncedCurrentCompany = ""
    @State private var debounceWorkItem: DispatchWorkItem? = nil
    private let debounceDelay = 0.25
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("appScreenBG").ignoresSafeArea()
                
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
                    .foregroundColor(Color("appTextSecondary"))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("SAVE") {
                        saveProfile()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(Color("appPrimaryAccent"))
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
                .foregroundColor(Color("appTextPrimary"))
                .kerning(1)
            HStack {
                Spacer()
                ZStack(alignment: .topTrailing) {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        if let profileImage = profileImage {
                            Image(uiImage: profileImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 160, height: 160)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .strokeBorder(LinearGradient(colors: [Color("appPrimaryAccent"), Color("appPrimaryAccent").opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 3)
                                )
                                .shadow(color: Color("appPrimaryAccent").opacity(0.3), radius: 8, x: 0, y: 4)
                        } else if let photoData = profileManager.currentProfile?.photoData,
                                  let uiImage = UIImage(data: photoData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 160, height: 160)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .strokeBorder(LinearGradient(colors: [Color("appPrimaryAccent"), Color("appPrimaryAccent").opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 3)
                                )
                                .shadow(color: Color("appPrimaryAccent").opacity(0.3), radius: 8, x: 0, y: 4)
                        } else {
                            ZStack {
                                Circle()
                                    .fill(Color("appStrokeGray").opacity(0.3))
                                    .frame(width: 160, height: 160)
                                    .overlay(
                                        Circle()
                                            .stroke(Color("appPrimaryAccent").opacity(0.2), lineWidth: 1)
                                    )
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 100, height: 100)
                                    .foregroundColor(Color("appPrimaryAccent"))
                                    .shadow(color: Color("appPrimaryAccent"), radius: 6, x: 0, y: 0)
                            }
                        }
                    }
                    Button(action: {
                        // Trigger PhotosPicker
                        selectedPhoto = nil // This will allow re-picking the same image
                    }) {
                        Image(systemName: "pencil.circle.fill")
                            .resizable()
                            .frame(width: 36, height: 36)
                            .foregroundColor(Color("appPrimaryAccent"))
                            .background(Color("appCardBG").opacity(0.9))
                            .clipShape(Circle())
                            .shadow(radius: 4)
                            .padding(6)
                    }
                    .offset(x: 12, y: -12)
                }
                Spacer()
            }
        }
        .padding(20)
        .background(Color("appCardBG"))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color("appStrokeGray"), lineWidth: 1))
    }
    
    private var basicInfoSection: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                Text("BASIC INFORMATION")
                    .font(.headline)
                    .fontWeight(.heavy)
                    .foregroundColor(Color("appTextPrimary"))
                    .kerning(1)
                CustomTextField(title: "Username", text: $username, placeholder: "Enter your username")
                    .onChange(of: username) { newValue, _ in debounceInput(newValue, for: "username") }
                HStack(spacing: 12) {
                    CustomTextField(title: "First Name", text: $firstName, placeholder: "Enter your first name")
                        .onChange(of: firstName) { newValue, _ in debounceInput(newValue, for: "firstName") }
                    CustomTextField(title: "Last Name", text: $lastName, placeholder: "Enter your last name")
                        .onChange(of: lastName) { newValue, _ in debounceInput(newValue, for: "lastName") }
                }
                CustomTextField(title: "Role/Title", text: $role, placeholder: "e.g., iOS Developer, Student")
                    .onChange(of: role) { newValue, _ in debounceInput(newValue, for: "role") }
                CustomTextField(title: "Current Company/Institution", text: $currentCompany, placeholder: "e.g., Acme Corp, University of X")
                    .onChange(of: currentCompany) { newValue, _ in debounceInput(newValue, for: "currentCompany") }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bio")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color("appTextPrimary"))
                    TextEditor(text: $bio)
                        .frame(height: 100)
                        .padding(12)
                        .background(Color("appStrokeGray"))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color("appStrokeGray"), lineWidth: 1)
                        )
                        .onChange(of: bio) { newValue, _ in debounceInput(newValue, for: "bio") }
                }
                DatePicker("Date of Birth", selection: $dob, displayedComponents: .date)
                    .datePickerStyle(CompactDatePickerStyle())
                CustomTextField(title: "Address", text: $address, placeholder: "Enter your address")
                    .onChange(of: address) { newValue, _ in debounceInput(newValue, for: "address") }
            }
        }
    }
    
    private var contactInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("CONTACT INFORMATION")
                .font(.headline)
                .fontWeight(.heavy)
                .foregroundColor(Color("appTextPrimary"))
                .kerning(1)
            
            VStack(spacing: 12) {
                CustomTextField(title: "Email", text: $email, placeholder: "Enter your email address")
                    .onChange(of: email) { newValue, _ in debounceInput(newValue, for: "email") }
                
                CustomTextField(title: "Phone", text: $phone, placeholder: "Enter your phone number")
                    .onChange(of: phone) { newValue, _ in debounceInput(newValue, for: "phone") }
            }
        }
        .padding(20)
        .background(Color("appCardBG"))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color("appStrokeGray"), lineWidth: 1))
    }
    
    private var socialLinksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("SOCIAL LINKS")
                .font(.headline)
                .fontWeight(.heavy)
                .foregroundColor(Color("appTextPrimary"))
                .kerning(1)
            
            VStack(spacing: 12) {
                CustomTextField(title: "LinkedIn", text: $linkedin, placeholder: "linkedin.com/in/yourprofile")
                    .onChange(of: linkedin) { newValue, _ in debounceInput(newValue, for: "linkedin") }
                
                CustomTextField(title: "Website", text: $website, placeholder: "yourwebsite.com")
                    .onChange(of: website) { newValue, _ in debounceInput(newValue, for: "website") }
            }
        }
        .padding(20)
        .background(Color("appCardBG"))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color("appStrokeGray"), lineWidth: 1))
    }
    
    private func loadProfileData() {
        guard let profile = profileManager.currentProfile else { return }
        
        // Split the name into first and last name
        let nameComponents = (profile.name ?? "").components(separatedBy: " ")
        firstName = nameComponents.first ?? ""
        lastName = nameComponents.dropFirst().joined(separator: " ")
        
        role = profile.role ?? ""
        email = profile.email ?? ""
        phone = profile.phone ?? ""
        bio = profile.bio ?? ""
        linkedin = profile.linkedin ?? ""
        website = profile.website ?? ""
        username = profile.username ?? ""
        address = profile.address ?? ""
        currentCompany = profile.currentCompany ?? ""
        
        if let dobData = profile.dob {
            dob = dobData
        }
    }
    
    private func saveProfile() {
        let fullName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
        profileManager.updateProfile(
            name: fullName,
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
        
        // Update profile photo if selected
        if let profileImage = profileImage {
            profileManager.updateProfilePhoto(profileImage)
        }
        
        dismiss()
    }
    
    private func debounceInput(_ value: String, for field: String) {
        debounceWorkItem?.cancel()
        let workItem = DispatchWorkItem { [value] in
            DispatchQueue.main.async {
                switch field {
                case "username": debouncedUsername = value
                case "firstName": debouncedFirstName = value
                case "lastName": debouncedLastName = value
                case "role": debouncedRole = value
                case "bio": debouncedBio = value
                case "email": debouncedEmail = value
                case "phone": debouncedPhone = value
                case "linkedin": debouncedLinkedin = value
                case "website": debouncedWebsite = value
                case "address": debouncedAddress = value
                case "currentCompany": debouncedCurrentCompany = value
                default: break
                }
            }
        }
        debounceWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + debounceDelay, execute: workItem)
    }
}

// Note: CustomTextFieldStyle is now defined in SharedFormComponents.swift 
