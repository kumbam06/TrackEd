import Foundation
import FirebaseAuth
import Combine
import AuthenticationServices
import FirebaseFirestore
import GoogleSignIn
import FirebaseCore

class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isCheckingAuth = true
    
    private var handle: AuthStateDidChangeListenerHandle?
    
    init() {
        print("[DEBUG] AuthViewModel.init() - Firebase Auth initialized")
        // handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
        //     print("[DEBUG] AuthViewModel - Auth state changed, user: \(user?.uid ?? "nil")")
        //     self?.user = user
        //     self?.isCheckingAuth = false
        // }
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
    }
    
    func signUp(email: String, password: String, username: String, fullName: String, role: String, dob: Date?, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil
        // Check username uniqueness
        let db = Firestore.firestore()
        db.collection("users").whereField("username", isEqualTo: username).getDocuments { [weak self] snapshot, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.errorMessage = error.localizedDescription
                    completion(false)
                }
                return
            }
            if let docs = snapshot?.documents, !docs.isEmpty {
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.errorMessage = "Username already taken."
                    completion(false)
                }
                return
            }
            // Username is unique, proceed to create user
            Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.isLoading = false
                        self?.errorMessage = error.localizedDescription
                        completion(false)
                    } else if let user = result?.user {
                        // Save profile data to Firestore
                        var userData: [String: Any] = [
                            "username": username,
                            "email": email,
                            "name": fullName,
                            "role": role
                        ]
                        if let dob = dob {
                            userData["dob"] = Timestamp(date: dob)
                        }
                        db.collection("users").document(user.uid).setData(userData) { firestoreError in
                            DispatchQueue.main.async {
                                self?.isLoading = false
                                if let firestoreError = firestoreError {
                                    self?.errorMessage = firestoreError.localizedDescription
                                    completion(false)
                                } else {
                                    self?.user = user
                                    completion(true)
                                }
                            }
                        }
                    } else {
                        self?.isLoading = false
                        self?.errorMessage = "Unknown error."
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
    
    func logout() {
        do {
            try Auth.auth().signOut()
            self.user = nil
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
} 
