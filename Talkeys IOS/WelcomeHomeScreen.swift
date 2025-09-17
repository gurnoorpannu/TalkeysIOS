import SwiftUI
import GoogleSignIn

struct WelcomeHomeScreen: View {
    @Binding var isLoggedIn: Bool
    @State private var userName: String = ""
    @State private var showingSignOut = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.11, green: 0.11, blue: 0.11),
                        Color(red: 0.18, green: 0.18, blue: 0.18)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    Spacer()
                    
                    // Welcome Section
                    VStack(spacing: 20) {
                        // App Logo/Icon
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.72, green: 0.41, blue: 1.0),
                                        Color(red: 0.45, green: 0.25, blue: 0.8)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .overlay(
                                Text("T")
                                    .font(.system(size: 60, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
                        
                        VStack(spacing: 12) {
                            Text("Welcome to Home Screen!")
                                .font(.title.weight(.bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            Text("You've successfully logged in with Google")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                            
                            if !userName.isEmpty {
                                Text("Hello, \(userName)! 👋")
                                    .font(.title2.weight(.semibold))
                                    .foregroundColor(Color(red: 0.72, green: 0.41, blue: 1.0))
                                    .padding(.top, 8)
                            }
                        }
                    }
                    
                    // Success indicators
                    VStack(spacing: 16) {
                        SuccessIndicator(
                            icon: "checkmark.circle.fill",
                            text: "Google Authentication",
                            color: .green
                        )
                        
                        SuccessIndicator(
                            icon: "server.rack",
                            text: "Backend Connected",
                            color: .blue
                        )
                        
                        SuccessIndicator(
                            icon: "iphone",
                            text: "iOS App Ready",
                            color: .purple
                        )
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer()
                    
                    // Sign Out Button
                    Button(action: {
                        showSignOutConfirmation()
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.title3)
                            Text("Sign Out")
                                .font(.title3.weight(.semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.red.opacity(0.8))
                        )
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 50)
                }
            }
            .navigationBarHidden(true)
        }
        .alert("Sign Out", isPresented: $showingSignOut) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .onAppear {
            loadUserName()
        }
    }
    
    private func loadUserName() {
        // Get the actual user name from Google Sign-In
        if let user = GIDSignIn.sharedInstance.currentUser,
           let profile = user.profile {
            userName = profile.name
        } else {
            userName = "User"
        }
    }
    
    private func showSignOutConfirmation() {
        showingSignOut = true
    }
    
    private func signOut() {
        // Clear any local authentication state
        GoogleSignInManager.shared.updateSignInStatus(false)
        
        // Navigate back to landing page
        withAnimation(.easeInOut(duration: 0.5)) {
            isLoggedIn = false
        }
    }
}

// MARK: - Success Indicator Component
struct SuccessIndicator: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 24, height: 24)
            
            Text(text)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.white.opacity(0.9))
            
            Spacer()
            
            Image(systemName: "checkmark")
                .font(.caption.weight(.bold))
                .foregroundColor(color)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Preview
struct WelcomeHomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeHomeScreen(isLoggedIn: .constant(true))
    }
}
