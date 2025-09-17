import SwiftUI
import sharedKit

struct LandingView: View {
    var body: some View {
        VStack {
            Text("This is LandingView - not being used")
        }
    }
}

@MainActor
class LandingViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var authStateText = "Initializing..."
    @Published var navigateToHome = false
    
    private var authRepository: AuthRepository
    
    init() {
        // Initialize KMP shared module - same as your Android app
        SharedModuleInitializerKt.doInitKoin()
        
        // Create shared AuthRepository - same logic as Android!
        let apiClient = ApiClient()
        let googleSignInProvider = IOSGoogleSignInProvider()
        let tokenStorage = IOSTokenStorage()
        
        self.authRepository = AuthRepository(
            httpClient: apiClient.httpClient,
            googleSignInProvider: googleSignInProvider,
            tokenStorage: tokenStorage
        )
        
        print("🚀 Shared Authentication Repository Initialized (same as Android!)")
        authStateText = "Ready - using shared Android logic"
    }
    
    func checkExistingAuth() {
        // Same auto-login check as your Android app
        Task {
            do {
                let authState = try await authRepository.checkExistingAuth()
                
                await MainActor.run {
                    if let successState = authState as? AuthState.Success {
                        // User already logged in - same as Android behavior
                        self.authStateText = "Already signed in: \(successState.user.name)"
                        self.navigateToHome = true
                        self.alertMessage = "Welcome back \(successState.user.name)! (Shared logic from Android)"
                        self.showAlert = true
                    } else {
                        self.authStateText = "Ready to sign in"
                    }
                }
            } catch {
                await MainActor.run {
                    self.authStateText = "Error checking auth: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func signInWithGoogle() {
        isLoading = true
        authStateText = "Authenticating with shared logic..."
        
        // Use the SAME shared authentication logic as your Android app!
        Task {
            do {
                let authState = try await authRepository.signInWithGoogle()
                
                await MainActor.run {
                    self.isLoading = false
                    
                    if let successState = authState as? AuthState.Success {
                        // Success - same as Android!
                        self.authStateText = "Signed in: \(successState.user.name)"
                        self.navigateToHome = true
                        self.alertMessage = """
                        ✅ Authentication Success!
                        
                        Welcome \(successState.user.name)!
                        
                        This used the SAME shared authentication logic as your Android app!
                        
                        • Same API calls
                        • Same token management 
                        • Same error handling
                        • Same business logic
                        """
                        self.showAlert = true
                        
                    } else if let errorState = authState as? AuthState.Error {
                        // Error handling - same as Android
                        self.authStateText = "Sign-in failed"
                        self.alertMessage = """
                        Authentication Failed
                        
                        \(errorState.message)
                        
                        Note: This is using the same shared error handling as your Android app. 
                        
                        For now, Google Sign-In shows a placeholder since we haven't implemented the iOS Google SDK yet, but the logic is shared!
                        """
                        self.showAlert = true
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.authStateText = "Sign-in failed"
                    self.alertMessage = "Error: \(error.localizedDescription)"
                    self.showAlert = true
                }
            }
        }
    }
}

#Preview {
    LandingView()
}
