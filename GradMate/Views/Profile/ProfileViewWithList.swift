//
//  ProfileViewWithList.swift
//  GradMate
//
//  Alternative implementation using default SwiftUI List
//  This shows how the same functionality could be achieved with standard components
//

import SwiftUI
import SDWebImageSwiftUI

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

struct ProfileViewWithList: View {
    @EnvironmentObject private var profileManager: ProfileManager
    @EnvironmentObject private var skillManager: SkillManager
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingEditProfile = false
    @State private var showingAddSkill = false
    @State private var showingWorkExperience = false
    @State private var showingInternship = false
    @State private var showingProject = false
    @State private var showingCertification = false
    @State private var showingLanguage = false
    @State private var showingResumeUpload = false
    @State private var showingCoverLetter = false
    @State private var showingHomeScreenCustomization = false
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("appScreenBG").ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Profile Header
                    profileHeader
                    
                    // Tab Content
                    TabView(selection: $selectedTab) {
                        skillsTab
                            .tag(0)
                        
                        experienceTab
                            .tag(1)
                        
                        projectsTab
                            .tag(2)
                        
                        certificationsTab
                            .tag(3)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView()
            }
            .sheet(isPresented: $showingAddSkill) {
                AddSkillView()
            }
            .sheet(isPresented: $showingWorkExperience) {
                WorkExperienceEditView(workExperience: nil) { _ in }
            }
            .sheet(isPresented: $showingInternship) {
                InternshipEditView(internship: nil, onSave: { _ in }, onCancel: { })
            }
            .sheet(isPresented: $showingProject) {
                ProjectEditView(project: nil) { _ in } onCancel: { }
            }
            .sheet(isPresented: $showingCertification) {
                CertificationEditView(certification: nil, onSave: { _ in }, onCancel: { })
            }
            .sheet(isPresented: $showingLanguage) {
                LanguageListView()
            }
            .sheet(isPresented: $showingResumeUpload) {
                ResumeUploadView()
            }
            .sheet(isPresented: $showingCoverLetter) {
                CoverLetterComposerView()
            }
            .sheet(isPresented: $showingHomeScreenCustomization) {
                HomeScreenCustomizationView()
            }
        }
    }
    
    private var profileHeader: some View {
        VStack {
            Text("Profile")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(Color("appTextPrimary"))
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .padding(.bottom, 20)
    }
    
    private var skillsTab: some View {
        VStack {
            ListRow(
                icon: "plus.circle.fill",
                title: "Add Skill",
                subtitle: "Add new skills and expertise",
                color: Color("appPrimaryAccent")
            ) { showingAddSkill = true }
            
            ListRow(
                icon: "folder.fill",
                title: "Projects",
                subtitle: "Manage your projects",
                color: Color("appPrimaryAccent")
            ) { showingProject = true }
            
            ListRow(
                icon: "briefcase.fill",
                title: "Internships",
                subtitle: "Manage your internships",
                color: Color("appWarning")
            ) { showingInternship = true }
            
            ListRow(
                icon: "trophy.fill",
                title: "Certifications",
                subtitle: "Manage your certifications",
                color: Color("appWarning")
            ) { showingCertification = true }
            
            ListRow(
                icon: "briefcase.fill",
                title: "Work Experience",
                subtitle: "Manage your work experience",
                color: Color("appSuccess")
            ) { showingWorkExperience = true }
            
            ListRow(
                icon: "arrow.up.doc.fill",
                title: "Upload Resume",
                subtitle: "Import and auto-fill profile",
                color: Color("appPrimaryAccent")
            ) { showingResumeUpload = true }
            
            ListRow(
                icon: "globe",
                title: "Languages",
                subtitle: "Add spoken languages",
                color: Color("appPrimaryAccent")
            ) { showingLanguage = true }
            
            ListRow(
                icon: "doc.text.fill",
                title: "Cover Letters",
                subtitle: "Manage your cover letters",
                color: Color("appPrimaryAccent")
            ) { showingCoverLetter = true }
        }
        .padding()
    }
    
    private var experienceTab: some View {
        VStack {
            ListRow(
                icon: "briefcase.fill",
                title: "Work Experience",
                subtitle: "Manage your work experience",
                color: Color("appSuccess")
            ) { showingWorkExperience = true }
            
            ListRow(
                icon: "arrow.up.doc.fill",
                title: "Upload Resume",
                subtitle: "Import and auto-fill profile",
                color: Color("appPrimaryAccent")
            ) { showingResumeUpload = true }
            
            ListRow(
                icon: "globe",
                title: "Languages",
                subtitle: "Add spoken languages",
                color: Color("appPrimaryAccent")
            ) { showingLanguage = true }
            
            ListRow(
                icon: "doc.text.fill",
                title: "Cover Letters",
                subtitle: "Manage your cover letters",
                color: Color("appPrimaryAccent")
            ) { showingCoverLetter = true }
        }
        .padding()
    }
    
    private var projectsTab: some View {
        VStack {
            ListRow(
                icon: "plus.circle.fill",
                title: "Add Project",
                subtitle: "Add a new project to your portfolio",
                color: Color("appPrimaryAccent")
            ) { showingProject = true }
            
            ListRow(
                icon: "folder.fill",
                title: "Projects",
                subtitle: "Manage your projects",
                color: Color("appPrimaryAccent")
            ) { showingProject = true }
        }
        .padding()
    }
    
    private var certificationsTab: some View {
        VStack {
            ListRow(
                icon: "plus.circle.fill",
                title: "Add Certification",
                subtitle: "Add a new certification to your profile",
                color: Color("appPrimaryAccent")
            ) { showingCertification = true }
            
            ListRow(
                icon: "trophy.fill",
                title: "Certifications",
                subtitle: "Manage your certifications",
                color: Color("appWarning")
            ) { showingCertification = true }
        }
        .padding()
    }
}

struct ListRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color("appTextPrimary"))
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(Color("appTextSecondary"))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Color("appTextSecondary"))
            }
            .padding()
            .background(Color("appCardBG"))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    if #available(iOS 16.0, *) {
        ProfileViewWithList()
            .environmentObject(ProfileManager())
            .environmentObject(SkillManager())
            .environmentObject(TaskManager())
            .environmentObject(AuthViewModel())
            .environmentObject(HomeScreenPreferencesManager())
    } else {
        Text("Profile View requires iOS 16.0+")
            .environmentObject(ProfileManager())
            .environmentObject(SkillManager())
            .environmentObject(TaskManager())
            .environmentObject(AuthViewModel())
            .environmentObject(HomeScreenPreferencesManager())
    }
} 