import SwiftUI

struct SignupChatFlowView: View {
    var onSignupComplete: (() -> Void)?
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var username = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var dob: Date? = nil
    @State private var role = ""
    @State private var signupStep: SignupStep = .username
    @State private var isLoading = false
    @State private var error: String?
    @FocusState private var isInputFocused: Bool
    @Namespace private var animation
    @State private var showBubbles: [Bool] = Array(repeating: false, count: 10)
    @State private var scrollToBottom = false
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var confirmPasswordError: String? = nil
    @State private var passwordSubmitted = false
    @State private var confirmPasswordSubmitted = false
    @State private var debouncedUsername = ""
    @State private var debouncedEmail = ""
    @State private var debouncedPassword = ""
    @State private var debouncedConfirmPassword = ""
    @State private var debouncedFirstName = ""
    @State private var debouncedLastName = ""
    @State private var debounceWorkItem: DispatchWorkItem?
    private let debounceDelay = 0.25

    enum SignupStep: Int, CaseIterable {
        case username, email, password, confirmPassword, firstName, lastName, role, dob, review
    }

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(gradient: Gradient(colors: [Color(.systemGray6), Color(.systemGray4)]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 0) {
                // Title
                Text("Sign Up")
                    .font(.largeTitle).fontWeight(.bold)
                    .foregroundColor(Color.primary)
                    .padding(.top, 32)
                    .padding(.bottom, 8)
                // App logo only for first conversation
                if signupStep == .username {
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 64, height: 64)
                        .padding(.bottom, 8)
                        .transition(.opacity)
                }
                Spacer(minLength: 8)
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(0...signupStep.rawValue, id: \ .self) { step in
                                if showBubbles[step] {
                                    chatBubbleView(for: SignupStep(rawValue: step)!)
                                        .transition(.move(edge: .bottom).combined(with: .opacity))
                                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showBubbles[step])
                                }
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.bottom, 120) // more space for input bar
                        .onChange(of: signupStep) { _ in
                            withAnimation {
                                showBubbles[signupStep.rawValue] = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                withAnimation { proxy.scrollTo(signupStep.rawValue, anchor: .bottom) }
                            }
                        }
                        .onAppear {
                            for i in 0...signupStep.rawValue { showBubbles[i] = true }
                        }
                    }
                }
                Spacer(minLength: 0)
                // Floating input bar
                if let inputBar = inputBarView() {
                    inputBar
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 22)
                                .fill(Color(UIColor { trait in
                                    trait.userInterfaceStyle == .dark ? UIColor(red:0.13,green:0.14,blue:0.18,alpha:0.95) : UIColor.white.withAlphaComponent(0.95)
                                }))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 22)
                                        .stroke(Color(UIColor { trait in
                                            trait.userInterfaceStyle == .dark ? UIColor(red:0.22,green:0.23,blue:0.28,alpha:1) : UIColor(red:0.88,green:0.88,blue:0.92,alpha:1)
                                        }), lineWidth: 1.2)
                                )
                                .shadow(color: Color(.black).opacity(0.08), radius: 10, y: 2)
                        )
                        .padding(.horizontal, 12)
                        .padding(.bottom, 18)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.easeInOut, value: signupStep)
                }
            }
            if error != nil {
                VStack {
                    Spacer()
                    Text(error ?? "Unknown error")
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(12)
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(12)
                        .shadow(radius: 4)
                        .padding(.bottom, 80)
                }
                .transition(.opacity)
            }
            if isLoading {
                // Loader is now shown globally
            }
        }
    }

    @ViewBuilder
    private func chatBubbleView(for step: SignupStep) -> some View {
        switch step {
        case .username:
            VStack(alignment: .leading, spacing: 10) {
                systemBubble(text: "👋 Hi! Let's get started. What's your preferred username?", isFirst: true)
                if !username.isEmpty {
                    userBubble(text: username, accepted: isUsernameAccepted())
                }
            }.padding(.vertical, 4)
        case .email:
            VStack(alignment: .leading, spacing: 10) {
                systemBubble(text: "What's your email address?")
                if !email.isEmpty {
                    userBubble(text: email, accepted: isEmailAccepted())
                }
            }.padding(.vertical, 4)
        case .password:
            VStack(alignment: .leading, spacing: 10) {
                systemBubble(text: "Create a password.")
                if passwordSubmitted {
                    userBubble(text: String(repeating: "•", count: password.count), accepted: isPasswordAccepted())
                }
            }.padding(.vertical, 4)
        case .confirmPassword:
            VStack(alignment: .leading, spacing: 10) {
                systemBubble(text: "Please confirm your password.")
                if confirmPasswordSubmitted {
                    if confirmPassword == password && !confirmPassword.isEmpty {
                        userBubble(text: String(repeating: "•", count: confirmPassword.count), accepted: true)
                    } else if !confirmPassword.isEmpty {
                        userBubble(text: String(repeating: "•", count: confirmPassword.count), accepted: false, error: "Passwords do not match")
                    }
                }
            }.padding(.vertical, 4)
        case .firstName:
            VStack(alignment: .leading, spacing: 10) {
                systemBubble(text: "What's your first name?")
                if !firstName.isEmpty {
                    userBubble(text: firstName, accepted: true)
                }
            }.padding(.vertical, 4)
        case .lastName:
            VStack(alignment: .leading, spacing: 10) {
                systemBubble(text: "And your last name?")
                if !lastName.isEmpty {
                    userBubble(text: lastName, accepted: true)
                }
            }.padding(.vertical, 4)
        case .role:
            VStack(alignment: .leading, spacing: 10) {
                systemBubble(text: "What is your designation or role? (e.g., Student, Developer, Designer)")
                if !role.isEmpty {
                    userBubble(text: role, accepted: true)
                }
            }.padding(.vertical, 4)
        case .dob:
            VStack(alignment: .leading, spacing: 10) {
                systemBubble(text: "When's your birthday? (optional)")
                if dob != nil {
                    userBubble(text: dob!.formatted(date: .abbreviated, time: .omitted), accepted: true)
                }
            }.padding(.vertical, 4)
        case .review:
            reviewSheet()
        }
    }

    private func systemBubble(text: String, isFirst: Bool = false) -> some View {
        HStack(alignment: .bottom, spacing: 8) {
            Image("AppLogo")
                .resizable()
                .frame(width: 28, height: 28)
                .clipShape(Circle())
                .shadow(radius: 2)
            Text(text)
                .font(.system(size: 19, weight: .regular, design: .rounded))
                .padding(.vertical, 16)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(UIColor { trait in
                            trait.userInterfaceStyle == .dark ? UIColor(red:0.18,green:0.20,blue:0.25,alpha:1) : UIColor(red:0.95,green:0.95,blue:0.97,alpha:1)
                        }))
                        .shadow(color: Color(.systemGray3).opacity(0.13), radius: 6, y: 3)
                )
                .foregroundColor(Color.primary)
                .frame(maxWidth: 260, alignment: .leading)
                .accessibilityLabel("Question: " + text)
            Spacer()
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
    }

    private func userBubble(text: String, accepted: Bool, error: String? = nil) -> some View {
        HStack(alignment: .bottom, spacing: 8) {
            Spacer()
            ZStack(alignment: .bottomTrailing) {
                Text(text)
                    .font(.system(size: 19, weight: .semibold, design: .rounded))
                    .padding(.vertical, 16)
                    .padding(.horizontal, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.accentColor)
                            .shadow(color: Color.accentColor.opacity(0.18), radius: 6, y: 3)
                    )
                    .foregroundColor(.white)
                    .frame(maxWidth: 260, alignment: .trailing)
                    .accessibilityLabel("Your answer: " + text)
                if accepted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .background(Circle().fill(Color.white).frame(width: 18, height: 18))
                        .frame(width: 18, height: 18)
                        .offset(x: 8, y: 8)
                } else if error != nil {
                    Image(systemName: "xmark.octagon.fill")
                        .foregroundColor(.red)
                        .background(Circle().fill(Color.white).frame(width: 18, height: 18))
                        .frame(width: 18, height: 18)
                        .offset(x: 8, y: 8)
                }
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
    }

    private func filterUsername(_ input: String) -> String {
        let allowed = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._"
        return String(input.filter { allowed.contains($0) })
    }

    private func inputBarView() -> AnyView? {
        switch signupStep {
        case .username:
            return AnyView(
                HStack {
                    TextField("Username", text: Binding(
                        get: { username },
                        set: { username = filterUsername($0) }
                    ), onCommit: nextSignupStep)
                        .autocapitalization(.none)
                        .textFieldStyle(.plain)
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(UIColor { trait in
                                    trait.userInterfaceStyle == .dark ? UIColor(red:0.18,green:0.20,blue:0.25,alpha:1) : UIColor(red:0.97,green:0.97,blue:0.99,alpha:1)
                                }))
                        )
                        .foregroundColor(Color.primary)
                        .cornerRadius(16)
                        .focused($isInputFocused)
                        .onAppear { isInputFocused = true }
                    Button(action: nextSignupStep) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(isUsernameAccepted() ? .accentColor : .gray)
                    }
                    .disabled(!isUsernameAccepted())
                }
            )
        case .email:
            return AnyView(
                HStack {
                    TextField("Email", text: $email, onCommit: nextSignupStep)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textFieldStyle(.plain)
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(UIColor { trait in
                                    trait.userInterfaceStyle == .dark ? UIColor(red:0.18,green:0.20,blue:0.25,alpha:1) : UIColor(red:0.97,green:0.97,blue:0.99,alpha:1)
                                }))
                        )
                        .foregroundColor(Color.primary)
                        .cornerRadius(16)
                        .focused($isInputFocused)
                        .onAppear { isInputFocused = true }
                    Button(action: nextSignupStep) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(isEmailAccepted() ? .accentColor : .gray)
                    }
                    .disabled(!isEmailAccepted())
                }
            )
        case .password:
            return AnyView(
                HStack {
                    Group {
                        if showPassword {
                            TextField("Password", text: $password, onCommit: nextSignupStep)
                        } else {
                            SecureField("Password", text: $password, onCommit: nextSignupStep)
                        }
                    }
                    .textFieldStyle(.plain)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(UIColor { trait in
                                trait.userInterfaceStyle == .dark ? UIColor(red:0.18,green:0.20,blue:0.25,alpha:1) : UIColor(red:0.97,green:0.97,blue:0.99,alpha:1)
                            }))
                    )
                    .foregroundColor(Color.primary)
                    .cornerRadius(16)
                    .focused($isInputFocused)
                    .onAppear { isInputFocused = true }
                    Button(action: { showPassword.toggle() }) {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .foregroundColor(.gray)
                    }
                    .padding(.trailing, 8)
                    Button(action: {
                        if isPasswordAccepted() { nextSignupStep() }
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(isPasswordAccepted() ? .accentColor : .gray)
                    }
                    .disabled(!isPasswordAccepted())
                }
            )
        case .confirmPassword:
            return AnyView(
                HStack {
                    Group {
                        if showConfirmPassword {
                            TextField("Confirm Password", text: $confirmPassword, onCommit: nextSignupStep)
                        } else {
                            SecureField("Confirm Password", text: $confirmPassword, onCommit: nextSignupStep)
                        }
                    }
                    .textFieldStyle(.plain)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(UIColor { trait in
                                trait.userInterfaceStyle == .dark ? UIColor(red:0.18,green:0.20,blue:0.25,alpha:1) : UIColor(red:0.97,green:0.97,blue:0.99,alpha:1)
                            }))
                    )
                    .foregroundColor(Color.primary)
                    .cornerRadius(16)
                    .focused($isInputFocused)
                    .onAppear { isInputFocused = true }
                    Button(action: { showConfirmPassword.toggle() }) {
                        Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
                            .foregroundColor(.gray)
                    }
                    .padding(.trailing, 8)
                    Button(action: {
                        if confirmPassword == password && !confirmPassword.isEmpty {
                            nextSignupStep()
                        } else {
                            confirmPasswordError = "Passwords do not match"
                        }
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor((confirmPassword == password && !confirmPassword.isEmpty) ? .accentColor : .gray)
                    }
                    .disabled(!(confirmPassword == password && !confirmPassword.isEmpty))
                }
            )
        case .firstName:
            return AnyView(
                HStack {
                    TextField("First Name", text: $firstName, onCommit: nextSignupStep)
                        .textFieldStyle(.plain)
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(UIColor { trait in
                                    trait.userInterfaceStyle == .dark ? UIColor(red:0.18,green:0.20,blue:0.25,alpha:1) : UIColor(red:0.97,green:0.97,blue:0.99,alpha:1)
                                }))
                        )
                        .foregroundColor(Color.primary)
                        .cornerRadius(16)
                        .focused($isInputFocused)
                        .onAppear { isInputFocused = true }
                    Button(action: nextSignupStep) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(firstName.isEmpty ? .gray : .accentColor)
                    }
                    .disabled(firstName.isEmpty)
                }
            )
        case .lastName:
            return AnyView(
                HStack {
                    TextField("Last Name", text: $lastName, onCommit: nextSignupStep)
                        .textFieldStyle(.plain)
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(UIColor { trait in
                                    trait.userInterfaceStyle == .dark ? UIColor(red:0.18,green:0.20,blue:0.25,alpha:1) : UIColor(red:0.97,green:0.97,blue:0.99,alpha:1)
                                }))
                        )
                        .foregroundColor(Color.primary)
                        .cornerRadius(16)
                        .focused($isInputFocused)
                        .onAppear { isInputFocused = true }
                    Button(action: nextSignupStep) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(lastName.isEmpty ? .gray : .accentColor)
                    }
                    .disabled(lastName.isEmpty)
                }
            )
        case .role:
            return AnyView(
                HStack {
                    TextField("Role / Designation", text: $role, onCommit: nextSignupStep)
                        .textFieldStyle(.plain)
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(UIColor { trait in
                                    trait.userInterfaceStyle == .dark ? UIColor(red:0.18,green:0.20,blue:0.25,alpha:1) : UIColor(red:0.97,green:0.97,blue:0.99,alpha:1)
                                }))
                        )
                        .foregroundColor(Color.primary)
                        .cornerRadius(16)
                        .focused($isInputFocused)
                        .onAppear { isInputFocused = true }
                    Button(action: nextSignupStep) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(role.isEmpty ? .gray : .accentColor)
                    }
                    .disabled(role.isEmpty)
                }
            )
        case .dob:
            return AnyView(
                HStack {
                    DatePicker(
                        "Birthday",
                        selection: Binding(
                            get: { dob ?? Date() },
                            set: { dob = $0 }
                        ),
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(UIColor { trait in
                                trait.userInterfaceStyle == .dark ? UIColor(red:0.18,green:0.20,blue:0.25,alpha:1) : UIColor(red:0.97,green:0.97,blue:0.99,alpha:1)
                            }))
                    )
                    .foregroundColor(Color.primary)
                    .cornerRadius(16)
                    Button("Next", action: nextSignupStep)
                        .buttonStyle(.borderedProminent)
                }
            )
        case .review:
            return nil
        }
    }

    private func reviewSheet() -> some View {
        VStack(spacing: 20) {
            Text("Review your details")
                .font(.title2).fontWeight(.bold)
                .padding(.top, 8)
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Image(systemName: "person.crop.circle")
                        .foregroundColor(.accentColor)
                    Text("Username: ")
                        .fontWeight(.semibold)
                    Text(username)
                }
                HStack {
                    Image(systemName: "envelope")
                        .foregroundColor(.accentColor)
                    Text("Email: ")
                        .fontWeight(.semibold)
                    Text(email)
                }
                HStack {
                    Image(systemName: "person")
                        .foregroundColor(.accentColor)
                    Text("First Name: ")
                        .fontWeight(.semibold)
                    Text(firstName)
                }
                HStack {
                    Image(systemName: "person")
                        .foregroundColor(.accentColor)
                    Text("Last Name: ")
                        .fontWeight(.semibold)
                    Text(lastName)
                }
                HStack {
                    Image(systemName: "briefcase")
                        .foregroundColor(.accentColor)
                    Text("Role: ")
                        .fontWeight(.semibold)
                    Text(role)
                }
                if let dob = dob {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.accentColor)
                        Text("DOB: ")
                            .fontWeight(.semibold)
                        Text(dob.formatted(date: .abbreviated, time: .omitted))
                    }
                }
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(UIColor { trait in
                        trait.userInterfaceStyle == .dark ? UIColor(red:0.18,green:0.20,blue:0.25,alpha:1) : UIColor(red:0.97,green:0.97,blue:0.99,alpha:1)
                    }))
                    .shadow(color: Color(.black).opacity(0.06), radius: 8, y: 2)
            )
            Button(action: completeSignup) {
                if isLoading {
                    ProgressView()
                } else {
                    Text("Sign Up")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .disabled(isLoading)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(UIColor { trait in
                    trait.userInterfaceStyle == .dark ? UIColor(red:0.13,green:0.14,blue:0.18,alpha:0.98) : UIColor.white.withAlphaComponent(0.98)
                }))
                .shadow(color: Color(.black).opacity(0.10), radius: 16, y: 4)
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
    }

    private func nextSignupStep() {
        switch signupStep {
        case .username:
            guard isUsernameAccepted() else {
                error = "Username must be at least 4 characters, no spaces, and only . or _ allowed."
                return
            }
            signupStep = .email
        case .email:
            guard isEmailAccepted() else {
                error = "Please enter a valid email address."
                return
            }
            signupStep = .password
        case .password:
            guard isPasswordAccepted() else {
                error = "Password must be at least 6 characters."
                return
            }
            passwordSubmitted = true
            signupStep = .confirmPassword
        case .confirmPassword:
            guard confirmPassword == password && !confirmPassword.isEmpty else {
                confirmPasswordError = "Passwords do not match"
                error = "Passwords do not match."
                return
            }
            confirmPasswordSubmitted = true
            signupStep = .firstName
        case .firstName:
            guard !firstName.isEmpty else {
                error = "First name is required."
                return
            }
            signupStep = .lastName
        case .lastName:
            guard !lastName.isEmpty else {
                error = "Last name is required."
                return
            }
            signupStep = .role
        case .role:
            guard !role.isEmpty else {
                error = "Role/Designation is required."
                return
            }
            signupStep = .dob
        case .dob:
            signupStep = .review
        case .review:
            break
        }
        error = nil
    }

    private func completeSignup() {
        isLoading = true
        error = nil
        let fullName = firstName + (lastName.isEmpty ? "" : " " + lastName)
        authViewModel.signUp(email: email, password: password, username: username, fullName: fullName, role: role, dob: dob) { success in
            isLoading = false
            if success {
                onSignupComplete?()
            } else {
                error = authViewModel.errorMessage ?? "Sign up failed. Please try again."
            }
        }
    }

    private func isUsernameAccepted() -> Bool { username.range(of: "^[A-Za-z0-9._]{4,}$", options: .regularExpression) != nil }
    private func isEmailAccepted() -> Bool { email.contains("@") && email.contains(".") }
    private func isPasswordAccepted() -> Bool { password.count >= 6 }

    private func debounceInput(_ value: String, for field: String) {
        debounceWorkItem?.cancel()
        let workItem = DispatchWorkItem {
            DispatchQueue.main.async {
                switch field {
                case "username": debouncedUsername = value
                case "email": debouncedEmail = value
                case "password": debouncedPassword = value
                case "confirmPassword": debouncedConfirmPassword = value
                case "firstName": debouncedFirstName = value
                case "lastName": debouncedLastName = value
                default: break
                }
            }
        }
        debounceWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + debounceDelay, execute: workItem)
    }
}

 
