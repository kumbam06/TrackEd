//
//  ProfileView.swift
//  GradMate
//
//  Created by Pradeep Reddy Kumbam on 23/06/2025.
//

import SwiftUI
import SDWebImageSwiftUI

struct ProfileView: View {
    @EnvironmentObject private var profileManager: ProfileManager
    @EnvironmentObject private var skillManager: SkillManager
    @EnvironmentObject private var taskManager: TaskManager
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var preferencesManager: HomeScreenPreferencesManager
    @StateObject private var careerDataService = CareerDataService()
    @StateObject private var coverLetterDataService = CoverLetterDataService()
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var showingEditProfile = false
    @State private var showingResumeExport = false
    @State private var showingAddSkill = false
    @State private var showingDeleteAlert = false
    @State private var showingHomeCustomization = false
    @State private var showingProjects = false
    @State private var showingInternships = false
    @State private var showingCertifications = false
    @State private var showingWorkExperience = false
    @State private var showingCoverLetter = false
    
    var body: some View {
        ZStack {
            Color("appScreenBG").ignoresSafeArea()
            ScrollView {
                VStack(spacing: 40) {
                    profileHeaderSection
                    careerFeaturesSection
                    settingsSection
                    actionsSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 44)
            }
            .bottomFadeMask(fadeHeight: 80)
            .safeAreaInset(edge: .bottom) {
                Spacer().frame(height: 80)
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .sheet(isPresented: $showingEditProfile) { 
                EditProfileView()
                    .environmentObject(profileManager)
            }
            .sheet(isPresented: $showingResumeExport) { 
                ResumeExportView()
                    .environmentObject(profileManager)
                    .environmentObject(skillManager)
            }
            .sheet(isPresented: $showingAddSkill) { 
                AddSkillView()
                    .environmentObject(skillManager)
            }
            .sheet(isPresented: $showingHomeCustomization) {
                HomeScreenCustomizationView()
                    .environmentObject(preferencesManager)
            }
            .sheet(isPresented: $showingProjects) {
                ProjectListView()
                    .environmentObject(careerDataService)
            }
            .sheet(isPresented: $showingInternships) {
                InternshipListView()
                    .environmentObject(careerDataService)
            }
            .sheet(isPresented: $showingCertifications) {
                CertificationListView()
                    .environmentObject(careerDataService)
            }
            .sheet(isPresented: $showingWorkExperience) {
                WorkExperienceListView()
                    .environmentObject(careerDataService)
            }
            .sheet(isPresented: $showingCoverLetter) {
                CoverLetterListView()
                    .environmentObject(coverLetterDataService)
            }
            .alert("Delete Account", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    // Implement delete account logic
                }
            } message: {
                Text("Are you sure you want to delete your account? This action cannot be undone.")
            }
        }
    }
    
    // MARK: - Profile Header Section
    private var profileHeaderSection: some View {
        VStack(spacing: 24) {
            // Profile Photo and Edit Button
            ZStack(alignment: .bottomTrailing) {
                if let photoData = profileManager.currentProfile?.photoData,
                   let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color("appPrimaryAccent").opacity(0.2), lineWidth: 3)
                        )
                        .shadow(color: Color("appPrimaryAccent").opacity(0.15), radius: 12, x: 0, y: 6)
                } else {
                    ZStack {
                        Circle()
                            .fill(Color("appPrimaryAccent").opacity(0.1))
                            .frame(width: 120, height: 120)
                        Image(systemName: "person.fill")
                            .font(.system(size: 50))
                            .foregroundColor(Color("appPrimaryAccent"))
                    }
                    .overlay(
                        Circle()
                            .stroke(Color("appPrimaryAccent").opacity(0.2), lineWidth: 3)
                    )
                    .shadow(color: Color("appPrimaryAccent").opacity(0.15), radius: 12, x: 0, y: 6)
                }
                
                Button(action: { showingEditProfile = true }) {
                    ZStack {
                        Circle()
                            .fill(Color("appPrimaryAccent"))
                            .frame(width: 36, height: 36)
                        Image(systemName: "pencil")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .shadow(color: Color("appPrimaryAccent").opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .offset(x: 8, y: 8)
            }
            
            // Profile Info
            VStack(spacing: 8) {
                Text(profileManager.currentProfile?.name ?? "STUDENT")
                    .font(.largeTitle)
                    .fontWeight(.black)
                    .foregroundColor(Color("appTextPrimary"))
                    .kerning(2)
                
                Text(profileManager.currentProfile?.role ?? "STUDENT")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("appPrimaryAccent"))
                    .kerning(1.5)
                
                if let bio = profileManager.currentProfile?.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(Color("appTextSecondary"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .background(Color("appStrokeGray"))
                        .cornerRadius(16)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .background(Color("appCardBG"))
        .cornerRadius(24)
    }
    
    // MARK: - Career Features Section
    private var careerFeaturesSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("CAREER FEATURES")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(Color("appTextPrimary"))
                    .kerning(1.5)
                
                Spacer()
                
                Rectangle()
                    .fill(Color("appTextPrimary"))
                    .frame(height: 2)
                    .frame(width: 80)
            }
            .padding(.leading, 4)
            
            VStack(spacing: 16) {
                skillsSection
                careerFeaturesSectionContent
            }
            .background(Color("appCardBG"))
            .cornerRadius(16)
        }
    }
    
    // MARK: - Skills Section
    private var skillsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("SKILLS & EXPERTISE")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(Color("appTextPrimary"))
                    .kerning(1.5)
                
                Spacer()
                
                Button(action: { showingAddSkill = true }) {
                    ZStack {
                        Circle()
                            .fill(Color("appPrimaryAccent").opacity(0.2))
                            .frame(width: 32, height: 32)
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color("appPrimaryAccent"))
                    }
                }
            }
            .padding(.leading, 4)
            
            if skillManager.skills.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "star.slash")
                        .font(.system(size: 32))
                        .foregroundColor(Color("appTextSecondary"))
                    Text("NO SKILLS ADDED")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color("appTextSecondary"))
                    Text("Add your first skill to showcase your expertise")
                        .font(.caption)
                        .foregroundColor(Color("appTextSecondary"))
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity)
                .background(Color("appStrokeGray"))
                .cornerRadius(12)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                    ForEach(Array(skillManager.skills.prefix(4)), id: \.id) { skill in
                        ProfileSkillCard(skill: skill, color: Color("appPrimaryAccent"))
                    }
                }
                
                if skillManager.skills.count > 4 {
                    Button(action: { showingAddSkill = true }) {
                        HStack {
                            Text("View All \(skillManager.skills.count) Skills")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(Color("appPrimaryAccent"))
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundColor(Color("appPrimaryAccent"))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color("appStrokeGray"))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding(16)
    }
    
    // MARK: - Career Features Section Content
    private var careerFeaturesSectionContent: some View {
        VStack(spacing: 0) {
            ProfileActionRow(
                icon: "plus.circle.fill",
                title: "ADD SKILL",
                subtitle: "Add new skills and expertise",
                color: Color("appPrimaryAccent")
            ) {
                showingAddSkill = true
            }
            
            Divider()
                .padding(.leading, 56)
            
            ProfileActionRow(
                icon: "folder.fill",
                title: "PROJECTS",
                subtitle: "\(careerDataService.projects.count) projects",
                color: Color("appPrimaryAccent")
            ) {
                showingProjects = true
            }
            
            Divider()
                .padding(.leading, 56)
            
            ProfileActionRow(
                icon: "briefcase.fill",
                title: "INTERNSHIPS",
                subtitle: "\(careerDataService.internships.count) internships",
                color: Color("appWarning")
            ) {
                showingInternships = true
            }
            
            Divider()
                .padding(.leading, 56)
            
            ProfileActionRow(
                icon: "trophy.fill",
                title: "CERTIFICATIONS",
                subtitle: "\(careerDataService.certificationModels.count) certifications",
                color: Color("appWarning")
            ) {
                showingCertifications = true
            }
            
            Divider()
                .padding(.leading, 56)
            
            ProfileActionRow(
                icon: "briefcase.fill",
                title: "WORK EXPERIENCE",
                subtitle: "\(careerDataService.workExperiences.count) experiences",
                color: Color("appSuccess")
            ) {
                showingWorkExperience = true
            }
            
            Divider()
                .padding(.leading, 56)
            
            ProfileActionRow(
                icon: "doc.text.fill",
                title: "COVER LETTERS",
                subtitle: "\(coverLetterDataService.coverLetters.count) letters",
                color: Color("appPrimaryAccent")
            ) {
                showingCoverLetter = true
            }
        }
    }
    
    // MARK: - Settings Section
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("SETTINGS")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(Color("appTextPrimary"))
                    .kerning(1.5)
                
                Spacer()
                
                Rectangle()
                    .fill(Color("appTextPrimary"))
                    .frame(height: 2)
                    .frame(width: 50)
            }
            .padding(.leading, 4)
            
            VStack(spacing: 0) {
                ProfileActionRow(
                    icon: "person.crop.circle",
                    title: "ACCOUNT SETTINGS",
                    subtitle: "Manage your profile",
                    color: Color("appPrimaryAccent")
                ) {
                    showingEditProfile = true
                }
                
                Divider()
                    .padding(.leading, 56)
                
                ProfileActionRow(
                    icon: "slider.horizontal.3",
                    title: "CUSTOMIZE HOME",
                    subtitle: "Personalize your dashboard",
                    color: Color("appWarning")
                ) {
                    showingHomeCustomization = true
                }
                
                Divider()
                    .padding(.leading, 56)
                
                ProfileActionRow(
                    icon: "bell.fill",
                    title: "NOTIFICATIONS",
                    subtitle: "Configure alerts",
                    color: Color("appWarning")
                ) {
                    // Handle notifications
                }
                
                Divider()
                    .padding(.leading, 56)
                
                ProfileActionRow(
                    icon: "doc.text.fill",
                    title: "EXPORT RESUME",
                    subtitle: "Generate PDF resume",
                    color: Color("appSuccess")
                ) {
                    showingResumeExport = true
                }
            }
            .background(Color("appCardBG"))
            .cornerRadius(16)
        }
    }
    
    // MARK: - Actions Section
    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("ACTIONS")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(Color("appTextPrimary"))
                    .kerning(1.5)
                
                Spacer()
                
                Rectangle()
                    .fill(Color("appTextPrimary"))
                    .frame(height: 2)
                    .frame(width: 40)
            }
            .padding(.leading, 4)
            
            VStack(spacing: 0) {
                ProfileActionRow(
                    icon: "arrow.right.square.fill",
                    title: "SIGN OUT",
                    subtitle: "Sign out of your account",
                    color: Color("appWarning")
                ) {
                    Task {
                        await authViewModel.signOut()
                    }
                }
                
                Divider()
                    .padding(.leading, 56)
                
                ProfileActionRow(
                    icon: "trash.fill",
                    title: "DELETE ACCOUNT",
                    subtitle: "Permanently delete account",
                    color: Color("appError")
                ) {
                    showingDeleteAlert = true
                }
            }
            .background(Color("appCardBG"))
            .cornerRadius(16)
        }
    }
}

// MARK: - Supporting Views
struct ProfileActionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color("appTextPrimary"))
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(Color("appTextSecondary"))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Color("appTextSecondary"))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ProfileSkillCard: View {
    let skill: SkillEntity
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(skill.name ?? "Unknown Skill")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("appTextPrimary"))
                    .lineLimit(1)
                
                Spacer()
                
                Text("\(Int(skill.proficiency))/5")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(color)
            }
            
            HStack(spacing: 2) {
                ForEach(0..<5, id: \.self) { index in
                    Image(systemName: index < Int(skill.proficiency) ? "star.fill" : "star")
                        .font(.caption2)
                        .foregroundColor(index < Int(skill.proficiency) ? color : Color("appTextSecondary"))
                }
            }
        }
        .padding(12)
        .background(Color("appStrokeGray"))
        .cornerRadius(12)
    }
} 