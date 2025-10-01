import SwiftUI
import sharedKit

struct HomeTopBar: View {
    @ObservedObject var authViewModel: AuthViewModel
    var onLogoTap: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 0) {
            // Navigation Icon (Logo) - Using logo from assets (75dp equivalent)
            Button(action: {
                // Navigate to home - equivalent to navController.navigate("home")
                onLogoTap?()
            }) {
                Image("logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 70, height: 70)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(PlainButtonStyle())
            .frame(maxHeight: .infinity) // fillMaxHeight equivalent
            
            Spacer()
            
            // Actions
            HStack(spacing: 12) {
                // Chat Button
                Button(action: {
                    // Handle chat click
                }) {
                    Image(systemName: "message.circle")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
                .buttonStyle(PlainButtonStyle())
                
                // User Avatar with Google profile picture
                GoogleUserAvatar(
                    user: authViewModel.currentUser,
                    size: 36
                )
                .onTapGesture {
                    // Navigate to profile
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(height: 80) // Increased height to accommodate 75dp logo
        .background(Color.black) // Black background as requested
        .foregroundColor(.white)
    }
}

// Google User Avatar Component with profile picture
struct GoogleUserAvatar: View {
    let user: User?
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 112/255, green: 60/255, blue: 160/255),
                            Color(red: 183/255, green: 104/255, blue: 255/255)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
            
            // Profile picture or initials
            if let profilePictureUrl = user?.profilePicture,
               !profilePictureUrl.isEmpty,
               let url = URL(string: profilePictureUrl) {
                
                // Debug logging
                let _ = print("🖼️ Loading profile picture from: \(profilePictureUrl)")
                
                // Load Google profile picture
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size, height: size)
                            .clipShape(Circle())
                    case .failure(let error):
                        // Log error and show initials
                        let _ = print("❌ Failed to load profile picture: \(error)")
                        Text(getUserInitials())
                            .font(.system(size: size * 0.4, weight: .semibold))
                            .foregroundColor(.white)
                    case .empty:
                        // Show loading indicator
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.5)
                    @unknown default:
                        Text(getUserInitials())
                            .font(.system(size: size * 0.4, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
            } else {
                // Debug logging for missing profile picture
                let _ = print("👤 No profile picture URL found. User: \(user?.name ?? "nil"), ProfilePicture: \(user?.profilePicture ?? "nil")")
                
                // Show user initials if no profile picture
                Text(getUserInitials())
                    .font(.system(size: size * 0.4, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .overlay(
            Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: 2)
        )
        .onAppear {
            // Debug user data
            print("🔍 GoogleUserAvatar - User: \(user?.name ?? "nil")")
            print("🔍 GoogleUserAvatar - Email: \(user?.email ?? "nil")")
            print("🔍 GoogleUserAvatar - ProfilePicture: \(user?.profilePicture ?? "nil")")
        }
    }
    
    private func getUserInitials() -> String {
        guard let user = user, !user.name.isEmpty else { 
            print("⚠️ No user or empty name, using 'U'")
            return "U" 
        }
        let initials = String(user.name.prefix(1).uppercased())
        print("✅ Using initials: \(initials) for user: \(user.name)")
        return initials
    }
}


