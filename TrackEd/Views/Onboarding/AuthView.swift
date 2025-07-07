import SwiftUI
import AuthenticationServices
import FirebaseAuth

#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif

struct AuthView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showSignup = false
    @State private var navigateToSignup = false
    @State private var isLoading = false
    @State private var error: String?
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var username = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var dob: Date? = nil
    @State private var signupStep: SignupStep = .username
    @FocusState private var isInputFocused: Bool
    @State private var role = ""
    @State private var showForgotPassword = false
    @State private var forgotPasswordEmail = ""
    @State private var forgotPasswordMessage: String? = nil
    @State private var forgotPasswordLoading = false
    @State private var debouncedEmail = ""
    @State private var debouncedPassword = ""
    private let debounceDelay = 0.25
    @State private var debounceWorkItem: DispatchWorkItem? = nil

    enum SignupStep: Int, CaseIterable {
        case username, email, password, confirmPassword, firstName, lastName, role, dob, review
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color(uiColor: .systemGray6), Color(uiColor: .systemGray4)]), startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                VStack(spacing: 0) {
                    Spacer(minLength: 32)
                    // App Logo (always show at top)
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 72, height: 72)
                        .shadow(color: Color.accentColor.opacity(0.12), radius: 12, y: 4)
                        .padding(.bottom, 20)
                    Text("Welcome back!")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .padding(.bottom, 18)
                    // Card
                    VStack(spacing: 24) {
                        VStack(spacing: 18) {
                            HStack {
                                Image(systemName: "envelope")
                                    .foregroundColor(.accentColor)
                                TextField("Email", text: $email)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .focused($isInputFocused)
                                    .accessibilityLabel(Text("Email"))
                                    .onChange(of: email) { newValue in
                                        debounceInput(newValue, for: "email")
                                    }
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(uiColor: .systemGray6))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color(uiColor: .systemGray4), lineWidth: 1.1)
                                )
                            HStack {
                                Image(systemName: "lock")
                                    .foregroundColor(.accentColor)
                                Group {
                                    if showPassword {
                                        TextField("Password", text: $password)
                                            .focused($isInputFocused)
                                            .accessibilityLabel(Text("Password"))
                                            .onChange(of: password) { newValue in
                                                debounceInput(newValue, for: "password")
                                            }
                                    } else {
                                        SecureField("Password", text: $password)
                                            .focused($isInputFocused)
                                            .accessibilityLabel(Text("Password"))
                                            .onChange(of: password) { newValue in
                                                debounceInput(newValue, for: "password")
                                            }
                                    }
                                }
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color(uiColor: .systemGray6))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color(uiColor: .systemGray4), lineWidth: 1.1)
                                    )
                            }
                            HStack {
                                Spacer()
                                Button(action: { showForgotPassword = true }) {
                                    Text("Forgot password?")
                                        .font(.footnote)
                                        .foregroundColor(.accentColor)
                                }
                                .accessibilityLabel(Text("Forgot password?"))
                            }
                            Button(action: {
                                isLoading = true
                                error = nil
                                authViewModel.login(email: debouncedEmail, password: debouncedPassword) { success in
                                    isLoading = false
                                    if !success {
                                        error = authViewModel.errorMessage ?? "Login failed. Please check your credentials."
                                    }
                                }
                            }) {
                                if isLoading {
                                    CustomLoaderOverlay()
                                } else {
                                    Text("Log In")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.accentColor)
                                        .foregroundColor(.white)
                                        .cornerRadius(12)
                                }
                            }
                            .disabled(debouncedEmail.isEmpty || debouncedPassword.isEmpty || isLoading)
                            .padding(.top, 4)
                            if let error = error ?? authViewModel.errorMessage {
                                Text(error)
                                    .foregroundColor(.red)
                                    .font(.caption)
                                    .accessibilityLabel(Text("Error: \(error)"))
                            }
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color(uiColor: .systemGray6))
                                .shadow(color: Color(.black).opacity(0.10), radius: 16, y: 4)
                        )
                        .padding(.horizontal, 24)
                        .padding(.bottom, 18)
                        // Or divider
                        HStack {
                            Rectangle().frame(height: 1).foregroundColor(.gray.opacity(0.3))
                            Text("or")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Rectangle().frame(height: 1).foregroundColor(.gray.opacity(0.3))
                        }
                        .padding(.horizontal, 32)
                        .padding(.vertical, 8)
                        // Google sign in
                        Button(action: {
                            isLoading = true
                            error = nil
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                               let rootVC = windowScene.windows.first?.rootViewController {
                                authViewModel.signInWithGoogle(presentingViewController: rootVC) { success, errMsg in
                                    DispatchQueue.main.async {
                                        isLoading = false
                                        if !success {
                                            error = errMsg ?? "Google sign-in failed."
                                        }
                                    }
                                }
                            } else {
                                isLoading = false
                                error = "Unable to get root view controller."
                            }
                        }) {
                            HStack {
                                Image("GoogleLogo")
                                    .resizable()
                                    .frame(width: 22, height: 22)
                                Text("Sign in with Google")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(uiColor: .systemGray6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(uiColor: .systemGray4), lineWidth: 1.1)
                            )
                            .cornerRadius(12)
                            .shadow(color: Color(.black).opacity(0.04), radius: 4, y: 2)
                        }
                        .padding(.horizontal, 32)
                        .padding(.bottom, 8)
                        Spacer()
                        HStack(spacing: 4) {
                            Text("Don't have an account?")
                                .foregroundColor(.secondary)
                            Button(action: { navigateToSignup = true }) {
                                Text("Sign Up")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .font(.footnote)
                        .padding(.bottom, 18)
                        // NavigationLink for signup
                        NavigationLink(destination: SignupChatFlowView()
                            .environmentObject(authViewModel), isActive: $navigateToSignup) {
                            EmptyView()
                        }
                        .hidden()
                    }
                    if isLoading {
                        CustomLoaderOverlay()
                    }
                }
                .sheet(isPresented: $showForgotPassword) {
                    VStack(spacing: 24) {
                        Text("Reset Password")
                            .font(.title2).fontWeight(.bold)
                            .padding(.top, 24)
                        Text("Enter your email and we'll send you a password reset link.")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                        TextField("Email", text: $forgotPasswordEmail)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(uiColor: .systemGray6))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color(uiColor: .systemGray4), lineWidth: 1.1)
                            )
                            .padding(.horizontal, 16)
                        if let msg = forgotPasswordMessage {
                            Text(msg)
                                .foregroundColor(msg.contains("sent") ? .green : .red)
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
                            } else {
                                Text("Send Reset Link")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.accentColor)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                        }
                        .disabled(forgotPasswordEmail.isEmpty || forgotPasswordLoading)
                        .padding(.horizontal, 16)
                        Spacer()
                    }
                    .presentationDetents([.medium])
                }
            }
            .onTapGesture {
                hideKeyboard()
            }
            .onAppear {
                debouncedEmail = email
                debouncedPassword = password
            }
        }
    }

    // MARK: - Debounce Helper
    func debounceInput(_ value: String, for field: String) {
        debounceWorkItem?.cancel()
        let workItem = DispatchWorkItem {
            if field == "email" {
                debouncedEmail = value
            } else if field == "password" {
                debouncedPassword = value
            }
        }
        debounceWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + debounceDelay, execute: workItem)
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
