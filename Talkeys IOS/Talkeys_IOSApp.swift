//
//  Talkeys_IOSApp.swift
//  Talkeys IOS
//
//  Created by Gurnoor Singh Pannu on 17/09/25.
//

import SwiftUI
import GoogleSignIn
import sharedKit

@main
struct Talkeys_IOSApp: App {
    var body: some Scene {
        WindowGroup {
            MainAppView()
                .onAppear {
                    configureGoogleSignIn()
                }
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
    
    private func configureGoogleSignIn() {
        print("🔧 Configuring Google Sign-In...")
        print("📁 Bundle ID: \(Bundle.main.bundleIdentifier ?? "Unknown")")
        print("📁 Bundle path: \(Bundle.main.bundleURL.path)")
        
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") else {
            print("❌ Error: GoogleService-Info.plist not found in bundle")
            print("📁 Bundle contents: \(Bundle.main.bundleURL.path)")
            return
        }
        
        print("✅ Found GoogleService-Info.plist at: \(path)")
        
        guard let plist = NSDictionary(contentsOfFile: path) else {
            print("❌ Error: Could not read GoogleService-Info.plist")
            return
        }
        
        print("📄 Plist contents: \(plist)")
        
        guard let clientId = plist["CLIENT_ID"] as? String else {
            print("❌ Error: CLIENT_ID missing from GoogleService-Info.plist")
            return
        }
        
        print("🆔 Client ID found: \(clientId)")
        
        // Configure Google Sign-In
        let configuration = GIDConfiguration(clientID: clientId)
        GIDSignIn.sharedInstance.configuration = configuration
        
        print("✅ Google Sign-In configured successfully!")
        print("🔍 Current configuration: \(GIDSignIn.sharedInstance.configuration?.clientID ?? "NOT SET")")
        
        // Test if we can get current user
        if let currentUser = GIDSignIn.sharedInstance.currentUser {
            print("👤 Current user already signed in: \(currentUser.profile?.name ?? "Unknown")")
        } else {
            print("👤 No current user signed in")
        }
    }
}

struct MainAppView: View {
    @State private var isLoggedIn = false
    @State private var isCheckingAuth = true
    
    var body: some View {
        Group {
            if isCheckingAuth {
                // Show loading screen while checking authentication
                SplashLoadingView()
            } else if isLoggedIn {
                // Navigate to ExploreEventsView after successful authentication
                ExploreEventsView()
            } else {
                // Use LandingPage which has the Google Sign-In button
                LandingPage(isLoggedIn: $isLoggedIn)
            }
        }
        .animation(.easeInOut, value: isLoggedIn)
        .onAppear {
            checkExistingAuthentication()
        }
    }
    
    private func checkExistingAuthentication() {
        print("🔍 Checking existing authentication...")
        
        // Simple timeout-based check to prevent infinite loading
        Task {
            // Add a maximum timeout of 3 seconds
            let timeoutTask = Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
                await MainActor.run {
                    if isCheckingAuth {
                        print("⏰ Authentication check timed out, showing login screen")
                        isLoggedIn = false
                        isCheckingAuth = false
                    }
                }
            }
            
            // Check if we have a valid token stored locally
            if TokenManager.shared.isTokenValid() {
                print("✅ Valid token found, attempting quick validation...")
                
                // Simple validation - if token exists and is valid, assume user is logged in
                // This avoids the complex backend check that was causing issues
                await MainActor.run {
                    print("✅ Auto-login successful (token-based)")
                    isLoggedIn = true
                    isCheckingAuth = false
                    timeoutTask.cancel()
                }
            } else {
                print("❌ No valid token found, showing login screen")
                await MainActor.run {
                    isLoggedIn = false
                    isCheckingAuth = false
                    timeoutTask.cancel()
                }
            }
        }
    }
    
    // MARK: - Debug Methods (for manual testing)
    
    /// Call this method manually for testing token clearing
    /// Usage: In Xcode debugger or by adding a temporary button
    private func clearTokensForTesting() {
        print("🧪 DEBUG: Manually clearing tokens for testing")
        TokenManager.shared.clearTokensForTesting()
        isLoggedIn = false
        isCheckingAuth = false
    }
}

// Splash loading view while checking authentication
struct SplashLoadingView: View {
    var body: some View {
        ZStack {
            // Background Image (same as landing page)
            Image("splash_bg")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // Loading indicator
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                Text("Checking authentication...")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.top, 16)
                
                Text("This should only take a moment...")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.top, 8)
                
                Spacer()
            }
        }
    }
}

// Home screen with sign out functionality
struct HomeView: View {
    @Binding var isLoggedIn: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Text("🎉 Welcome to Talkeys!")
                .font(.title)
                .padding()
            
            Text("Successfully authenticated using\nshared Kotlin Multiplatform logic!")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding()
            
            Text("🔗 Same authentication logic as Android app")
                .font(.caption)
                .foregroundColor(.blue)
            
            Spacer()
            
            // Sign Out Button
            Button(action: {
                signOut()
            }) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Sign Out")
                }
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.red)
                .cornerRadius(8)
            }
            .padding(.horizontal)
        }
        .padding()
    }
    
    private func signOut() {
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
        
        // Navigate back to landing page
        withAnimation(.easeInOut) {
            isLoggedIn = false
        }
    }
}
