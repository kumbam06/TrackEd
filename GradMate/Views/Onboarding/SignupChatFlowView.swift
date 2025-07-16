import SwiftUI

struct SignupChatFlowView: View {
    var onSignupComplete: (() -> Void)?
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
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
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.words)
                        .focused($isInputFocused)
                        .padding(.horizontal, 8)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal, 8)
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal, 8)
                    SecureField("Confirm Password", text: $confirmPassword)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal, 8)
                    if let error = error {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.top, 2)
                    }
                    Button(action: signUp) {
                        if isLoading {
                            ProgressView()
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
                        .fill(Color.white.opacity(0.95))
                        .shadow(color: Color(.black).opacity(0.10), radius: 16, y: 4)
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 18)
                Spacer()
                // Footer
                HStack(spacing: 4) {
                    Text("Already have an account?")
                        .foregroundColor(.secondary)
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
        isLoading = true
        error = nil
        authViewModel.signUp(email: email, password: password, username: "", fullName: name, role: "Student", dob: nil) { success in
            isLoading = false
            if success {
                onSignupComplete?()
            } else {
                error = authViewModel.errorMessage ?? "Signup failed. Please try again."
            }
        }
    }
}

 
