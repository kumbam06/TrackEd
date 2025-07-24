import Foundation
import FirebaseAuth
import Combine
import AuthenticationServices
import FirebaseFirestore
import GoogleSignIn
import FirebaseCore
import Network

class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isCheckingAuth = true
    
    private var handle: AuthStateDidChangeListenerHandle?
    private let networkMonitor = NWPathMonitor()
    private let networkQueue = DispatchQueue(label: "NetworkMonitor")
    
    init() {
        print("[DEBUG] AuthViewModel.init() - Firebase Auth initialized")
        setupNetworkMonitoring()
        // Setup auth listener immediately
        setupAuthListener()
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                if path.status == .satisfied {
                    print("[DEBUG] Network connection available")
                } else {
                    print("[DEBUG] Network connection unavailable")
                }
            }
        }
        networkMonitor.start(queue: networkQueue)
    }
    
    private func isNetworkAvailable() -> Bool {
        return networkMonitor.currentPath.status == .satisfied
    }
    
    func setupAuthListener() {
        print("[DEBUG] Setting up auth listener")
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            print("[DEBUG] AuthViewModel - Auth state changed, user: \(user?.uid ?? "nil")")
            DispatchQueue.main.async {
                self?.user = user
                self?.isCheckingAuth = false
            }
        }
    }
    
    deinit {
        if let handle = handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
        networkMonitor.cancel()
    }
    
    func signUp(email: String, password: String, username: String, fullName: String, role: String, dob: Date?, completion: @escaping (Bool) -> Void) {
        print("[DEBUG] Starting signup process for email: \(email), username: \(username)")
        
        isLoading = true
        errorMessage = nil
        
        // Check network connectivity
        guard isNetworkAvailable() else {
            print("[DEBUG] No network connection available")
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "No internet connection. Please check your network and try again."
                completion(false)
            }
            return
        }
        
        // Check if Firebase is properly configured
        guard FirebaseApp.app() != nil else {
            print("[DEBUG] Firebase not configured")
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "App configuration error. Please restart the app."
                completion(false)
            }
            return
        }
        
        // Generate unique username if needed
        let finalUsername = username.isEmpty ? generateUsernameFromEmail(email) : username
        
        print("[DEBUG] Using username: \(finalUsername)")
        
        // Create user account directly
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let error = error {
                    print("[DEBUG] Firebase Auth error: \(error.localizedDescription)")
                    self.isLoading = false
                    
                    // Provide specific error messages
                    if error.localizedDescription.contains("email already in use") {
                        self.errorMessage = "An account with this email already exists. Please try logging in instead."
                    } else if error.localizedDescription.contains("weak password") {
                        self.errorMessage = "Password is too weak. Please use a stronger password."
                    } else if error.localizedDescription.contains("invalid email") {
                        self.errorMessage = "Please enter a valid email address."
                    } else if error.localizedDescription.contains("network") || error.localizedDescription.contains("connection") {
                        self.errorMessage = "Network connection issue. Please check your internet connection and try again."
                    } else {
                        self.errorMessage = "Signup failed: \(error.localizedDescription)"
                    }
                    completion(false)
                    return
                }
                
                guard let user = result?.user else {
                    print("[DEBUG] No user returned from Firebase Auth")
                    self.isLoading = false
                    self.errorMessage = "Account creation failed. Please try again."
                    completion(false)
                    return
                }
                
                print("[DEBUG] Firebase user created successfully: \(user.uid)")
                
                // Save profile data to Firestore
                var userData: [String: Any] = [
                    "username": finalUsername,
                    "email": email,
                    "name": fullName,
                    "role": role,
                    "createdAt": FieldValue.serverTimestamp(),
                    "lastSignIn": FieldValue.serverTimestamp()
                ]
                
                if let dob = dob {
                    userData["dob"] = Timestamp(date: dob)
                }
                
                print("[DEBUG] Saving user data to Firestore: \(userData)")
                
                let db = Firestore.firestore()
                db.collection("users").document(user.uid).setData(userData) { firestoreError in
                    DispatchQueue.main.async {
                        if let firestoreError = firestoreError {
                            print("[DEBUG] Firestore error: \(firestoreError.localizedDescription)")
                            self.isLoading = false
                            self.errorMessage = "Account created but profile setup failed. Please try again."
                            completion(false)
                        } else {
                            print("[DEBUG] User profile saved successfully")
                            self.user = user
                            self.isLoading = false
                            completion(true)
                        }
                    }
                }
            }
        }
    }
    
    private func generateUsernameFromEmail(_ email: String) -> String {
        let username = email.components(separatedBy: "@").first ?? "user"
        let cleanUsername = username.replacingOccurrences(of: "[^a-zA-Z0-9]", with: "", options: .regularExpression)
        let randomSuffix = Int.random(in: 1000...9999)
        return "\(cleanUsername)\(randomSuffix)"
    }
    
    func login(email: String, password: String, completion: @escaping (Bool) -> Void) {
        print("[DEBUG] Starting login process for email: \(email)")
        
        isLoading = true
        errorMessage = nil
        
        // Check network connectivity
        guard isNetworkAvailable() else {
            print("[DEBUG] No network connection available for login")
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "No internet connection. Please check your network and try again."
                completion(false)
            }
            return
        }
        
        // Check if Firebase is properly configured
        guard FirebaseApp.app() != nil else {
            print("[DEBUG] Firebase not configured for login")
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "App configuration error. Please restart the app."
                completion(false)
            }
            return
        }
        
        print("[DEBUG] Attempting Firebase sign in")
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                self.isLoading = false
                
                if let error = error {
                    print("[DEBUG] Login error: \(error.localizedDescription)")
                    self.errorMessage = error.localizedDescription
                    completion(false)
                } else if let user = result?.user {
                    print("[DEBUG] Login successful for user: \(user.uid)")
                    self.user = user
                    completion(true)
                } else {
                    print("[DEBUG] Login failed - no user returned")
                    self.errorMessage = "Login failed. Please try again."
                    completion(false)
                }
            }
        }
    }
    
    func signInWithGoogle(presentingViewController: UIViewController? = nil, completion: ((Bool, String?) -> Void)? = nil) {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            completion?(false, "Missing Google client ID")
            return
        }
        let presentingVC: UIViewController
        if let presentingViewController = presentingViewController {
            presentingVC = presentingViewController
        } else {
            guard let rootVC = UIApplication.shared.connectedScenes
                .compactMap({ ($0 as? UIWindowScene)?.keyWindow?.rootViewController })
                .first else {
                completion?(false, "No presenting view controller")
                return
            }
            presentingVC = rootVC
        }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        GIDSignIn.sharedInstance.signIn(withPresenting: presentingVC) { [weak self] result, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.errorMessage = error.localizedDescription
                    completion?(false, error.localizedDescription)
                }
                return
            }
            guard let user = result?.user else {
                DispatchQueue.main.async {
                    self?.errorMessage = "Google authentication failed."
                    completion?(false, "Google authentication failed.")
                }
                return
            }
            let idToken: String?
            let accessToken: String?
            if let idTokenValue = (user.idToken as AnyObject?)?.tokenString as? String,
               let accessTokenValue = (user.accessToken as AnyObject?)?.tokenString as? String,
               !idTokenValue.isEmpty, !accessTokenValue.isEmpty {
                idToken = idTokenValue
                accessToken = accessTokenValue
            } else {
                DispatchQueue.main.async {
                    self?.errorMessage = "Google authentication failed (missing token)."
                    completion?(false, "Google authentication failed (missing token).")
                }
                return
            }
            let credential = GoogleAuthProvider.credential(withIDToken: idToken!, accessToken: accessToken!)
            Auth.auth().signIn(with: credential) { [weak self] result, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                        completion?(false, error.localizedDescription)
                    } else if let user = result?.user {
                        // Save or update user profile data to Firestore
                        let db = Firestore.firestore()
                        let googleUser = result?.user
                        
                        // Get user data from Google
                        let email = googleUser?.email ?? ""
                        let displayName = googleUser?.displayName ?? ""
                        let photoURL = googleUser?.photoURL?.absoluteString
                        
                        // Create or update user document in Firestore
                        var userData: [String: Any] = [
                            "email": email,
                            "name": displayName,
                            "role": "Student", // Default role
                            "createdAt": FieldValue.serverTimestamp(),
                            "lastSignIn": FieldValue.serverTimestamp()
                        ]
                        
                        if let photoURL = photoURL {
                            userData["photoURL"] = photoURL
                        }
                        
                        // Check if user already exists
                        db.collection("users").document(user.uid).getDocument { document, error in
                            if let document = document, document.exists {
                                // User exists, just update last sign in
                                db.collection("users").document(user.uid).updateData([
                                    "lastSignIn": FieldValue.serverTimestamp()
                                ]) { error in
                                    DispatchQueue.main.async {
                                        if let error = error {
                                            print("[DEBUG] Error updating user: \(error.localizedDescription)")
                                        }
                                        self?.user = user
                                        completion?(true, nil)
                                    }
                                }
                            } else {
                                // New user, create profile
                                db.collection("users").document(user.uid).setData(userData) { error in
                                    DispatchQueue.main.async {
                                        if let error = error {
                                            print("[DEBUG] Error creating user profile: \(error.localizedDescription)")
                                        }
                                        self?.user = user
                                        completion?(true, nil)
                                    }
                                }
                            }
                        }
                    } else {
                        self?.errorMessage = "Unknown error."
                        completion?(false, "Unknown error.")
                    }
                }
            }
        }
    }
    
    func signInWithApple(result: Result<ASAuthorization, Error>) {
        // TODO: Implement Apple Sign-In using ASAuthorizationAppleIDCredential and FirebaseAuth
        // See: https://firebase.google.com/docs/auth/ios/apple
        // 1. Handle Apple sign-in result
        // 2. Get credential and authenticate with Firebase
        print("Apple Sign-In tapped (not yet implemented)")
    }
    
    @MainActor
    func signOut() async {
        isLoading = true
        errorMessage = nil
        do {
            try Auth.auth().signOut()
            self.user = nil
            // Optionally clear any other user-related state here
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
} 
