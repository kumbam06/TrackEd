import SwiftUI

struct AuthMainStackView: View {
    @Binding var email: String
    @Binding var password: String
    @Binding var isLoading: Bool
    @Binding var error: String?
    @Binding var showPassword: Bool
    @Binding var isInputFocused: Bool
    @Binding var debouncedEmail: String
    @Binding var debouncedPassword: String
    @Binding var navigateToSignup: Bool
    @Binding var showForgotPassword: Bool
    var authViewModel: AuthViewModel
    var onForgotPassword: () -> Void
    var onLogin: () -> Void
    var onGoogleSignIn: () -> Void
    var debounceInput: (String, String) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 32)
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
            LoginCardView(
                email: $email,
                password: $password,
                isLoading: $isLoading,
                error: $error,
                showPassword: $showPassword,
                isInputFocused: $isInputFocused,
                debouncedEmail: $debouncedEmail,
                debouncedPassword: $debouncedPassword,
                navigateToSignup: $navigateToSignup,
                authViewModel: authViewModel,
                onForgotPassword: onForgotPassword,
                onLogin: onLogin,
                onGoogleSignIn: onGoogleSignIn,
                debounceInput: debounceInput
            )
            if isLoading {
                // Loader is now shown globally
            }
        }
    }
} 