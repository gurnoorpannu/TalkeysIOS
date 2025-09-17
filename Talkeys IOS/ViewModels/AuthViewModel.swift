import SwiftUI
import Combine
import GoogleSignIn
import UIKit
import sharedKit

// Use sharedKit.User instead of local User model
typealias User = sharedKit.User

@MainActor
class AuthViewModel: ObservableObject {
    
    // MARK: - Published Properties (State)
    @Published var isLoggedIn = false
    @Published var isLoading = false
    @Published var isCheckingToken = true
    @Published var currentUser: User?
    @Published var errorMessage: String?
    @Published var showToast = false
    @Published var toastMessage = ""
    
    // MARK: - Private Properties
    private let authRepository: AuthRepository
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        // Initialize shared KMP authentication
        SharedModuleInitializerKt.doInitKoin()
        
        let apiClient = ApiClient()
        let googleSignInProvider = IOSGoogleSignInProvider()
        let tokenStorage = IOSTokenStorage()
        
        self.authRepository = AuthRepository(
            httpClient: apiClient.httpClient,
            googleSignInProvider: googleSignInProvider,
            tokenStorage: tokenStorage
        )
        
        // Automatically check for existing auth on init
        checkExistingAuth()
    }
    
    // MARK: - Public Methods
    
    /// Check if user has existing valid authentication
    func checkExistingAuth() {
        Task {
            isCheckingToken = true
            
            // Quick local token validation first
            if TokenManager.shared.isTokenValid() {
                do {
                    let authState = try await authRepository.checkExistingAuth()
                    
                    if let successState = authState as? AuthState.Success {
                        // User already logged in
                        await updateAuthState(
                            isLoggedIn: true,
                            user: successState.user,
                            message: "Welcome back \(successState.user.name)!"
                        )
                        
                        GoogleSignInManager.shared.updateSignInStatus(true)
                        
                        // Show welcome message briefly
                        await showToastMessage("Welcome back \(successState.user.name)!")
                    } else {
                        // Token exists but auth failed, clear it
                        await handleAuthFailure("Authentication expired")
                    }
                } catch {
                    // Error checking auth, clear token and show login
                    await handleAuthFailure("Authentication check failed: \(error.localizedDescription)")
                }
            } else {
                // No valid token, show login screen
                await updateAuthState(isLoggedIn: false, user: nil)
                GoogleSignInManager.shared.updateSignInStatus(false)
            }
            
            isCheckingToken = false
        }
    }
    
    /// Handle Google Sign-In using native iOS implementation
    func signInWithGoogle() {
        guard !isLoading else { return }
        
        print("🔥 AuthViewModel.signInWithGoogle() called")
        
        // Use native iOS GoogleSignInManager instead of broken KMP implementation
        isLoading = true
        errorMessage = nil
        
        // Get root view controller
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let presentingViewController = windowScene.windows.first?.rootViewController else {
            Task {
                await handleAuthFailure("No presenting view controller found")
                isLoading = false
            }
            return
        }
        
        print("✅ Found presenting view controller: \(presentingViewController)")
        print("🔧 GIDSignIn configuration: \(GIDSignIn.sharedInstance.configuration?.clientID ?? "NOT CONFIGURED")")
        
        // Use native Google Sign-In SDK directly
        print("🚀 Calling GIDSignIn.sharedInstance.signIn...")
        GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { [weak self] result, error in
            print("📲 Google Sign-In callback received")
            
            Task { @MainActor in
                self?.isLoading = false
                
                if let error = error {
                    print("❌ Google Sign-In error: \(error.localizedDescription)")
                    await self?.handleAuthFailure("Google Sign-In failed: \(error.localizedDescription)")
                    return
                }
                
                guard let user = result?.user,
                      let idToken = user.idToken?.tokenString,
                      let profile = user.profile else {
                    print("❌ Failed to get user data from Google")
                    await self?.handleAuthFailure("Failed to get ID token from Google")
                    return
                }
                
                let userName = profile.name ?? "User"
                let userEmail = profile.email ?? ""
                
                print("✅ Google Sign-In successful for: \(userName)")
                print("📧 Email: \(userEmail)")
                print("🎫 ID Token: \(idToken.prefix(50))...")
                
                // Create a User object for our app using correct sharedKit.User initializer
                let appUser = User(
                    id: user.userID ?? UUID().uuidString,
                    name: userName,
                    email: userEmail,
                    displayName: userName, // Use the same name as displayName
                    profilePicture: profile.imageURL(withDimension: 200)?.absoluteString, // Get profile picture URL if available
                    about: nil, // No about info from Google Sign-In
                    pronouns: nil // No pronouns info from Google Sign-In
                )
                
                // Save token locally
                let tokenResult = TokenManager.shared.saveToken(idToken)
                switch tokenResult {
                case .success:
                    print("✅ Token saved locally")
                case .failure(let error):
                    print("⚠️ Failed to save token locally: \(error)")
                }
                
                // Update auth state to trigger navigation
                await self?.updateAuthState(
                    isLoggedIn: true,
                    user: appUser,
                    message: "Welcome \(userName)!"
                )
                
                // Update GoogleSignInManager status
                GoogleSignInManager.shared.updateSignInStatus(true)
                
                // Show success message
                await self?.showToastMessage("Welcome \(userName)!")
                
                print("✅ Authentication flow completed successfully")
            }
        }
    }
    
    /// Sign out user
    func signOut() {
        Task {
            isLoading = true
            
            do {
                // Sign out from shared KMP logic
                try await authRepository.signOut()
                
                // Clear local token
                let tokenResult = TokenManager.shared.clearToken()
                switch tokenResult {
                case .success:
                    print("✅ Local token cleared")
                case .failure(let error):
                    print("⚠️ Failed to clear token: \(error.localizedDescription)")
                }
                
                // Update sign-in manager
                GoogleSignInManager.shared.updateSignInStatus(false)
                
                // Update state
                await updateAuthState(isLoggedIn: false, user: nil)
                
            } catch {
                await handleAuthFailure("Sign-out failed: \(error.localizedDescription)")
            }
            
            isLoading = false
        }
    }
    
    /// Load user data from shared repository
    func loadUserData() {
        Task {
            do {
                let authState = try await authRepository.checkExistingAuth()
                
                if let successState = authState as? AuthState.Success {
                    currentUser = successState.user
                }
            } catch {
                print("Error loading user data: \(error)")
                errorMessage = "Failed to load user data"
            }
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func updateAuthState(isLoggedIn: Bool, user: User?, message: String? = nil) async {
        self.isLoggedIn = isLoggedIn
        self.currentUser = user
        if let message = message {
            self.toastMessage = message
        }
        self.errorMessage = nil
    }
    
    private func handleAuthFailure(_ message: String) async {
        // Clear any stored tokens
        _ = TokenManager.shared.clearToken()
        GoogleSignInManager.shared.updateSignInStatus(false)
        
        // Update state
        self.isLoggedIn = false
        self.currentUser = nil
        self.errorMessage = message
        
        // Show error as toast
        await showToastMessage(message)
        
        print("❌ Auth failure: \(message)")
    }
    
    private func showToastMessage(_ message: String) async {
        toastMessage = message
        showToast = true
        
        // Hide toast after 3 seconds
        try? await Task.sleep(nanoseconds: 3_000_000_000)
        showToast = false
    }
}

// MARK: - Computed Properties
extension AuthViewModel {
    /// Check if user is authenticated
    var isAuthenticated: Bool {
        isLoggedIn && currentUser != nil
    }
    
    /// Get user display name
    var userDisplayName: String {
        currentUser?.name ?? "User"
    }
    
    /// Get user email
    var userEmail: String {
        currentUser?.email ?? ""
    }
    
    /// Get user initials for avatar
    var userInitials: String {
        String(currentUser?.name.prefix(1).uppercased() ?? "U")
    }
}
