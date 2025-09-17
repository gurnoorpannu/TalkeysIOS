import SwiftUI
import GoogleSignIn
import sharedKit

struct LandingPage: View {
    // MARK: - MVVM Properties
    @StateObject private var authViewModel = AuthViewModel()
    
    // Navigation
    @Binding var isLoggedIn: Bool
    
    init(isLoggedIn: Binding<Bool>) {
        self._isLoggedIn = isLoggedIn
    }
    
    var body: some View {
        ZStack {
            // Background Image
            Image("splash_bg")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
            
            if authViewModel.isCheckingToken {
                // Loading state while checking token
                VStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    Spacer()
                }
            } else {
                // Main Content
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Main Title
                    Text("Unlimited\nentertainment,\nall in one place")
                        .font(.urbanist(size: 24))
                        .fontWeight(.semibold)
                        .foregroundColor(Color(red: 1.0, green: 252/255, blue: 252/255))
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                    
                    // Subtitle
                    Text("Your Stage, Your Voice\nEvents Reimagined")
                        .font(.urbanistCallout)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.top, 16)
                    
                    // Login Button
                    Button(action: {
                        authViewModel.signInWithGoogle()
                    }) {
                        HStack {
                            if authViewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                                
                                Text("SIGNING IN...")
                                    .font(.urbanistButton)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.leading, 12)
                            } else {
                                Text("LOGIN WITH GOOGLE")
                                    .font(.urbanistButton)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            authViewModel.isLoading ? 
                            Color(red: 156/255, green: 77/255, blue: 205/255) :
                            Color(red: 183/255, green: 104/255, blue: 255/255)
                        )
                        .cornerRadius(4)
                    }
                    .disabled(authViewModel.isLoading)
                    .padding(.top, 32)
                    
                    Spacer()
                        .frame(height: 32)
                }
                .padding(.horizontal, 24)
            }
            
            // Toast Overlay
            if authViewModel.showToast {
                VStack {
                    Spacer()
                    Text(authViewModel.toastMessage)
                        .font(.urbanistSmall)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(8)
                        .padding(.bottom, 100)
                }
                .transition(.opacity)
            }
        }
        .onAppear {
            // Sync with AuthViewModel state
            syncAuthState()
        }
        .onChange(of: authViewModel.isLoggedIn) { newValue in
            // Sync navigation state with AuthViewModel
            isLoggedIn = newValue
        }
    }
    
    // MARK: - MVVM Helper Functions
    
    private func syncAuthState() {
        // Sync navigation state with AuthViewModel
        isLoggedIn = authViewModel.isLoggedIn
    }
}

// MARK: - Enhanced TokenManager (similar to Android's TokenManager with Result handling)

class TokenManager {
    static let shared = TokenManager()
    private let userDefaults = UserDefaults.standard
    private let tokenKey = "auth_token"
    private let tokenExpiryKey = "auth_token_expiry"
    
    private init() {}
    
    // MARK: - Token Management (equivalent to Android's TokenManager methods)
    
    /// Save token with proper error handling (equivalent to Android's saveToken)
    func saveToken(_ token: String) -> Result<Void, TokenError> {
        userDefaults.set(token, forKey: tokenKey)
        
        // Set expiry time (24 hours from now, similar to Android)
        let expiryTime = Date().timeIntervalSince1970 + (24 * 60 * 60)
        userDefaults.set(expiryTime, forKey: tokenExpiryKey)
        
        print("✅ Token saved successfully")
        return .success(())
    }
    
    /// Get current token (equivalent to Android's getToken)
    func getToken() -> Result<String?, TokenError> {
        let token = userDefaults.string(forKey: tokenKey)
        return .success(token)
    }
    
    /// Clear token (equivalent to Android's clearToken)
    func clearToken() -> Result<Void, TokenError> {
        userDefaults.removeObject(forKey: tokenKey)
        userDefaults.removeObject(forKey: tokenExpiryKey)
        print("✅ Token cleared successfully")
        return .success(())
    }
    
    /// Check if token is valid (equivalent to Android's isTokenValid)
    func isTokenValid() -> Bool {
        guard let token = userDefaults.string(forKey: tokenKey), !token.isEmpty else {
            return false
        }
        
        // Check expiry (optional, similar to Android logic)
        let expiryTime = userDefaults.double(forKey: tokenExpiryKey)
        if expiryTime > 0 && Date().timeIntervalSince1970 > expiryTime {
            print("⚠️ Token expired")
            _ = clearToken() // Clear expired token
            return false
        }
        
        return true
    }
}

// MARK: - Token Error Types (similar to Android's Result.Error)
enum TokenError: LocalizedError {
    case saveFailed
    case retrievalFailed
    case clearFailed
    
    var errorDescription: String? {
        switch self {
        case .saveFailed:
            return "Failed to save authentication token"
        case .retrievalFailed:
            return "Failed to retrieve authentication token"
        case .clearFailed:
            return "Failed to clear authentication token"
        }
    }
}

// MARK: - Preview
struct LandingPage_Previews: PreviewProvider {
    static var previews: some View {
        LandingPage(isLoggedIn: .constant(false))
    }
}