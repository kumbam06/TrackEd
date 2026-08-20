//
//  ProfileView.swift
//  GradMate
//
//  Created by Pradeep Reddy Kumbam on 23/06/2025.
//

import SwiftUI
import SDWebImageSwiftUI
import CoreImage.CIFilterBuiltins
import Photos

struct ProfileView: View {
    @EnvironmentObject private var profileManager: ProfileManager
    @EnvironmentObject private var skillManager: SkillManager
    @EnvironmentObject private var taskManager: TaskManager
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var preferencesManager: HomeScreenPreferencesManager
    @EnvironmentObject private var careerDataService: CareerDataService
    @EnvironmentObject private var languageManager: LanguageManager
    @StateObject private var coverLetterDataService = CoverLetterDataService()
    @Environment(\.colorScheme) private var colorScheme
    
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
        ZStack {
            Color("appScreenBG").ignoresSafeArea()
            ScrollView {
                VStack(spacing: 40) {
                    profileHeaderSection
                    profilePortfolioSection
                    careerAndSkillsSection
                    productivityAndCustomizationSection
                    accountSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 44)
                .padding(.bottom, 100) // Padding for tab bar
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
            .sheet(isPresented: $showingResumeExport) { 
                ResumeExportView()
                    .environmentObject(profileManager)
                    .environmentObject(skillManager)
                    .environmentObject(careerDataService)
                    .environmentObject(languageManager)
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
                    .environmentObject(profileManager)
                    .environmentObject(skillManager)
                    .environmentObject(careerDataService)
            }
            .sheet(isPresented: $showingLanguages) {
                LanguageListView()
                    .environmentObject(languageManager)
            }
            .sheet(isPresented: $showingResumeUpload) {
                ResumeUploadView()
                    .environmentObject(profileManager)
                    .environmentObject(skillManager)
                    .environmentObject(careerDataService)
                    .environmentObject(languageManager)
            }
            .alert("Delete Account", isPresented: $showingDeleteAlert, actions: {
                TextField("Type DELETE to confirm", text: $deleteConfirmationText)
                Button("Cancel", role: .cancel) {
                    deleteConfirmationText = ""
                }
                Button("Delete", role: .destructive) {
                    Task {
                        let success = await authViewModel.deleteAccount()
                        if !success {
                            deleteConfirmationText = ""
                        }
                    }
                    deleteConfirmationText = ""
                }.disabled(deleteConfirmationText != "DELETE")
            }, message: {
                Text("This action is permanent and cannot be undone. To confirm, type DELETE below.")
            })
        }
    }
    
    // MARK: - Profile Header Section
    private var profileHeaderSection: some View {
        ProfileIDCardView(profile: profileManager.currentProfile, showEditProfile: $showingEditProfile, showEditButton: true)
            .padding(.horizontal, 20)
            .padding(.top, 24)
    }
    
    // MARK: - Flippable ID Card
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
            if #available(iOS 16.0, *) {
                let rendererFront = ImageRenderer(content:
                    ProfileView.ProfileIDCardView(profile: profile, showEditProfile: .constant(false), showEditButton: false)
                        .frame(width: 340, height: 400)
                        .padding(.horizontal, 20)
                )
                rendererFront.scale = 3 // High quality
                let rendererBack = ImageRenderer(content:
                    ProfileView.IDCardBackView(profile: profile)
                        .frame(width: 340, height: 400)
                        .padding(.horizontal, 20)
                )
                rendererBack.scale = 3 // High quality
                var images: [UIImage] = []
                if let front = rendererFront.uiImage {
                    images.append(front)
                }
                if let back = rendererBack.uiImage {
                    images.append(back)
                }
                idCardImages = images
                showShareSheet = true
            } else {
                // For iOS 15.0+, show an alert that this feature requires iOS 16.0+
                // You could implement an alternative sharing method here
                print("ID Card sharing requires iOS 16.0 or later")
            }
        }
    }

    struct IDCardFrontView: View {
        let profile: Profile?
        @Environment(\.colorScheme) private var colorScheme
        @Binding var showEditProfile: Bool
        var showEditButton: Bool = true
        var body: some View {
            ZStack {
                // Shadow layer (not clipped)
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.clear)
                    .shadow(color: Color.black.opacity(0.18), radius: 24, y: 12)
                // Card background (matches app background, no border)
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(.systemBackground).opacity(colorScheme == .dark ? 0.92 : 0.98))
                    .overlay(
                        Text("GradMate")
                            .font(.system(size: 120, weight: .bold))
                            .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.07) : Color.black.opacity(0.06))
                            .rotationEffect(.degrees(-90))
                            .padding(.vertical, 24),
                        alignment: .center
                    )
                VStack(spacing: 0) {
                    // Company name at the very top
                    HStack {
                        Text((profile?.currentCompany?.isEmpty == false ? profile?.currentCompany : "Company Name") ?? "Company Name")
                            .font(.caption)
                            .foregroundColor(Color("appTextPrimary"))
                            .padding(.top, 16)
                            .padding(.leading, 20)
                        Spacer()
                    }
                    Spacer(minLength: 24)
                    HStack(alignment: .center, spacing: 0) {
                        // Left: Info, name starts from card center
                        VStack(alignment: .leading, spacing: 18) {
                            Spacer()
                            VStack(alignment: .leading, spacing: 0) {
                                Text(profile?.name?.components(separatedBy: " ").first ?? "First")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(Color.accentColor)
                                Text(profile?.name?.components(separatedBy: " ").dropFirst().joined(separator: " ") ?? "Last")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(Color.accentColor)
                                    .padding(.bottom, 2)
                                Rectangle()
                                    .fill(colorScheme == .dark ? Color.white : Color.black)
                                    .frame(width: 40, height: 3)
                                    .cornerRadius(2)
                            }
                            Text(profile?.role?.uppercased() ?? "GRAPHIC DESIGNER")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color("appTextPrimary"))
                            if let summary = profile?.bio, !summary.isEmpty {
                                Text(summary)
                                    .font(.footnote)
                                    .italic()
                                    .foregroundColor(Color("appTextSecondary"))
                                    .padding(.top, 8)
                            }
                            Spacer()
                        }
                        .padding(.leading, 20)
                        .padding(.trailing, 8)
                        .frame(maxHeight: .infinity)
                        // Right: Profile image, square, moved up
                        VStack(spacing: 8) {
                            if let photoData = profile?.photoData, let uiImage = UIImage(data: photoData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 100, height: 160)
                                    .clipped()
                                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(colorScheme == .dark ? Color.white : Color.gray.opacity(0.25), lineWidth: 2))
                                    .shadow(radius: 6)
                            } else {
                                Image("AppLogo")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 100, height: 160)
                                    .clipped()
                                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(colorScheme == .dark ? Color.white : Color.gray.opacity(0.25), lineWidth: 2))
                                    .shadow(radius: 6)
                            }
                            // Username below image
                            if let username = profile?.username, !username.isEmpty {
                                Text("@" + username)
                                    .font(.caption)
                                    .foregroundColor(Color("appTextSecondary"))
                                    .padding(.top, 2)
                            }
                        }
                        .offset(y: -40)
                        .padding(.trailing, 24)
                    }
                    Spacer()
                }
            }
            .frame(width: 340, height: 400)
            .padding(.horizontal, 20)
            .background(Color.clear)
        }
    }

    struct IDCardBackView: View {
        let profile: Profile?
        @Environment(\.colorScheme) private var colorScheme
        @Environment(\.openURL) private var openURL
        var body: some View {
            ZStack {
                // Shadow layer (not clipped)
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.clear)
                    .shadow(color: Color.black.opacity(0.18), radius: 24, y: 12)
                // Card background (matches app background, no border)
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(.systemBackground).opacity(colorScheme == .dark ? 0.92 : 0.98))
                    .overlay(
                        Text("GradMate")
                            .font(.system(size: 120, weight: .bold))
                            .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.07) : Color.black.opacity(0.06))
                            .rotationEffect(.degrees(-90))
                            .padding(.vertical, 24),
                        alignment: .center
                    )
                HStack(alignment: .center, spacing: 0) {
                    // Left: Icon + value for each present field, left-aligned
                    Spacer()
                    VStack(alignment: .leading, spacing: 18) {
                        Spacer()
                        if let email = profile?.email, !email.isEmpty {
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "envelope.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(Color.accentColor)
                                Text(email)
                                    .font(.body)
                                    .foregroundColor(Color("appTextPrimary"))
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        if let phone = profile?.phone, !phone.isEmpty {
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "phone.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(Color.accentColor)
                                Text(phone)
                                    .font(.body)
                                    .foregroundColor(Color("appTextPrimary"))
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        if let address = profile?.address, !address.isEmpty {
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(Color.accentColor)
                                Text(address)
                                    .font(.body)
                                    .foregroundColor(Color("appTextPrimary"))
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        if let linkedin = profile?.linkedin, !linkedin.isEmpty {
                            HStack(alignment: .top, spacing: 10) {
                                Image("linkedin-icon")
                                    .resizable()
                                    .frame(width: 22, height: 22)
                                    .clipShape(Circle())
                                    .shadow(radius: 1)
                                Button(action: {
                                    let raw = linkedin.hasPrefix("http") ? linkedin : "https://\(linkedin)"
                                    if let url = URL(string: raw) {
                                        openURL(url)
                                    }
                                }) {
                                    Text(linkedin)
                                        .font(.body)
                                        .foregroundColor(Color.accentColor)
                                        .underline()
                                        .lineLimit(nil)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        if let website = profile?.website, !website.isEmpty {
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "globe")
                                    .font(.system(size: 22))
                                    .foregroundColor(Color.accentColor)
                                Button(action: {
                                    let raw = website.hasPrefix("http") ? website : "https://\(website)"
                                    if let url = URL(string: raw) {
                                        openURL(url)
                                    }
                                }) {
                                    Text(website)
                                        .font(.body)
                                        .foregroundColor(Color.accentColor)
                                        .underline()
                                        .lineLimit(nil)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        Spacer()
                    }
                    .padding(.leading, 32)
                    .padding(.trailing, 8)
                    Spacer()
                }
            }
            .frame(width: 340, height: 400)
            .padding(.horizontal, 20)
            .background(Color.clear)
        }
    }

    struct LabeledDetail: View {
        let label: String
        let value: String
        var dark: Bool = false
        var alignLeft: Bool = false
        var body: some View {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.accentColor)
                Text(value)
                    .font(.body)
                    .foregroundColor(dark ? .black : .white)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(alignLeft ? .leading : .center)
            }
        }
    }
    
    private var profilePortfolioSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("YOUR RESUME DATA")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(Color("appTextPrimary"))
                    .kerning(1.5)
                Spacer()
                Rectangle()
                    .fill(Color("appTextPrimary"))
                    .frame(height: 2)
                    .frame(width: 90)
            }
            .padding(.leading, 4)
            
            if let profile = profileManager.currentProfile {
                PortfolioInfoCard(profile: profile)
            }
            
            if !skillManager.skills.isEmpty {
                PortfolioSectionCard(title: "Skills", icon: "sparkles") {
                    FlexibleChipWrap(titles: skillManager.skills.compactMap(\.name))
                }
            }
            
            if !careerDataService.workExperienceModels.isEmpty {
                PortfolioSectionCard(title: "Work experience", icon: "briefcase.fill") {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(careerDataService.workExperienceModels) { item in
                            PortfolioLine(title: item.title, subtitle: item.company)
                        }
                    }
                }
            }
            
            if !careerDataService.internshipModels.isEmpty {
                PortfolioSectionCard(title: "Internships", icon: "building.2.fill") {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(careerDataService.internshipModels) { item in
                            PortfolioLine(title: item.title, subtitle: item.company)
                        }
                    }
                }
            }
            
            if !careerDataService.projectModels.isEmpty {
                PortfolioSectionCard(title: "Projects", icon: "folder.fill") {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(careerDataService.projectModels) { item in
                            PortfolioLine(title: item.title, subtitle: item.role)
                        }
                    }
                }
            }
            
            if !careerDataService.certificationModels.isEmpty {
                PortfolioSectionCard(title: "Certifications", icon: "checkmark.seal.fill") {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(careerDataService.certificationModels) { item in
                            PortfolioLine(title: item.title, subtitle: item.organization)
                        }
                    }
                }
            }
            
            if !languageManager.languages.isEmpty {
                PortfolioSectionCard(title: "Languages", icon: "globe") {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(languageManager.languages) { item in
                            PortfolioLine(title: item.name, subtitle: item.proficiency.rawValue)
                        }
                    }
                }
            }
            
            if skillManager.skills.isEmpty
                && careerDataService.workExperiences.isEmpty
                && careerDataService.projects.isEmpty
                && careerDataService.internships.isEmpty
                && careerDataService.certifications.isEmpty {
                Text("Upload a resume or add sections below. Everything you save is stored in your account and appears here and on Build Resume.")
                    .font(.footnote)
                    .foregroundColor(Color("appTextSecondary"))
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color("appCardBG"))
                    .cornerRadius(16)
            }
        }
    }
    
    // MARK: - Career & Skills Section
    private var careerAndSkillsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("CAREER & SKILLS")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(Color("appTextPrimary"))
                    .kerning(1.5)
                Spacer()
                Rectangle()
                    .fill(Color("appTextPrimary"))
                    .frame(height: 2)
                    .frame(width: 110)
            }
            .padding(.leading, 4)
            VStack(spacing: 8) {
                ProfileActionRow(
                    icon: "plus.circle.fill",
                    title: "ADD SKILL",
                    subtitle: skillManager.skills.isEmpty ? "Add skills used on your resume" : "\(skillManager.skills.count) skills on your resume",
                    color: Color("appPrimaryAccent")
                ) { showingAddSkill = true }
                
                ProfileActionRow(
                    icon: "folder.fill",
                    title: "PROJECTS",
                    subtitle: "\(careerDataService.projects.count) projects",
                    color: Color("appPrimaryAccent")
                ) { showingProjects = true }
                
                ProfileActionRow(
                    icon: "briefcase.fill",
                    title: "INTERNSHIPS",
                    subtitle: "\(careerDataService.internships.count) internships",
                    color: Color("appWarning")
                ) { showingInternships = true }
                
                ProfileActionRow(
                    icon: "trophy.fill",
                    title: "CERTIFICATIONS",
                    subtitle: "\(careerDataService.certificationModels.count) certifications",
                    color: Color("appWarning")
                ) { showingCertifications = true }
                
                ProfileActionRow(
                    icon: "briefcase.fill",
                    title: "WORK EXPERIENCE",
                    subtitle: "\(careerDataService.workExperiences.count) experiences",
                    color: Color("appSuccess")
                ) { showingWorkExperience = true }
                
                ProfileActionRow(
                    icon: "arrow.up.doc.fill",
                    title: "UPLOAD RESUME",
                    subtitle: "Auto-fill every section from a PDF",
                    color: Color("appPrimaryAccent")
                ) { showingResumeUpload = true }
                
                ProfileActionRow(
                    icon: "globe",
                    title: "LANGUAGES",
                    subtitle: languageManager.languages.isEmpty ? "Add spoken languages" : "\(languageManager.languages.count) languages on your resume",
                    color: Color("appPrimaryAccent")
                ) { showingLanguages = true }
                
                ProfileActionRow(
                    icon: "doc.text.fill",
                    title: "COVER LETTERS",
                    subtitle: "\(coverLetterDataService.coverLetters.count) letters",
                    color: Color("appPrimaryAccent")
                ) { showingCoverLetter = true }
            }
        }
    }

    // MARK: - Productivity & Customization Section
    private var productivityAndCustomizationSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("PRODUCTIVITY & CUSTOMIZATION")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(Color("appTextPrimary"))
                    .kerning(1.5)
                Spacer()
                Rectangle()
                    .fill(Color("appTextPrimary"))
                    .frame(height: 2)
                    .frame(width: 170)
            }
            .padding(.leading, 4)
            VStack(spacing: 8) {
                ProfileActionRow(
                    icon: "slider.horizontal.3",
                    title: "CUSTOMIZE HOME",
                    subtitle: "Personalize your dashboard",
                    color: Color("appWarning")
                ) { showingHomeCustomization = true }
                
                ProfileActionRow(
                    icon: "doc.text.fill",
                    title: "BUILD & SHARE RESUME",
                    subtitle: "Preview designs and email recruiters",
                    color: Color("appSuccess")
                ) { showingResumeExport = true }
                
                ProfileActionRow(
                    icon: "bell.fill",
                    title: "NOTIFICATIONS",
                    subtitle: "Configure alerts",
                    color: Color("appWarning")
                ) { /* Handle notifications */ }
            }
        }
    }

    // MARK: - Account Section
    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("ACCOUNT")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(Color("appTextPrimary"))
                    .kerning(1.5)
                Spacer()
                Rectangle()
                    .fill(Color("appTextPrimary"))
                    .frame(height: 2)
                    .frame(width: 70)
            }
            .padding(.leading, 4)
            VStack(spacing: 8) {
                ProfileActionRow(
                    icon: "arrow.right.square.fill",
                    title: "SIGN OUT",
                    subtitle: "Sign out of your account",
                    color: Color("appWarning")
                ) {
                    Task { await authViewModel.signOut() }
                }
                
                ProfileActionRow(
                    icon: "trash.fill",
                    title: "DELETE ACCOUNT",
                    subtitle: "Permanently delete account",
                    color: Color("appError")
                ) {
                    showingDeleteAlert = true
                }
            }
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
                        .shadow(color: color.opacity(0.2), radius: 4, x: 0, y: 2)
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
            .frame(maxWidth: .infinity)
            .background(Color("appCardBG"))
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityHint("Opens \(title.lowercased())")
    }
}

struct PortfolioInfoCard: View {
    let profile: Profile
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let name = profile.name, !name.isEmpty {
                Text(name)
                    .font(.headline)
                    .foregroundColor(Color("appTextPrimary"))
            }
            if let role = profile.role, !role.isEmpty {
                Text(role)
                    .font(.subheadline)
                    .foregroundColor(Color("appTextSecondary"))
            }
            contactRow("envelope", profile.email)
            contactRow("phone", profile.phone)
            contactRow("link", profile.linkedin)
            contactRow("globe", profile.website)
            contactRow("mappin.and.ellipse", profile.address)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("appCardBG"))
        .cornerRadius(16)
    }
    
    @ViewBuilder
    private func contactRow(_ icon: String, _ value: String?) -> some View {
        if let value, !value.isEmpty {
            Label(value, systemImage: icon)
                .font(.footnote)
                .foregroundColor(Color("appTextPrimary"))
        }
    }
}

struct PortfolioSectionCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder var content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(Color("appTextPrimary"))
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("appCardBG"))
        .cornerRadius(16)
        .accessibilityElement(children: .contain)
    }
}

struct PortfolioLine: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundColor(Color("appTextPrimary"))
            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(Color("appTextSecondary"))
            }
        }
        .accessibilityElement(children: .combine)
    }
}

struct FlexibleChipWrap: View {
    let titles: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(titles.enumerated()), id: \.offset) { _, title in
                Text(title)
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color("appPrimaryAccent").opacity(0.12))
                    .foregroundColor(Color("appPrimaryAccent"))
                    .clipShape(Capsule())
            }
        }
        .accessibilityLabel("Skills: \(titles.joined(separator: ", "))")
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
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
} 
