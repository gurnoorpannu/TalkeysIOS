import SwiftUI
import Combine
import sharedKit

@MainActor
class HomeViewModel: ObservableObject {
    
    // MARK: - Published Properties (State)
    @Published var isLoading = false
    @Published var showingProfile = false
    @Published var quickActions: [QuickAction] = []
    @Published var recentActivities: [Activity] = []
    @Published var errorMessage: String?
    
    // MARK: - Dependencies
    private let authViewModel: AuthViewModel
    
    // MARK: - Initialization
    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
        setupQuickActions()
        setupRecentActivities()
    }
    
    // MARK: - Public Methods
    
    /// Load home screen data
    func loadData() {
        Task {
            isLoading = true
            errorMessage = nil
            
            do {
                // Load user data from shared repository
                authViewModel.loadUserData()
                
                // Simulate loading other data (replace with real API calls later)
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                
                // Update activities with user-specific data
                updateRecentActivities()
                
            } catch {
                errorMessage = "Failed to load home data: \(error.localizedDescription)"
                print("❌ Error loading home data: \(error)")
            }
            
            isLoading = false
        }
    }
    
    /// Handle quick action tap
    func handleQuickAction(_ action: QuickAction) {
        switch action.type {
        case .events:
            // TODO: Navigate to events screen
            print("📅 Navigate to Events")
            
        case .profile:
            showingProfile = true
            print("👤 Show Profile")
            
        case .settings:
            // TODO: Navigate to settings screen
            print("⚙️ Navigate to Settings")
            
        case .help:
            // TODO: Navigate to help screen
            print("❓ Navigate to Help")
        }
    }
    
    /// Sign out user
    func signOut() {
        authViewModel.signOut()
    }
    
    // MARK: - Private Methods
    
    private func setupQuickActions() {
        quickActions = [
            QuickAction(
                type: .events,
                title: "Events",
                subtitle: "Browse events",
                icon: "calendar.circle.fill",
                color: .blue
            ),
            QuickAction(
                type: .profile,
                title: "Profile",
                subtitle: "Edit profile",
                icon: "person.circle.fill",
                color: .green
            ),
            QuickAction(
                type: .settings,
                title: "Settings",
                subtitle: "App settings",
                icon: "gear.circle.fill",
                color: .orange
            ),
            QuickAction(
                type: .help,
                title: "Help",
                subtitle: "Get support",
                icon: "questionmark.circle.fill",
                color: .purple
            )
        ]
    }
    
    private func setupRecentActivities() {
        recentActivities = [
            Activity(
                id: "1",
                title: "Signed in successfully",
                subtitle: "Using shared authentication logic",
                time: "Just now",
                icon: "checkmark.circle.fill",
                iconColor: .green
            ),
            Activity(
                id: "2",
                title: "Welcome to Talkeys!",
                subtitle: "Your account is ready",
                time: "Just now",
                icon: "star.circle.fill",
                iconColor: .yellow
            )
        ]
    }
    
    private func updateRecentActivities() {
        // Update activities with current user info
        if let userName = authViewModel.currentUser?.name {
            recentActivities[0] = Activity(
                id: "1",
                title: "Welcome back, \(userName)!",
                subtitle: "Successfully authenticated",
                time: "Just now",
                icon: "checkmark.circle.fill",
                iconColor: .green
            )
        }
    }
}

// MARK: - Computed Properties
extension HomeViewModel {
    /// Get current user from auth view model
    var currentUser: User? {
        authViewModel.currentUser
    }
    
    /// Check if user is signed in
    var isSignedIn: Bool {
        authViewModel.isAuthenticated
    }
    
    /// Get user display name
    var userDisplayName: String {
        authViewModel.userDisplayName
    }
    
    /// Get user email
    var userEmail: String {
        authViewModel.userEmail
    }
    
    /// Get user initials
    var userInitials: String {
        authViewModel.userInitials
    }
}

// MARK: - Data Models

struct QuickAction: Identifiable, Hashable {
    let id = UUID()
    let type: QuickActionType
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
}

enum QuickActionType {
    case events
    case profile
    case settings
    case help
}

struct Activity: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let time: String
    let icon: String
    let iconColor: Color
}
