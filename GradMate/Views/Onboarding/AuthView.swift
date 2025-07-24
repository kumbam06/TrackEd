import SwiftUI
import AuthenticationServices
import FirebaseAuth
import UIKit

#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif

struct AuthView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var isLoginMode = true
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var error: String?
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var showForgotPassword = false
    @State private var forgotPasswordEmail = ""
    @State private var forgotPasswordMessage: String? = nil
    @State private var forgotPasswordLoading = false
    @FocusState private var isInputFocused: Bool

    var body: some View {
        ZStack {
            Color("appScreenBG").ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer(minLength: 32)
                // Logo & App Name
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
                // Auth Card
                VStack(spacing: 20) {
                    if isLoginMode {
                        Text("Welcome back!")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(Color("appPrimaryAccent"))
                            .padding(.bottom, 4)
                    }
                    if !isLoginMode {
                        TextField("Name", text: $name)
                            .padding(.vertical, 16)
                            .padding(.horizontal, 14)
                            .background(Color("appStrokeGray"))
                            .cornerRadius(14)
                            .foregroundColor(Color("appTextPrimary"))
                            .autocapitalization(.words)
                            .focused($isInputFocused)
                    }
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 14)
                        .background(Color("appStrokeGray"))
                        .cornerRadius(14)
                        .foregroundColor(Color("appTextPrimary"))
                    ZStack(alignment: .trailing) {
                        Group {
                            if showPassword {
                                TextField("Password", text: $password)
                                    .padding(.vertical, 16)
                                    .padding(.horizontal, 14)
                                    .background(Color("appStrokeGray"))
                                    .cornerRadius(14)
                                    .foregroundColor(Color("appTextPrimary"))
                            } else {
                                SecureField("Password", text: $password)
                                    .padding(.vertical, 16)
                                    .padding(.horizontal, 14)
                                    .background(Color("appStrokeGray"))
                                    .cornerRadius(14)
                                    .foregroundColor(Color("appTextPrimary"))
                            }
                        }
                        Button(action: { showPassword.toggle() }) {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundColor(Color("appTextSecondary"))
                                .padding(.trailing, 14)
                        }
                    }
                    if !isLoginMode {
                        ZStack(alignment: .trailing) {
                            Group {
                                if showConfirmPassword {
                                    TextField("Confirm Password", text: $confirmPassword)
                                        .padding(.vertical, 16)
                                        .padding(.horizontal, 14)
                                        .background(Color("appStrokeGray"))
                                        .cornerRadius(14)
                                        .foregroundColor(Color("appTextPrimary"))
                                } else {
                                    SecureField("Confirm Password", text: $confirmPassword)
                                        .padding(.vertical, 16)
                                        .padding(.horizontal, 14)
                                        .background(Color("appStrokeGray"))
                                        .cornerRadius(14)
                                        .foregroundColor(Color("appTextPrimary"))
                                }
                            }
                            Button(action: { showConfirmPassword.toggle() }) {
                                Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
                                    .foregroundColor(Color("appTextSecondary"))
                                    .padding(.trailing, 14)
                            }
                        }
                    }
                    if let error = error {
                        Text(error)
                            .foregroundColor(Color("appError"))
                            .font(.caption)
                            .padding(.top, 2)
                    }
                    Button(action: {
                        isLoading = true
                        error = nil
                        if isLoginMode {
                            authViewModel.login(email: email, password: password) { success in
                                isLoading = false
                                if !success {
                                    error = authViewModel.errorMessage ?? "Login failed. Please try again."
                                }
                            }
                        } else {
                            guard !name.isEmpty, !email.isEmpty, !password.isEmpty, !confirmPassword.isEmpty, password == confirmPassword, password.count >= 6 else {
                                isLoading = false
                                error = "Please fill all fields correctly."
                                return
                            }
                            
                            // Generate a unique username from email
                            let emailComponents = email.components(separatedBy: "@")
                            let baseUsername = emailComponents.first ?? "user"
                            let username = baseUsername.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: "_", with: "")
                            
                            authViewModel.signUp(email: email, password: password, username: username, fullName: name, role: "Student", dob: nil) { success in
                                isLoading = false
                                if !success {
                                    error = authViewModel.errorMessage ?? "Signup failed. Please try again."
                                }
                            }
                        }
                    }) {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text(isLoginMode ? "Log In" : "Sign Up")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(Color("appPrimaryAccent"))
                                .cornerRadius(12)
                        }
                    }
                    .disabled(isLoginMode ? (email.isEmpty || password.isEmpty) : (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty || password != confirmPassword || password.count < 6))
                    .padding(.top, 4)
                    if isLoginMode {
                        Button(action: { showForgotPassword = true }) {
                            Text("Forgot password?")
                                .font(.footnote)
                                .foregroundColor(Color("appPrimaryAccent"))
                        }
                        .padding(.top, 2)
                    }
                    // Divider
                    HStack {
                        Rectangle().frame(height: 1).foregroundColor(.gray.opacity(0.2))
                        Text("or").foregroundColor(.secondary)
                        Rectangle().frame(height: 1).foregroundColor(.gray.opacity(0.2))
                    }
                    // Google Sign-In
                    Button(action: {
                        if let rootVC = UIApplication.shared.connectedScenes
                            .compactMap({ ($0 as? UIWindowScene)?.keyWindow?.rootViewController })
                            .first {
                            authViewModel.signInWithGoogle(presentingViewController: rootVC) { success, error in
                                if !success {
                                    self.error = error ?? "Google sign-in failed."
                                }
                            }
                        }
                    }) {
                        HStack {
                            Image("GoogleLogo")
                                .resizable()
                                .frame(width: 20, height: 20)
                            // Always show 'Sign in with Google' because Google auth is always a login action
                            Text("Sign in with Google")
                                .fontWeight(.semibold)
                                .foregroundColor(Color("appTextPrimary"))
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("appCardBG"))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                    }
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
                // Toggle Footer
                HStack(spacing: 4) {
                    Text(isLoginMode ? "Don't have an account?" : "Already have an account?")
                        .foregroundColor(Color("appTextSecondary"))
                    Button(action: {
                        withAnimation(.spring()) {
                            isLoginMode.toggle()
                            error = nil
                        }
                    }) {
                        Text(isLoginMode ? "Sign Up" : "Log In")
                            .fontWeight(.semibold)
                            .foregroundColor(Color("appPrimaryAccent"))
                    }
                }
                .font(.footnote)
                .padding(.bottom, 18)
            }
            .sheet(isPresented: $showForgotPassword) {
                VStack(spacing: 24) {
                    Text("Reset Password")
                        .font(.title2).fontWeight(.bold)
                        .foregroundColor(Color("appTextPrimary"))
                        .padding(.top, 24)
                    Text("Enter your email and we'll send you a password reset link.")
                        .font(.body)
                        .foregroundColor(Color("appTextSecondary"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                    TextField("Email", text: $forgotPasswordEmail)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color("appStrokeGray"))
                        )
                        .foregroundColor(Color("appTextPrimary"))
                        .padding(.horizontal, 16)
                    if let msg = forgotPasswordMessage {
                        Text(msg)
                            .foregroundColor(msg.contains("sent") ? Color("appSuccess") : Color("appError"))
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }
                    Button(action: {
                        forgotPasswordLoading = true
                        forgotPasswordMessage = nil
                        authViewModel.sendPasswordReset(email: forgotPasswordEmail) { success, err in
                            forgotPasswordLoading = false
                            if success {
                                forgotPasswordMessage = "Reset link sent! Check your email."
                            } else {
                                forgotPasswordMessage = err ?? "Failed to send reset link."
                            }
                        }
                    }) {
                        if forgotPasswordLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color.white))
                        } else {
                            Text("Send Reset Link")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color("appPrimaryAccent"))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                    .disabled(forgotPasswordEmail.isEmpty || forgotPasswordLoading)
                    .padding(.horizontal, 16)
                    Spacer()
                }
                .background(Color("appScreenBG").ignoresSafeArea())
            }
        }
        .onTapGesture { hideKeyboard() }
    }
}

struct LoginFormView: View {
    @Binding var email: String
    @Binding var password: String
    @Binding var debouncedEmail: String
    @Binding var debouncedPassword: String
    @Binding var isLoading: Bool
    @Binding var error: String?
    @Binding var showPassword: Bool
    @FocusState.Binding var isInputFocused: Bool
    var authViewModel: AuthViewModel
    var debounceInput: (String, String) -> Void

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Image(systemName: "envelope")
                    .foregroundColor(Color("appPrimaryAccent"))
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .focused($isInputFocused)
                    .onChange(of: email) { oldValue, newValue in
                        debounceInput(newValue, "email")
                    }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("appStrokeGray"))
            )
            .foregroundColor(Color("appTextPrimary"))
            HStack {
                Image(systemName: "lock")
                    .foregroundColor(Color("appPrimaryAccent"))
                ZStack(alignment: .trailing) {
                    Group {
                        if showPassword {
                            TextField("Password", text: $password)
                                .focused($isInputFocused)
                                .accessibilityLabel(Text("Password"))
                                .onChange(of: password) { oldValue, newValue in
                                    debounceInput(newValue, "password")
                                }
                        } else {
                            SecureField("Password", text: $password)
                                .focused($isInputFocused)
                                .accessibilityLabel(Text("Password"))
                                .onChange(of: password) { oldValue, newValue in
                                    debounceInput(newValue, "password")
                                }
                        }
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color("appStrokeGray"))
                    )
                    .foregroundColor(Color("appTextPrimary"))
                    Button(action: { showPassword.toggle() }) {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .foregroundColor(Color("appTextSecondary"))
                            .padding(.trailing, 16)
                    }
                }
            }
            HStack {
                Spacer()
                Button(action: { /* handled in parent */ }) {
                    Text("Forgot password?")
                        .font(.footnote)
                        .foregroundColor(Color("appPrimaryAccent"))
                }
                .accessibilityLabel(Text("Forgot password?"))
            }
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                error = nil
                authViewModel.login(email: debouncedEmail, password: debouncedPassword) { success in
                    if !success {
                        withAnimation(.spring()) {
                            error = authViewModel.errorMessage ?? "Login failed. Please check your credentials."
                        }
                    }
                }
            }) {
                Text("Log In")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("appPrimaryAccent"))
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(debouncedEmail.isEmpty || debouncedPassword.isEmpty || authViewModel.isLoading)
            .padding(.top, 4)
            if let error = error ?? authViewModel.errorMessage {
                Text(error)
                    .foregroundColor(Color("appError"))
                    .font(.caption)
                    .accessibilityLabel(Text("Error: \(error)"))
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.spring(), value: error)
            }
        }
    }
}

extension AuthViewModel {
    func sendPasswordReset(email: String, completion: @escaping (Bool, String?) -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                completion(false, error.localizedDescription)
            } else {
                completion(true, nil)
            }
        }
    }
}
