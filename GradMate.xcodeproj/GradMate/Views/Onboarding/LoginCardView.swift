import SwiftUI

struct LoginCardView: View {
    @Binding var email: String
    @Binding var password: String
    @Binding var isLoading: Bool
    @Binding var error: String?
    @Binding var showPassword: Bool
    @Binding var isInputFocused: Bool
    @Binding var debouncedEmail: String
    @Binding var debouncedPassword: String
    @Binding var navigateToSignup: Bool
    var authViewModel: AuthViewModel
    var onForgotPassword: () -> Void
    var onLogin: () -> Void
    var onGoogleSignIn: () -> Void
    var debounceInput: (String, String) -> Void

    var body: some View {
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
                            debounceInput(newValue, "email")
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
                                    debounceInput(newValue, "password")
                                }
                        } else {
                            SecureField("Password", text: $password)
                                .focused($isInputFocused)
                                .accessibilityLabel(Text("Password"))
                                .onChange(of: password) { newValue in
                                    debounceInput(newValue, "password")
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
                    Button(action: onForgotPassword) {
                        Text("Forgot password?")
                            .font(.footnote)
                            .foregroundColor(.accentColor)
                    }
                    .accessibilityLabel(Text("Forgot password?"))
                }
                Button(action: onLogin) {
                    AnyView(
                        Text("Log In")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    )
                }
                .disabled(debouncedEmail.isEmpty || debouncedPassword.isEmpty || isLoading)
                .padding(.top, 4)
                if let error = error ?? authViewModel.errorMessage {
                    AnyView(
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .accessibilityLabel(Text("Error: \(error)"))
                    )
                } else {
                    AnyView(EmptyView())
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
            Button(action: onGoogleSignIn) {
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
            NavigationLink(destination: SignupFormView()
                .environmentObject(authViewModel), isActive: $navigateToSignup) {
                EmptyView()
            }
            .hidden()
        }
    }
} 