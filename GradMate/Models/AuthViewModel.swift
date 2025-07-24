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
        // handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
        //     print("[DEBUG] AuthViewModel - Auth state changed, user: \(user?.uid ?? "nil")")
        //     self?.user = user
        //     self?.isCheckingAuth = false
        // }
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
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
    
    private func testNetworkConnectivity(completion: @escaping (Bool, String?) -> Void) {
        guard isNetworkAvailable() else {
            completion(false, "No network connection available")
            return
        }
        
        // Test basic internet connectivity
        let url = URL(string: "https://www.google.com")!
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(false, "Internet connectivity test failed: \(error.localizedDescription)")
                } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    completion(true, nil)
                } else {
                    completion(false, "Internet connectivity test failed: Invalid response")
                }
            }
        }
        task.resume()
    }
    
    func setupAuthListener() {
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            print("[DEBUG] AuthViewModel - Auth state changed, user: \(user?.uid ?? "nil")")
            self?.user = user
            self?.isCheckingAuth = false
        }
    }
    
    deinit {
        if let handle = handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
        networkMonitor.cancel()
    }
    
    func signUp(email: String, password: String, username: String, fullName: String, role: String, dob: Date?, completion: @escaping (Bool) -> Void) {
        signUpWithRetry(email: email, password: password, username: username, fullName: fullName, role: role, dob: dob, retryCount: 0, completion: completion)
    }
    
    private func signUpWithRetry(email: String, password: String, username: String, fullName: String, role: String, dob: Date?, retryCount: Int, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil
        
        print("[DEBUG] Starting signup process for email: \(email), username: \(username), retry: \(retryCount)")
        
        // Check network connectivity first
        guard isNetworkAvailable() else {
            print("[DEBUG] No network connection available")
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "No internet connection. Please check your network and try again."
                completion(false)
            }
            return
        }
        
        // Test internet connectivity
        testNetworkConnectivity { [weak self] isConnected, errorMessage in
            guard let self = self else { return }
            
            if !isConnected {
                print("[DEBUG] Internet connectivity test failed: \(errorMessage ?? "Unknown error")")
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = errorMessage ?? "Network connectivity issue. Please check your internet connection."
                    completion(false)
                }
                return
            }
            
            print("[DEBUG] Internet connectivity test passed")
            
            // Continue with Firebase operations
            self.performSignup(email: email, password: password, username: username, fullName: fullName, role: role, dob: dob, retryCount: retryCount, completion: completion)
        }
    }
    
    private func performSignup(email: String, password: String, username: String, fullName: String, role: String, dob: Date?, retryCount: Int, completion: @escaping (Bool) -> Void) {
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
        
        // Check username uniqueness with timeout
        let db = Firestore.firestore()
        let usernameQuery = db.collection("users").whereField("username", isEqualTo: username)
        
        // Add timeout for the query
        let timeoutTask = DispatchWorkItem {
            print("[DEBUG] Username check timeout")
            DispatchQueue.main.async {
                self.isLoading = false
                if retryCount < 2 {
                    print("[DEBUG] Retrying username check...")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.signUpWithRetry(email: email, password: password, username: username, fullName: fullName, role: role, dob: dob, retryCount: retryCount + 1, completion: completion)
                    }
                } else {
                    self.errorMessage = "Connection timeout. Please check your internet and try again."
                    completion(false)
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0, execute: timeoutTask)
        
        usernameQuery.getDocuments { [weak self] snapshot, error in
            timeoutTask.cancel() // Cancel timeout if query completes
            
            if let error = error {
                print("[DEBUG] Error checking username: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.isLoading = false
                    // Provide more specific error messages
                    if error.localizedDescription.contains("network") || error.localizedDescription.contains("connection") {
                        if retryCount < 2 {
                            print("[DEBUG] Retrying due to network error...")
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                self?.signUpWithRetry(email: email, password: password, username: username, fullName: fullName, role: role, dob: dob, retryCount: retryCount + 1, completion: completion)
                            }
                        } else {
                            self?.errorMessage = "Network connection issue. Please check your internet connection and try again."
                            completion(false)
                        }
                    } else if error.localizedDescription.contains("permission") {
                        self?.errorMessage = "Database access denied. Please contact support."
                        completion(false)
                    } else {
                        self?.errorMessage = "Unable to verify username. Please try again."
                        completion(false)
                    }
                }
                return
            }
            
            if let docs = snapshot?.documents, !docs.isEmpty {
                print("[DEBUG] Username '\(username)' already taken, generating unique username")
                // Generate a unique username by adding a random number
                let uniqueUsername = "\(username)\(Int.random(in: 1000...9999))"
                print("[DEBUG] Generated unique username: \(uniqueUsername)")
                
                // Recursively call signUp with the new username
                self?.signUpWithRetry(email: email, password: password, username: uniqueUsername, fullName: fullName, role: role, dob: dob, retryCount: retryCount, completion: completion)
                return
            }
            
            print("[DEBUG] Username '\(username)' is unique, proceeding with account creation")
            
            // Username is unique, proceed to create user
            Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("[DEBUG] Firebase Auth error: \(error.localizedDescription)")
                        self?.isLoading = false
                        // Provide more specific error messages
                        if error.localizedDescription.contains("network") || error.localizedDescription.contains("connection") {
                            if retryCount < 2 {
                                print("[DEBUG] Retrying due to network error...")
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    self?.signUpWithRetry(email: email, password: password, username: username, fullName: fullName, role: role, dob: dob, retryCount: retryCount + 1, completion: completion)
                                }
                            } else {
                                self?.errorMessage = "Network connection issue. Please check your internet connection and try again."
                                completion(false)
                            }
                        } else if error.localizedDescription.contains("email already in use") {
                            self?.errorMessage = "An account with this email already exists. Please try logging in instead."
                            completion(false)
                        } else if error.localizedDescription.contains("weak password") {
                            self?.errorMessage = "Password is too weak. Please use a stronger password."
                            completion(false)
                        } else if error.localizedDescription.contains("invalid email") {
                            self?.errorMessage = "Please enter a valid email address."
                            completion(false)
                        } else {
                            self?.errorMessage = error.localizedDescription
                        }
                        completion(false)
                    } else if let user = result?.user {
                        print("[DEBUG] Firebase user created successfully: \(user.uid)")
                        
                        // Save profile data to Firestore
                        var userData: [String: Any] = [
                            "username": username,
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
                        
                        db.collection("users").document(user.uid).setData(userData) { firestoreError in
                            DispatchQueue.main.async {
                                if let firestoreError = firestoreError {
                                    print("[DEBUG] Firestore error: \(firestoreError.localizedDescription)")
                                    self?.errorMessage = "Account created but profile setup failed. Please try again."
                                    completion(false)
                                } else {
                                    print("[DEBUG] User profile saved successfully")
                                    self?.user = user
                                    completion(true)
                                }
                                self?.isLoading = false
                            }
                        }
                    } else {
                        print("[DEBUG] Unknown error in user creation")
                        self?.isLoading = false
                        self?.errorMessage = "Unknown error occurred. Please try again."
                        completion(false)
                    }
                }
            }
        }
    }
    
    func login(email: String, password: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    completion(false)
                } else {
                    self?.user = result?.user
                    completion(true)
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
