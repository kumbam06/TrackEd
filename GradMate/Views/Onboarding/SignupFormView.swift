import SwiftUI

struct SignupFormView: View {
    var onSignupComplete: (() -> Void)?
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var error: String?
    @FocusState private var isInputFocused: Bool

    var body: some View {
        ZStack {
            Color("appScreenBG").ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer(minLength: 32)
                // App Logo and App Name
                VStack(spacing: 8) {
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 72, height: 72)
                        .shadow(color: Color.accentColor.opacity(0.12), radius: 12, y: 4)
                    Text("GradMate")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Color("appPrimaryAccent"))
                }
                .padding(.bottom, 24)
                // Signup Card
                VStack(spacing: 20) {
                    TextField("Name", text: $name)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 14)
                        .background(Color("appStrokeGray"))
                        .cornerRadius(14)
                        .foregroundColor(Color("appTextPrimary"))
                        .autocapitalization(.words)
                        .focused($isInputFocused)
                        .padding(.horizontal, 8)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 14)
                        .background(Color("appStrokeGray"))
                        .cornerRadius(14)
                        .foregroundColor(Color("appTextPrimary"))
                        .padding(.horizontal, 8)
                    SecureField("Password", text: $password)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 14)
                        .background(Color("appStrokeGray"))
                        .cornerRadius(14)
                        .foregroundColor(Color("appTextPrimary"))
                        .padding(.horizontal, 8)
                    SecureField("Confirm Password", text: $confirmPassword)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 14)
                        .background(Color("appStrokeGray"))
                        .cornerRadius(14)
                        .foregroundColor(Color("appTextPrimary"))
                        .padding(.horizontal, 8)
                    if let error = error {
                        Text(error)
                            .foregroundColor(Color("appError"))
                            .font(.caption)
                            .padding(.top, 2)
                    }
                    Button(action: signUp) {
                        if authViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color.white))
                        } else {
                            Text("Create Account")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(Color("appPrimaryAccent"))
                                .cornerRadius(12)
                        }
                    }
                    .disabled(!formIsValid())
                    .padding(.top, 4)
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color("appCardBG"))
                        .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 4)
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 18)
                Spacer()
                // Footer
                HStack(spacing: 4) {
                    Text("Already have an account?")
                        .foregroundColor(Color("appTextSecondary"))
                    Button(action: { onSignupComplete?() }) {
                        Text("Log In")
                            .fontWeight(.semibold)
                            .foregroundColor(Color("appPrimaryAccent"))
                    }
                }
                .font(.footnote)
                .padding(.bottom, 18)
            }
        }
    }

    private func formIsValid() -> Bool {
        !name.isEmpty && !email.isEmpty && !password.isEmpty && !confirmPassword.isEmpty && password == confirmPassword && password.count >= 6
    }

    private func signUp() {
        guard formIsValid() else { return }
        
        error = nil
        
        // Generate a unique username from email
        let emailComponents = email.components(separatedBy: "@")
        let baseUsername = emailComponents.first ?? "user"
        let username = baseUsername.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: "_", with: "")
        
        authViewModel.signUp(email: email, password: password, username: username, fullName: name, role: "Student", dob: nil) { success in
            if !success {
                error = authViewModel.errorMessage ?? "Signup failed. Please try again."
            }
        }
    }
}

 
