import Foundation
import Combine
import GoogleSignIn
import UIKit
import sharedKit

/// Google Sign-In Manager integrated with Kotlin Multiplatform shared authentication
class GoogleSignInManager: ObservableObject {
    
    static let shared = GoogleSignInManager()
    
    @Published var isSignedIn = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let authRepository: AuthRepository
    private let googleSignInProvider: IOSGoogleSignInProvider
    
    private init() {
        // Initialize shared KMP components
        self.googleSignInProvider = IOSGoogleSignInProvider()
        
        // Initialize with your KMP shared components
        let tokenStorage = IOSTokenStorage()
        
        // Don't initialize Koin here - it's done in LandingPage
        // SharedModuleInitializerKt.doInitKoin() // Removed to prevent duplicate initialization
        let apiClient = ApiClient()
        
        self.authRepository = AuthRepository(
            httpClient: apiClient.httpClient,
            googleSignInProvider: googleSignInProvider,
            tokenStorage: tokenStorage
        )
        
        checkSignInStatus()
    }
    
    private func checkSignInStatus() {
        authRepository.checkExistingAuth { [weak self] authState, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    self?.isSignedIn = false
                } else if let authState = authState {
                    switch authState {
                    case is AuthState.Success:
                        self?.isSignedIn = true
                    case is AuthState.Error:
                        self?.isSignedIn = false
                        if let errorState = authState as? AuthState.Error {
                            self?.errorMessage = errorState.message
                        }
                    default:
                        self?.isSignedIn = false
                    }
                }
            }
        }
    }
    
    func signIn() {
        print("🔥 GoogleSignInManager.signIn() called")
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let presentingViewController = windowScene.windows.first?.rootViewController else {
            let error = "No presenting view controller found"
            print("❌ Error: \(error)")
            errorMessage = error
            return
        }
        
        print("✅ Found presenting view controller: \(presentingViewController)")
        
        isLoading = true
        errorMessage = nil
        print("🔄 Starting Google Sign-In process...")
        print("🔧 GIDSignIn configuration: \(GIDSignIn.sharedInstance.configuration?.clientID ?? "NOT CONFIGURED")")
        
        // Use Google Sign-In SDK
        print("🚀 Calling GIDSignIn.sharedInstance.signIn...")
        GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { [weak self] result, error in
            print("📲 Google Sign-In callback received")
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Google Sign-In failed: \(error.localizedDescription)"
                    return
                }
                
                guard let user = result?.user,
                      let idToken = user.idToken?.tokenString else {
                    self?.errorMessage = "Failed to get ID token from Google"
                    return
                }
                
                // Now use the shared KMP authentication
                self?.authRepository.signInWithGoogle { authState, error in
                    DispatchQueue.main.async {
                        if let error = error {
                            self?.errorMessage = "Backend authentication failed: \(error.localizedDescription)"
                        } else if let authState = authState {
                            switch authState {
                            case is AuthState.Success:
                                self?.isSignedIn = true
                                print("✅ Successfully signed in with Google and authenticated with backend")
                            case is AuthState.Error:
                                if let errorState = authState as? AuthState.Error {
                                    self?.errorMessage = errorState.message
                                }
                                self?.isSignedIn = false
                            default:
                                self?.isSignedIn = false
                            }
                        }
                    }
                }
            }
        }
    }
    
    func signOut() {
        isLoading = true
        errorMessage = nil
        
        // Sign out from Google
        GIDSignIn.sharedInstance.signOut()
        
        // Sign out from backend using shared KMP
        authRepository.signOut { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Sign out failed: \(error.localizedDescription)"
                } else {
                    self?.isSignedIn = false
                    print("✅ Successfully signed out")
                }
            }
        }
    }
    
    func updateSignInStatus(_ isSignedIn: Bool) {
        DispatchQueue.main.async {
            self.isSignedIn = isSignedIn
        }
    }
}

