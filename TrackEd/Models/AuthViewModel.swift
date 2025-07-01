import Foundation
import FirebaseAuth
import Combine
import AuthenticationServices
import FirebaseFirestore

class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isCheckingAuth = true
    
    private var handle: AuthStateDidChangeListenerHandle?
    
    init() {
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.user = user
            self?.isCheckingAuth = false
        }
    }
    
    deinit {
        if let handle = handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    func signUp(email: String, password: String, username: String, completion: @escaping (Bool) -> Void) {
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
                        // Save username and email to Firestore
                        let userData: [String: Any] = [
                            "username": username,
                            "email": email
                        ]
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
    
    func signInWithGoogle() {
        // TODO: Implement Google Sign-In using GIDSignIn and FirebaseAuth
        // See: https://firebase.google.com/docs/auth/ios/google-signin
        // 1. Present Google sign-in flow
        // 2. Get ID token and access token
        // 3. Authenticate with Firebase
        print("Google Sign-In tapped (not yet implemented)")
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
