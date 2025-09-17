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
    
    var body: some View {
        Group {
            if isLoggedIn {
                // Navigate to ExploreEventsView after successful authentication
                ExploreEventsView()
            } else {
                // Use LandingPage which has the Google Sign-In button
                LandingPage(isLoggedIn: $isLoggedIn)
            }
        }
        .animation(.easeInOut, value: isLoggedIn)
        .onAppear {
            // For testing: Clear any existing tokens to ensure fresh start
            // Comment this out in production to enable auto-login
            clearTokensForTesting()
        }
    }
    
    private func clearTokensForTesting() {
        print("🧪 DEBUG: Clearing tokens for fresh testing experience")
        let _ = TokenManager.shared.clearToken()
        GIDSignIn.sharedInstance.signOut()
        print("🧪 DEBUG: Tokens cleared - app will show landing page")
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
