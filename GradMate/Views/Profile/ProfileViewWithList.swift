//
//  ProfileViewWithList.swift
//  GradMate
//
//  Alternative implementation using default SwiftUI List
//  This shows how the same functionality could be achieved with standard components
//

import SwiftUI

struct ProfileViewWithList: View {
    @EnvironmentObject private var profileManager: ProfileManager
    @EnvironmentObject private var skillManager: SkillManager
    @EnvironmentObject private var taskManager: TaskManager
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var preferencesManager: HomeScreenPreferencesManager
    @StateObject private var careerDataService = CareerDataService()
    @StateObject private var coverLetterDataService = CoverLetterDataService()
    
    @State private var showingEditProfile = false
    @State private var showingResumeExport = false
    @State private var showingAddSkill = false
    @State private var showingDeleteAlert = false
    @State private var deleteConfirmationText = ""
    @State private var showingHomeCustomization = false
    @State private var showingProjects = false
    @State private var showingInternships = false
    @State private var showingCertifications = false
    @State private var showingWorkExperience = false
    @State private var showingCoverLetter = false
    @State private var showingLanguages = false
    @State private var showingResumeUpload = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("appScreenBG").ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Profile Header (same as original)
                    ProfileIDCardView(profile: profileManager.currentProfile, showEditProfile: $showingEditProfile, showEditButton: true)
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .padding(.bottom, 20)
                    
                    // Main Content using List
                    List {
                        // Career & Skills Section
                        Section {
                            ListRow(
                                icon: "plus.circle.fill",
                                title: "Add Skill",
                                subtitle: "Add new skills and expertise",
                                color: Color("appPrimaryAccent")
                            ) { showingAddSkill = true }
                            
                            ListRow(
                                icon: "folder.fill",
                                title: "Projects",
                                subtitle: "\(careerDataService.projects.count) projects",
                                color: Color("appPrimaryAccent")
                            ) { showingProjects = true }
                            
                            ListRow(
                                icon: "briefcase.fill",
                                title: "Internships",
                                subtitle: "\(careerDataService.internships.count) internships",
                                color: Color("appWarning")
                            ) { showingInternships = true }
                            
                            ListRow(
                                icon: "trophy.fill",
                                title: "Certifications",
                                subtitle: "\(careerDataService.certificationModels.count) certifications",
                                color: Color("appWarning")
                            ) { showingCertifications = true }
                            
                            ListRow(
                                icon: "briefcase.fill",
                                title: "Work Experience",
                                subtitle: "\(careerDataService.workExperiences.count) experiences",
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
                            ) { showingLanguages = true }
                            
                            ListRow(
                                icon: "doc.text.fill",
                                title: "Cover Letters",
                                subtitle: "\(coverLetterDataService.coverLetters.count) letters",
                                color: Color("appPrimaryAccent")
                            ) { showingCoverLetter = true }
                        } header: {
                            Text("Career & Skills")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(Color("appTextPrimary"))
                                .textCase(nil)
                                .padding(.bottom, 8)
                        }
                        
                        // Productivity & Customization Section
                        Section {
                            ListRow(
                                icon: "slider.horizontal.3",
                                title: "Customize Home",
                                subtitle: "Personalize your dashboard",
                                color: Color("appWarning")
                            ) { showingHomeCustomization = true }
                            
                            ListRow(
                                icon: "doc.text.fill",
                                title: "Export Resume",
                                subtitle: "Generate PDF resume",
                                color: Color("appSuccess")
                            ) { showingResumeExport = true }
                            
                            ListRow(
                                icon: "bell.fill",
                                title: "Notifications",
                                subtitle: "Configure alerts",
                                color: Color("appWarning")
                            ) { /* Handle notifications */ }
                        } header: {
                            Text("Productivity & Customization")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(Color("appTextPrimary"))
                                .textCase(nil)
                                .padding(.bottom, 8)
                        }
                        
                        // Account Section
                        Section {
                            ListRow(
                                icon: "arrow.right.square.fill",
                                title: "Sign Out",
                                subtitle: "Sign out of your account",
                                color: Color("appWarning")
                            ) {
                                Task { await authViewModel.signOut() }
                            }
                            
                            ListRow(
                                icon: "trash.fill",
                                title: "Delete Account",
                                subtitle: "Permanently delete account",
                                color: Color("appError")
                            ) {
                                showingDeleteAlert = true
                            }
                        } header: {
                            Text("Account")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(Color("appTextPrimary"))
                                .textCase(nil)
                                .padding(.bottom, 8)
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("My Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingEditProfile = true }) {
                        Text("Edit Profile")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
            }
            // Same sheets and alerts as original
            .sheet(isPresented: $showingResumeExport) { 
                ResumeExportView()
                    .environmentObject(profileManager)
                    .environmentObject(skillManager)
            }
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView()
                    .environmentObject(profileManager)
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
            .sheet(isPresented: $showingLanguages) {
                LanguageListView().environmentObject(profileManager)
            }
            .sheet(isPresented: $showingResumeUpload) {
                ResumeUploadView()
                    .environmentObject(profileManager)
                    .environmentObject(skillManager)
            }
            .alert("Delete Account", isPresented: $showingDeleteAlert, actions: {
                TextField("Type DELETE to confirm", text: $deleteConfirmationText)
                Button("Cancel", role: .cancel) {
                    deleteConfirmationText = ""
                }
                Button("Delete", role: .destructive) {
                    // Implement delete account logic here
                    deleteConfirmationText = ""
                }.disabled(deleteConfirmationText != "DELETE")
            }, message: {
                Text("This action is permanent and cannot be undone. To confirm, type DELETE below.")
            })
        }
    }
}

// MARK: - List Row Component
struct ListRow: View {
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
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Profile ID Card (same as original)
struct ProfileIDCardView: View {
    let profile: Profile?
    @Binding var showEditProfile: Bool
    var showEditButton: Bool = true
    @State private var isFlipped = false
    @State private var showShareSheet = false
    @State private var idCardImages: [UIImage] = []
    
    var body: some View {
        ZStack {
            IDCardFrontView(profile: profile, showEditProfile: $showEditProfile, showEditButton: showEditButton)
                .opacity(isFlipped ? 0 : 1)
            ZStack {
                IDCardBackView(profile: profile)
                    .opacity(isFlipped ? 1 : 0)
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            }
            if isFlipped {
                VStack {
                    Spacer()
                    Button(action: { captureIDCards() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.title2)
                            Text("Share")
                                .font(.body)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 6)
                        .background(Color(.systemBackground).opacity(0.95))
                        .clipShape(Capsule())
                        .shadow(radius: 4)
                    }
                    .padding(.bottom, 8)
                }
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            }
        }
        .frame(width: 340, height: 400)
        .clipped()
        .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
        .animation(.spring(), value: isFlipped)
        .onTapGesture { isFlipped.toggle() }
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(isFlipped ? "Show profile front" : "Show profile back")
        .sheet(isPresented: $showShareSheet) {
            if !idCardImages.isEmpty {
                ShareSheet(items: idCardImages)
            }
        }
    }
    
    private func captureIDCards() {
        // Implementation same as original
    }
}

struct IDCardFrontView: View {
    let profile: Profile?
    @Environment(\.colorScheme) private var colorScheme
    @Binding var showEditProfile: Bool
    var showEditButton: Bool = true
    
    var body: some View {
        // Implementation same as original ProfileView
        Text("ID Card Front")
            .frame(width: 340, height: 400)
    }
}

struct IDCardBackView: View {
    let profile: Profile?
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        // Implementation same as original ProfileView
        Text("ID Card Back")
            .frame(width: 340, height: 400)
    }
}

#Preview {
    ProfileViewWithList()
        .environmentObject(ProfileManager())
        .environmentObject(SkillManager())
        .environmentObject(TaskManager())
        .environmentObject(AuthViewModel())
        .environmentObject(HomeScreenPreferencesManager())
} 