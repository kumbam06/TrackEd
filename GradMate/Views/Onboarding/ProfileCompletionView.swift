import SwiftUI
import Photos
import PhotosUI

struct ProfileCompletionView: View {
    @EnvironmentObject private var profileManager: ProfileManager
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var role = ""
    @State private var bio = ""
    @State private var phone = ""
    @State private var address = ""
    @State private var linkedin = ""
    @State private var website = ""
    @State private var currentCompany = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var showingPhotoPicker = false
    @State private var isLoading = false
    @State private var error: String?
    @State private var currentStep = 0
    
    private let steps = ["Basic Info", "Contact", "Professional", "Photo"]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("appScreenBG").ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progress indicator
                    progressSection
                    
                    // Content
                    ScrollView {
                        VStack(spacing: 32) {
                            headerSection
                            
                            switch currentStep {
                            case 0:
                                basicInfoSection
                            case 1:
                                contactSection
                            case 2:
                                professionalSection
                            case 3:
                                photoSection
                            default:
                                basicInfoSection
                            }
                            
                            Spacer(minLength: 100)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                    
                    // Bottom buttons
                    bottomButtonsSection
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                loadExistingData()
            }
        }
    }
    
    // MARK: - Progress Section
    private var progressSection: some View {
        VStack(spacing: 16) {
            HStack {
                ForEach(0..<steps.count, id: \.self) { index in
                    Circle()
                        .fill(index <= currentStep ? Color("appPrimaryAccent") : Color("appStrokeGray"))
                        .frame(width: 12, height: 12)
                    
                    if index < steps.count - 1 {
                        Rectangle()
                            .fill(index < currentStep ? Color("appPrimaryAccent") : Color("appStrokeGray"))
                            .frame(height: 2)
                    }
                }
            }
            
            Text("Step \(currentStep + 1) of \(steps.count): \(steps[currentStep])")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Color("appTextSecondary"))
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .shadow(color: Color("appPrimaryAccent").opacity(0.15), radius: 8, y: 4)
            
            Text("Complete Your Profile")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color("appTextPrimary"))
            
            Text("Let's set up your professional profile to get the most out of GradMate")
                .font(.body)
                .foregroundColor(Color("appTextSecondary"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Basic Info Section
    private var basicInfoSection: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Full Name")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("appTextPrimary"))
                
                TextField("Enter your full name", text: $name)
                    .textFieldStyle(CustomTextFieldStyle())
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Role/Position")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("appTextPrimary"))
                
                TextField("e.g., Software Engineer, Student, Designer", text: $role)
                    .textFieldStyle(CustomTextFieldStyle())
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Bio (Optional)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("appTextPrimary"))
                
                TextEditor(text: $bio)
                    .frame(minHeight: 80)
                    .padding(12)
                    .background(Color("appStrokeGray"))
                    .cornerRadius(12)
                    .foregroundColor(Color("appTextPrimary"))
            }
        }
    }
    
    // MARK: - Contact Section
    private var contactSection: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Phone Number (Optional)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("appTextPrimary"))
                
                TextField("Enter your phone number", text: $phone)
                    .textFieldStyle(CustomTextFieldStyle())
                    .keyboardType(.phonePad)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Address (Optional)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("appTextPrimary"))
                
                TextField("Enter your address", text: $address)
                    .textFieldStyle(CustomTextFieldStyle())
            }
        }
    }
    
    // MARK: - Professional Section
    private var professionalSection: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Current Company (Optional)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("appTextPrimary"))
                
                TextField("Enter your company name", text: $currentCompany)
                    .textFieldStyle(CustomTextFieldStyle())
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("LinkedIn Profile (Optional)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("appTextPrimary"))
                
                TextField("linkedin.com/in/yourprofile", text: $linkedin)
                    .textFieldStyle(CustomTextFieldStyle())
                    .keyboardType(.URL)
                    .autocapitalization(.none)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Website (Optional)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("appTextPrimary"))
                
                TextField("yourwebsite.com", text: $website)
                    .textFieldStyle(CustomTextFieldStyle())
                    .keyboardType(.URL)
                    .autocapitalization(.none)
            }
        }
    }
    
    // MARK: - Photo Section
    private var photoSection: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                if let photoData = photoData, let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.1), radius: 8, y: 4)
                } else {
                    Circle()
                        .fill(Color("appPrimaryAccent").opacity(0.1))
                        .frame(width: 120, height: 120)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.system(size: 40))
                                .foregroundColor(Color("appPrimaryAccent"))
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 8, y: 4)
                }
                
                Text("Add a professional photo")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("appTextPrimary"))
                
                Text("A professional photo helps others recognize you")
                    .font(.body)
                    .foregroundColor(Color("appTextSecondary"))
                    .multilineTextAlignment(.center)
            }
            
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                HStack(spacing: 8) {
                    Image(systemName: "photo")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Choose Photo")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color("appPrimaryAccent"))
                .cornerRadius(12)
            }
            .onChange(of: selectedPhoto) { oldValue, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self) {
                        photoData = data
                    }
                }
            }
        }
    }
    
    // MARK: - Bottom Buttons Section
    private var bottomButtonsSection: some View {
        VStack(spacing: 12) {
            if let error = error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(Color("appError"))
                    .padding(.horizontal, 20)
            }
            
            HStack(spacing: 16) {
                if currentStep > 0 {
                    Button("Back") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentStep -= 1
                        }
                    }
                    .font(.headline)
                    .foregroundColor(Color("appTextSecondary"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color("appStrokeGray"))
                    .cornerRadius(12)
                }
                
                Button(currentStep == steps.count - 1 ? "Complete Profile" : "Next") {
                    if currentStep == steps.count - 1 {
                        saveProfile()
                    } else {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentStep += 1
                        }
                    }
                }
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color("appPrimaryAccent"))
                .cornerRadius(12)
                .disabled(isLoading)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color("appCardBG"))
    }
    
    // MARK: - Helper Functions
    private func loadExistingData() {
        if let profile = profileManager.currentProfile {
            name = profile.name ?? ""
            role = profile.role ?? ""
            bio = profile.bio ?? ""
            phone = profile.phone ?? ""
            address = profile.address ?? ""
            linkedin = profile.linkedin ?? ""
            website = profile.website ?? ""
            currentCompany = profile.currentCompany ?? ""
            photoData = profile.photoData
        }
    }
    
    private func saveProfile() {
        guard !name.isEmpty else {
            error = "Please enter your full name"
            return
        }
        
        isLoading = true
        error = nil
        
        let profile = Profile(
            name: name,
            email: authViewModel.user?.email ?? "",
            username: authViewModel.user?.displayName ?? "",
            role: role.isEmpty ? "Student" : role,
            bio: bio,
            phone: phone,
            address: address,
            linkedin: linkedin,
            website: website,
            currentCompany: currentCompany,
            photoData: photoData
        )
        
        profileManager.updateProfile(profile) { success in
            DispatchQueue.main.async {
                isLoading = false
                if success {
                    // Profile saved successfully, dismiss the view
                    // The main app will detect the completed profile and show ContentView
                    dismiss()
                } else {
                    error = "Failed to save profile. Please try again."
                }
            }
        }
    }
}

// MARK: - Custom Text Field Style
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.vertical, 16)
            .padding(.horizontal, 14)
            .background(Color("appStrokeGray"))
            .cornerRadius(12)
            .foregroundColor(Color("appTextPrimary"))
    }
}

#Preview {
    ProfileCompletionView()
        .environmentObject(ProfileManager())
        .environmentObject(AuthViewModel())
} 