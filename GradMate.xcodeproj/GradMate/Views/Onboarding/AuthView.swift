import SwiftUI

struct AuthView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var error: String?
    @State private var showForgotPassword = false
    @State private var navigateToSignup = false
    @State private var forgotPasswordEmail = ""
    @State private var forgotPasswordMessage: String?
    @State private var forgotPasswordLoading = false
    @FocusState private var isInputFocused: Bool
    
    // MARK: - Section Views

    private var logoSection: some View {
        Image("AppLogo")
            .resizable()
            .scaledToFit()
            .frame(width: 72, height: 72)
            .shadow(color: Color.accentColor.opacity(0.12), radius: 12, y: 4)
            .padding(.bottom, 20)
    }
    
    private var welcomeSection: some View {
        Text("Welcome back!")
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundColor(.primary)
            .padding(.bottom, 18)
    }
    
    private var loginFormSection: some View {
        loginCard
    }
    
    private var signUpSection: some View {
        VStack(spacing: 0) {
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
            NavigationLink(destination: SignupChatFlowView()
                .environmentObject(authViewModel), isActive: $navigateToSignup) {
                EmptyView()
            }
            .hidden()
        }
    }

    private var mainStack: some View {
        let topSpacer: AnyView = AnyView(Spacer(minLength: 32))
        let logo: AnyView = AnyView(logoSection)
        let welcome: AnyView = AnyView(welcomeSection)
        let login: AnyView = AnyView(loginFormSection)
        let loading: AnyView = isLoading ? AnyView(CustomLoaderOverlay()) : AnyView(EmptyView())
        let bottomSpacer: AnyView = AnyView(Spacer())
        let signup: AnyView = AnyView(signUpSection)

        return VStack(spacing: 0) {
            topSpacer
            logo
            welcome
            login
            loading
            bottomSpacer
            signup
        }
    }

    // MARK: - Main Body

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color(uiColor: .systemGray6), Color(uiColor: .systemGray4)]), startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                AuthMainStackView(
                    email: $email,
                    password: $password,
                    isLoading: $isLoading,
                    error: $error,
                    showPassword: $showPassword,
                    isInputFocused: $isInputFocused,
                    debouncedEmail: $debouncedEmail,
                    debouncedPassword: $debouncedPassword,
                    navigateToSignup: $navigateToSignup,
                    showForgotPassword: $showForgotPassword,
                    authViewModel: authViewModel,
                    onForgotPassword: { showForgotPassword = true },
                    onLogin: {
                        isLoading = true
                        error = nil
                        authViewModel.login(email: debouncedEmail, password: debouncedPassword) { success in
                            isLoading = false
                            if !success {
                                error = authViewModel.errorMessage ?? "Login failed. Please check your credentials."
                            }
                        }
                    },
                    onGoogleSignIn: {
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
                    },
                    debounceInput: debounceInput
                )
            }
            .sheet(isPresented: $showForgotPassword) {
                forgotPasswordSheet
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

    private var emailField: some View {
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
    }

    private var passwordField: some View {
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
    }

    private var forgotPasswordButton: some View {
        HStack {
            Spacer()
            Button(action: { showForgotPassword = true }) {
                Text("Forgot password?")
                    .font(.footnote)
                    .foregroundColor(.accentColor)
            }
            .accessibilityLabel(Text("Forgot password?"))
        }
    }

    private var loginButton: some View {
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
                // Loader is now shown globally
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
    }

    private var errorMessageView: some View {
        Group {
            if let error = error ?? authViewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .accessibilityLabel(Text("Error: \(error)"))
            }
        }
    }

    private var divider: some View {
        HStack {
            Rectangle().frame(height: 1).foregroundColor(.gray.opacity(0.3))
            Text("or")
                .font(.caption)
                .foregroundColor(.gray)
            Rectangle().frame(height: 1).foregroundColor(.gray.opacity(0.3))
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 8)
    }

    private var googleSignInButton: some View {
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
                Text("G")
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
    }

    private var signUpSection: some View {
        VStack(spacing: 0) {
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
            NavigationLink(destination: SignupChatFlowView()
                .environmentObject(authViewModel), isActive: $navigateToSignup) {
                EmptyView()
            }
            .hidden()
        }
    }

    private var loginCard: some View {
        VStack(spacing: 24) {
            VStack(spacing: 18) {
                emailField
                passwordField
                forgotPasswordButton
                loginButton
                errorMessageView
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(uiColor: .systemGray6))
                    .shadow(color: Color(.black).opacity(0.10), radius: 16, y: 4)
            )
            .padding(.horizontal, 24)
            .padding(.bottom, 18)
            divider
            googleSignInButton
            Spacer()
            signUpSection
        }
    }

    private var forgotPasswordSheet: some View {
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

struct EmailField: View {
    @Binding var email: String
    @FocusState.Binding var isInputFocused: Bool
    var onChange: (String) -> Void
    var body: some View {
        HStack {
            Image(systemName: "envelope")
                .foregroundColor(.accentColor)
            TextField("Email", text: $email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .focused($isInputFocused)
                .accessibilityLabel(Text("Email"))
                .onChange(of: email, perform: onChange)
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
}

struct PasswordField: View {
    @Binding var password: String
    @FocusState.Binding var isInputFocused: Bool
    var showPassword: Bool
    var onChange: (String) -> Void
    var body: some View {
        HStack {
            Image(systemName: "lock")
                .foregroundColor(.accentColor)
            Group {
                if showPassword {
                    TextField("Password", text: $password)
                        .focused($isInputFocused)
                        .accessibilityLabel(Text("Password"))
                        .onChange(of: password, perform: onChange)
                } else {
                    SecureField("Password", text: $password)
                        .focused($isInputFocused)
                        .accessibilityLabel(Text("Password"))
                        .onChange(of: password, perform: onChange)
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
    }
}

struct GoogleSignInButton: View {
    var isLoading: Bool
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack {
                Text("G")
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
        .disabled(isLoading)
    }
}

struct ErrorMessageView: View {
    var error: String?
    var body: some View {
        if let error = error {
            Text(error)
                .foregroundColor(.red)
                .font(.caption)
                .accessibilityLabel(Text("Error: \(error)"))
        }
    }
}

extension AuthView {
    @ViewBuilder
    private func signUpSection() -> some View {
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
        NavigationLink(destination: SignupChatFlowView()
            .environmentObject(authViewModel), isActive: $navigateToSignup) {
            EmptyView()
        }
        .hidden()
    }
} 