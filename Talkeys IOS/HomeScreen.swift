import SwiftUI
import sharedKit

struct HomeScreen: View {
    @Binding var isLoggedIn: Bool
    @State private var showingProfile = false
    @State private var currentUser: User?
    @State private var isSigningOut = false
    
    // Get user info from shared KMP logic
    private let authRepository: AuthRepository
    
    init(isLoggedIn: Binding<Bool>) {
        self._isLoggedIn = isLoggedIn
        
        // Initialize shared KMP authentication to get user data
        SharedModuleInitializerKt.doInitKoin()
        let apiClient = ApiClient()
        let googleSignInProvider = IOSGoogleSignInProvider()
        let tokenStorage = IOSTokenStorage()
        
        self.authRepository = AuthRepository(
            httpClient: apiClient.httpClient,
            googleSignInProvider: googleSignInProvider,
            tokenStorage: tokenStorage
        )
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Welcome Section
                    VStack(spacing: 16) {
                        // Profile Picture Placeholder
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
                            .frame(width: 80, height: 80)
                            .overlay(
                                Text(currentUser?.name.prefix(1).uppercased() ?? "U")
                                    .font(.urbanistTitle1)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            )
                            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                        
                        VStack(spacing: 4) {
                            Text("Welcome back!")
                                .font(.urbanistTitle2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text(currentUser?.name ?? "User")
                                .font(.urbanistTitle3)
                                .fontWeight(.medium)
                                .foregroundColor(Color(red: 0.72, green: 0.41, blue: 1.0))
                            
                            Text(currentUser?.email ?? "")
                                .font(.urbanistSubheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Quick Actions
                    VStack(spacing: 16) {
                        HStack {
                            Text("Quick Actions")
                                .font(.urbanistHeadline)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                            QuickActionCard(
                                title: "Events",
                                subtitle: "Browse events",
                                icon: "calendar.circle.fill",
                                color: .blue
                            )
                            
                            QuickActionCard(
                                title: "Profile",
                                subtitle: "Edit profile",
                                icon: "person.circle.fill",
                                color: .green
                            ) {
                                showingProfile = true
                            }
                            
                            QuickActionCard(
                                title: "Settings",
                                subtitle: "App settings",
                                icon: "gear.circle.fill",
                                color: .orange
                            )
                            
                            QuickActionCard(
                                title: "Help",
                                subtitle: "Get support",
                                icon: "questionmark.circle.fill",
                                color: .purple
                            )
                        }
                    }
                    
                    // Recent Activity
                    VStack(spacing: 16) {
                        HStack {
                            Text("Recent Activity")
                                .font(.urbanistHeadline)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        
                        VStack(spacing: 12) {
                            ActivityRow(
                                title: "Signed in successfully",
                                subtitle: "Using shared authentication logic",
                                time: "Just now",
                                icon: "checkmark.circle.fill",
                                iconColor: .green
                            )
                            
                            ActivityRow(
                                title: "Welcome to Talkeys!",
                                subtitle: "Your account is ready",
                                time: "Just now",
                                icon: "star.circle.fill",
                                iconColor: .yellow
                            )
                        }
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        signOut()
                    }) {
                        if isSigningOut {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.red)
                        }
                    }
                    .disabled(isSigningOut)
                }
            }
        }
        .sheet(isPresented: $showingProfile) {
            ProfileSheet(user: currentUser)
        }
        .onAppear {
            loadUserData()
        }
    }
    
    // MARK: - Functions
    
    private func loadUserData() {
        // Try to get current user from shared KMP auth state
        Task {
            do {
                let authState = try await authRepository.checkExistingAuth()
                
                await MainActor.run {
                    if let successState = authState as? AuthState.Success {
                        self.currentUser = successState.user
                    }
                }
            } catch {
                print("Error loading user data: \\(error)")
            }
        }
    }
    
    private func signOut() {
        isSigningOut = true
        
        Task {
            // Sign out from shared KMP logic
            do {
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
                
                // Navigate back to landing page
                await MainActor.run {
                    withAnimation(.easeInOut) {
                        isLoggedIn = false
                    }
                    isSigningOut = false
                }
            } catch {
                await MainActor.run {
                    print("Error signing out: \\(error)")
                    isSigningOut = false
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct QuickActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: (() -> Void)?
    
    init(title: String, subtitle: String, icon: String, color: Color, action: (() -> Void)? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            action?()
        }) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(color)
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.urbanistHeadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.urbanistCaption1)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(Color(.systemGray6))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ActivityRow: View {
    let title: String
    let subtitle: String
    let time: String
    let icon: String
    let iconColor: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.urbanistSubheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.urbanistCaption1)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(time)
                .font(.urbanistCaption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ProfileSheet: View {
    let user: User?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Profile Header
                VStack(spacing: 16) {
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
                        .frame(width: 100, height: 100)
                        .overlay(
                            Text(user?.name.prefix(1).uppercased() ?? "U")
                                .font(.urbanistLargeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        )
                    
                    VStack(spacing: 8) {
                        Text(user?.name ?? "Unknown User")
                            .font(.urbanistTitle2)
                            .fontWeight(.semibold)
                        
                        Text(user?.email ?? "No email")
                            .font(.urbanistSubheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 20)
                
                // User Info
                VStack(spacing: 16) {
                    ProfileInfoRow(label: "User ID", value: user?.id ?? "N/A")
                    ProfileInfoRow(label: "Display Name", value: user?.displayName ?? "Not set")
                    ProfileInfoRow(label: "About", value: user?.about ?? "No bio available")
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ProfileInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            Text(value)
                .font(.body)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Preview
struct HomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        HomeScreen(isLoggedIn: .constant(true))
    }
}
