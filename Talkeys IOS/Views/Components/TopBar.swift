import SwiftUI
import sharedKit

struct HomeTopBar: View {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some View {
        HStack(spacing: 0) {
            // Navigation Icon (Logo) - Text-based logo
            Button(action: {
                // Navigate to home or handle logo tap
            }) {
                HStack(spacing: 2) {
                    Text("Talk")
                        .font(.custom("Urbanist-Regular", size: 18))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("eys")
                        .font(.custom("Urbanist-Regular", size: 18))
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 183/255, green: 104/255, blue: 255/255))
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // Actions
            HStack(spacing: 12) {
                // Chat Button (placeholder icon)
                Button(action: {
                    // Handle chat click
                }) {
                    Image(systemName: "message.circle")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
                .buttonStyle(PlainButtonStyle())
                
                // User Avatar
                SimpleUserAvatar(
                    userName: authViewModel.userDisplayName,
                    size: 36
                )
                .onTapGesture {
                    // Navigate to profile
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(height: 56)
        .background(Color.clear) // Transparent background to blend with screen
        .foregroundColor(.white)
    }
}

// Simple User Avatar Component
struct SimpleUserAvatar: View {
    let userName: String
    let size: CGFloat
    
    var body: some View {
        ZStack {
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
            
            Text(userName.isEmpty ? "U" : String(userName.prefix(1).uppercased()))
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundColor(.white)
        }
        .overlay(
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}
