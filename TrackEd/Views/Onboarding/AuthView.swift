import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isSignup = false
    @State private var isLoading = false
    @State private var error: String?
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var username = ""
    
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack(spacing: 32) {
                Spacer(minLength: 24)
                ZStack {
                    Circle()
                        .fill(Color(.secondarySystemBackground))
                        .frame(width: 100, height: 100)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(.separator), lineWidth: 1))
                    Image(systemName: "sparkles")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.accentColor)
                        .accessibilityLabel(Text("TrackEd Logo"))
                }
                Text(isSignup ? "Sign Up" : "Log In")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                VStack(spacing: 16) {
                    if isSignup {
                        TextField("Username", text: $username)
                            .autocapitalization(.none)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(16)
                            .accessibilityLabel(Text("Username"))
                    }
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                        .accessibilityLabel(Text("Email"))
                    ZStack(alignment: .trailing) {
                        if showPassword {
                            TextField("Password", text: $password)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(16)
                                .accessibilityLabel(Text("Password"))
                        } else {
                            SecureField("Password", text: $password)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(16)
                                .accessibilityLabel(Text("Password"))
                        }
                        Button(action: { showPassword.toggle() }) {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundColor(.gray)
                        }
                        .padding(.trailing, 12)
                        .accessibilityLabel(Text(showPassword ? "Hide Password" : "Show Password"))
                    }
                    if isSignup {
                        ZStack(alignment: .trailing) {
                            if showConfirmPassword {
                                TextField("Confirm Password", text: $confirmPassword)
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(16)
                                    .accessibilityLabel(Text("Confirm Password"))
                            } else {
                                SecureField("Confirm Password", text: $confirmPassword)
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(16)
                                    .accessibilityLabel(Text("Confirm Password"))
                            }
                            Button(action: { showConfirmPassword.toggle() }) {
                                Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
                                    .foregroundColor(.gray)
                            }
                            .padding(.trailing, 12)
                            .accessibilityLabel(Text(showConfirmPassword ? "Hide Confirm Password" : "Show Confirm Password"))
                        }
                    }
                }
                HStack {
                    Spacer()
                    Button(action: { /* TODO: Implement forgot password */ }) {
                        Text("Forgot password?")
                            .font(.footnote)
                            .foregroundColor(.accentColor)
                    }
                    .accessibilityLabel(Text("Forgot password?"))
                }
                if let error = error ?? authViewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .accessibilityLabel(Text("Error: \(error)"))
                }
                Button(action: {
                    isLoading = true
                    error = nil
                    if isSignup {
                        guard password == confirmPassword else {
                            error = "Passwords do not match."
                            isLoading = false
                            return
                        }
                        guard username.range(of: "^[A-Za-z0-9]{4,}$", options: .regularExpression) != nil else {
                            error = "Username must be at least 4 alphanumeric characters."
                            isLoading = false
                            return
                        }
                        authViewModel.signUp(email: email, password: password, username: username) { success in
                            isLoading = false
                            if !success {
                                error = authViewModel.errorMessage ?? "Sign up failed. Please try again."
                            }
                        }
                    } else {
                        authViewModel.login(email: email, password: password) { success in
                            isLoading = false
                            if !success {
                                error = authViewModel.errorMessage ?? "Login failed. Please check your credentials."
                            }
                        }
                    }
                }) {
                    if isLoading {
                        ProgressView()
                            .accessibilityLabel(Text("Loading"))
                    } else {
                        Text(isSignup ? "Sign Up" : "Log In")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .disabled((isSignup && (username.isEmpty || email.isEmpty || password.isEmpty || password != confirmPassword)) || (!isSignup && (email.isEmpty || password.isEmpty)) || isLoading)
                .padding(.top, 4)
                VStack(spacing: 12) {
                    HStack {
                        Rectangle().frame(height: 1).foregroundColor(.gray.opacity(0.3))
                        Text("or")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Rectangle().frame(height: 1).foregroundColor(.gray.opacity(0.3))
                    }
                    Button(action: {
                        isLoading = true
                        error = nil
                        authViewModel.signInWithGoogle()
                        // Simulate loading for demo
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            isLoading = false
                            error = "Google sign-in not yet implemented."
                        }
                    }) {
                        HStack {
                            Image(systemName: "globe")
                            Text("Sign in with Google")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                    }
                    .accessibilityLabel(Text("Sign in with Google"))
                    SignInWithAppleButton(
                        onRequest: { request in
                            // TODO: Configure Apple sign-in request
                        },
                        onCompletion: { result in
                            isLoading = true
                            error = nil
                            authViewModel.signInWithApple(result: result)
                            // Simulate loading for demo
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                isLoading = false
                                error = "Apple sign-in not yet implemented."
                            }
                        }
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .cornerRadius(12)
                    .padding(.horizontal, 2)
                    .accessibilityLabel(Text("Sign in with Apple"))
                }
                Button(action: { isSignup.toggle(); error = nil; isLoading = false; password = ""; confirmPassword = ""; username = "" }) {
                    Text(isSignup ? "Already have an account? Log In" : "Don't have an account? Sign Up")
                        .font(.footnote)
                        .foregroundColor(.accentColor)
                        .padding(.top, 8)
                }
                .accessibilityLabel(Text(isSignup ? "Switch to Log In" : "Switch to Sign Up"))
                Spacer(minLength: 24)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
        }
        .onTapGesture {
            hideKeyboard()
        }
    }
}

#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif 