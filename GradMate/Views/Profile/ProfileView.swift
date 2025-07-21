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
                .padding(.bottom, 100) // Padding for tab bar
            }
            .navigationTitle("")
            .navigationBarHidden(true)
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
                        .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0)) // Fix mirrored text
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
                            .foregroundColor(colorScheme == .dark ? .white : .black)
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
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            if let summary = profile?.bio, !summary.isEmpty {
                                Text(summary)
                                    .font(.footnote)
                                    .italic()
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                    .padding(.top, 8)
                            }
                            Spacer()
                        }
                        .padding(.leading, 20)
                        .padding(.trailing, 8)
                        .frame(maxHeight: .infinity)
                        // Right: Profile image, square, moved up
                        ZStack(alignment: .topTrailing) {
                            VStack(spacing: 8) {
                                if let photoData = profile?.photoData, let uiImage = UIImage(data: photoData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 100, height: 160)
                                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(colorScheme == .dark ? Color.white : Color.black, lineWidth: 2))
                                        .shadow(radius: 6)
                                } else {
                                    Image("AppLogo")
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 100, height: 160)
                                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(colorScheme == .dark ? Color.white : Color.black, lineWidth: 2))
                                        .shadow(radius: 6)
                                }
                                // Username below image
                                if let username = profile?.username, !username.isEmpty {
                                    Text("@" + username)
                                        .font(.caption)
                                        .foregroundColor(colorScheme == .dark ? .white : .black)
                                        .padding(.top, 2)
                                }
                            }
                            if showEditButton {
                                Button(action: { showEditProfile = true }) {
                                    Image(systemName: "pencil.circle.fill")
                                        .resizable()
                                        .frame(width: 36, height: 36)
                                        .foregroundColor(Color.accentColor)
                                        .background(Color(.systemBackground).opacity(0.9))
                                        .clipShape(Circle())
                                        .shadow(radius: 4)
                                        .padding(6)
                                }
                                .offset(x: 18, y: -18)
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
        @State private var showCopied = false
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
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                                Button(action: {
                                    UIPasteboard.general.string = email
                                    showCopied = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { showCopied = false }
                                }) {
                                    Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                                        .foregroundColor(Color.accentColor)
                                }
                            }
                        }
                        if let phone = profile?.phone, !phone.isEmpty {
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "phone.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(Color.accentColor)
                                Text(phone)
                                    .font(.body)
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                                Button(action: {
                                    UIPasteboard.general.string = phone
                                    showCopied = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { showCopied = false }
                                }) {
                                    Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                                        .foregroundColor(Color.accentColor)
                                }
                            }
                        }
                        if let address = profile?.address, !address.isEmpty {
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(Color.accentColor)
                                Text(address)
                                    .font(.body)
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                                Button(action: {
                                    UIPasteboard.general.string = address
                                    showCopied = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { showCopied = false }
                                }) {
                                    Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                                        .foregroundColor(Color.accentColor)
                                }
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
                                    let url = URL(string: linkedin.hasPrefix("http") ? linkedin : "https://\(linkedin)")!
                                    openURL(url)
                                }) {
                                    Text(linkedin)
                                        .font(.body)
                                        .foregroundColor(Color.accentColor)
                                        .underline()
                                        .lineLimit(nil)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Button(action: {
                                    UIPasteboard.general.string = linkedin
                                    showCopied = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { showCopied = false }
                                }) {
                                    Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                                        .foregroundColor(Color.accentColor)
                                }
                            }
                        }
                        if let website = profile?.website, !website.isEmpty {
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "globe")
                                    .font(.system(size: 22))
                                    .foregroundColor(Color.accentColor)
                                Button(action: {
                                    let url = URL(string: website.hasPrefix("http") ? website : "https://\(website)")!
                                    openURL(url)
                                }) {
                                    Text(website)
                                        .font(.body)
                                        .foregroundColor(Color.accentColor)
                                        .underline()
                                        .lineLimit(nil)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Button(action: {
                                    UIPasteboard.general.string = website
                                    showCopied = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { showCopied = false }
                                }) {
                                    Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                                        .foregroundColor(Color.accentColor)
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
                // Removed skillsSection
                careerFeaturesSectionContent
            }
            .background(Color("appCardBG"))
            .cornerRadius(16)
        }
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