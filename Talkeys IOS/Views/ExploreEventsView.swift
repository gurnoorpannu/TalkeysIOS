import SwiftUI
import Foundation

// MARK: - Explore Events View
struct ExploreEventsView: View {
    @StateObject private var eventRepository = EventRepository.shared
    @StateObject private var authViewModel = AuthViewModel()
    @State private var groupedEvents: [String: [EventResponse]] = [:]
    @State private var showLiveEvents = true
    @State private var scrollOffset: CGFloat = 0
    @State private var lastScrollOffset: CGFloat = 0
    @State private var isHeaderVisible = true
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background Image
                Image("background")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
                    .clipped()
                
                VStack(spacing: 0) {
                    // Top Bar
                    HomeTopBar(
                        authViewModel: authViewModel,
                        onLogoTap: {
                            // Navigate to home - equivalent to navController.navigate("home")
                            print("🏠 Logo tapped - Navigate to home")
                            // TODO: Implement actual navigation when home screen is ready
                        }
                    )
                    
                    // Header with filter buttons (collapsible)
                    if isHeaderVisible {
                        headerView
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // Debug button (remove in production)
                    HStack {
                        Button("Toggle Header") {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isHeaderVisible.toggle()
                            }
                        }
                        .padding(8)
                        .background(Color.red.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                        .font(.caption)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    
                    // Events Content
                    if eventRepository.isLoading {
                        loadingView
                    } else if let error = eventRepository.errorMessage {
                        errorView(error)
                    } else if filteredEvents.isEmpty {
                        emptyStateView
                    } else {
                        eventsContentView
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            loadEvents()
            // Ensure user data is loaded for TopBar
            if authViewModel.currentUser == nil && !authViewModel.isCheckingToken {
                authViewModel.checkExistingAuth()
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Title
            Text("Explore Events")
                .font(.custom("Urbanist-Regular", size: 20))
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.top, 8)
                .padding(.leading, 16)
            
            Spacer()
                .frame(height: 12)
            
            // Live/Past Events Filter Buttons
            HStack(spacing: 12) {
                FilterButton(
                    title: "Live Events",
                    isSelected: showLiveEvents,
                    action: {
                        if !showLiveEvents {
                            showLiveEvents = true
                            updateGroupedEvents()
                        }
                    }
                )
                
                FilterButton(
                    title: "Past Events",
                    isSelected: !showLiveEvents,
                    action: {
                        if showLiveEvents {
                            showLiveEvents = false
                            updateGroupedEvents()
                        }
                    }
                )
            }
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - Events Content View
    private var eventsContentView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Show events grouped by category
                    ForEach(Array(groupedEvents.keys.sorted()), id: \.self) { category in
                        if let categoryEvents = groupedEvents[category], !categoryEvents.isEmpty {
                            AnimatedCategorySectionView(
                                category: category,
                                events: categoryEvents,
                                onEventTapped: handleEventTap
                            )
                        }
                    }
                    
                    // Bottom spacing
                    Spacer()
                        .frame(height: 8)
                }
                .padding(.top, 20) // Add padding above first heading
                .padding(.bottom, 100) // Extra padding for bottom tab bar
                .background(
                    // Invisible scroll detector
                    GeometryReader { geometry in
                        Color.clear
                            .preference(key: ScrollOffsetPreferenceKey.self, 
                                      value: geometry.frame(in: .global).minY)
                    }
                )
            }
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                handleScrollOffset(value)
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let currentOffset = value.translation.height
                        handleDragOffset(currentOffset)
                    }
            )
            .modifier(RefreshableModifier {
                await loadEventsWithRefresh()
            })
        }
    }
    
    // MARK: - Category Section View
    struct CategorySectionView: View {
        let category: String
        let events: [EventResponse]
        let onEventTapped: (EventResponse) -> Void
        
        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                // Category Title
                Text(category)
                    .font(.custom("Urbanist-Regular", size: 18))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.leading, 16)
                    .padding(.bottom, 12)
                
                // Horizontal Scrolling Events
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(events.indices, id: \.self) { index in
                            let event = events[index]
                            
                            EventCard(
                                event: event,
                                onClick: {
                                    onEventTapped(event)
                                },
                                isCenter: false,
                                isFocused: true
                            )
                            .animation(
                                .spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)
                                    .delay(Double(index) * 0.05),
                                value: events.count
                            )
                        }
                    }
                    .padding(.leading, 16)
                    .padding(.trailing, 80)
                }
            }
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                ForEach(0..<4, id: \.self) { index in
                    LoadingCategorySection()
                        .animation(
                            Animation.easeInOut(duration: 0.8)
                                .delay(Double(index) * 0.2),
                            value: index
                        )
                }
                
                // Bottom spacing to match real content
                Spacer()
                    .frame(height: 8)
            }
            .padding(.top, 20) // Match real content top padding
            .padding(.bottom, 100) // Match real content bottom padding
        }
    }
    
    struct LoadingCategorySection: View {
        @State private var titleAnimating = false
        
        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                // Loading category title - matches real category title
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 64/255, green: 64/255, blue: 64/255).opacity(0.4),
                                Color(red: 80/255, green: 80/255, blue: 80/255).opacity(0.6),
                                Color(red: 64/255, green: 64/255, blue: 64/255).opacity(0.4)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 140, height: 18) // Match category title size
                    .padding(.leading, 16)
                    .padding(.bottom, 12)
                    .scaleEffect(titleAnimating ? 1.02 : 1.0)
                    .opacity(titleAnimating ? 0.8 : 0.5)
                    .animation(
                        Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                        value: titleAnimating
                    )
                    .onAppear {
                        titleAnimating = true
                    }
                
                // Loading cards row - matches real horizontal scroll
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(0..<4, id: \.self) { index in
                            SkeletonEventCard()
                                .animation(
                                    Animation.easeInOut(duration: 1.0)
                                        .delay(Double(index) * 0.1),
                                    value: titleAnimating
                                )
                        }
                    }
                    .padding(.leading, 16)
                    .padding(.trailing, 80)
                }
            }
        }
    }
    
    struct SkeletonEventCard: View {
        @State private var isAnimating = false
        @State private var shimmerOffset: CGFloat = -200
        
        var body: some View {
            VStack(spacing: 0) {
                // Image placeholder - matches EventCard image dimensions
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 64/255, green: 64/255, blue: 64/255).opacity(0.3),
                                Color(red: 80/255, green: 80/255, blue: 80/255).opacity(0.5),
                                Color(red: 64/255, green: 64/255, blue: 64/255).opacity(0.3)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 161, height: 165) // Match EventCard focused dimensions
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                
                // Content section - matches EventCard content area
                VStack(alignment: .leading, spacing: 6) {
                    // Title placeholder
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(red: 64/255, green: 64/255, blue: 64/255).opacity(0.4))
                        .frame(width: 140, height: 14)
                    
                    // Second line of title
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(red: 64/255, green: 64/255, blue: 64/255).opacity(0.3))
                        .frame(width: 100, height: 14)
                    
                    // Location row placeholder
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(red: 64/255, green: 64/255, blue: 64/255).opacity(0.4))
                            .frame(width: 12, height: 12)
                        
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(red: 64/255, green: 64/255, blue: 64/255).opacity(0.4))
                            .frame(width: 80, height: 10)
                    }
                    
                    // Date row placeholder
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(red: 64/255, green: 64/255, blue: 64/255).opacity(0.4))
                            .frame(width: 12, height: 12)
                        
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(red: 64/255, green: 64/255, blue: 64/255).opacity(0.4))
                            .frame(width: 90, height: 10)
                    }
                    
                    // Tags row placeholder
                    HStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(red: 64/255, green: 64/255, blue: 64/255).opacity(0.4))
                            .frame(width: 40, height: 16)
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(red: 64/255, green: 64/255, blue: 64/255).opacity(0.4))
                            .frame(width: 35, height: 16)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 12)
                .frame(width: 165, alignment: .leading) // Match EventCard width
            }
            .frame(width: 165, height: 286) // Match EventCard total dimensions
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 40/255, green: 40/255, blue: 40/255).opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .overlay(
                // Shimmer effect
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(0.1),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: shimmerOffset)
                    .animation(
                        Animation.linear(duration: 1.5).repeatForever(autoreverses: false),
                        value: shimmerOffset
                    )
            )
            .clipped()
            .scaleEffect(isAnimating ? 1.01 : 1.0)
            .opacity(isAnimating ? 0.8 : 0.6)
            .animation(
                Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
                // Start shimmer animation
                withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    shimmerOffset = 200
                }
            }
        }
    }
    
    // MARK: - Error View
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 24) {
            Text("Unable to load events")
                .font(.custom("Urbanist-Regular", size: 20))
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(error)
                .font(.custom("Urbanist-Regular", size: 16))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
            
            HStack(spacing: 12) {
                Button("Dismiss") {
                    eventRepository.errorMessage = nil
                    updateGroupedEvents()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.white, lineWidth: 1)
                )
                .foregroundColor(.white)
                
                Button("Retry") {
                    loadEvents(forceRefresh: true)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color(red: 138/255, green: 68/255, blue: 203/255))
                .cornerRadius(8)
                .foregroundColor(.white)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 32)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Text(showLiveEvents ? "No live events available" : "No past events available")
                .font(.custom("Urbanist-Regular", size: 18))
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text("Check back later for new events")
                .font(.custom("Urbanist-Regular", size: 16))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 32)
    }
    
    // MARK: - Filter Button Component
    struct FilterButton: View {
        let title: String
        let isSelected: Bool
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                Text(title)
                    .font(.custom("Urbanist-Regular", size: 14))
                    .fontWeight(isSelected ? .bold : .regular)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(
                        isSelected ?
                        Color(red: 138/255, green: 68/255, blue: 203/255) :
                        Color.white.opacity(0.25)
                    )
                    .cornerRadius(20)
            }
        }
    }
    
    // MARK: - Computed Properties
    private var filteredEvents: [EventResponse] {
        var filtered = eventRepository.events
        
        // Filter by Live/Past events
        filtered = filtered.filter { event in
            if showLiveEvents {
                return event.isLive == true
            } else {
                return event.isLive != true
            }
        }
        
        return filtered
    }
    
    // MARK: - Methods
    private func loadEvents(forceRefresh: Bool = false) {
        Task {
            await eventRepository.fetchAllEvents(forceRefresh: forceRefresh)
            await MainActor.run {
                updateGroupedEvents()
            }
        }
    }
    
    private func loadEventsWithRefresh() async {
        await eventRepository.fetchAllEvents(forceRefresh: true)
        await MainActor.run {
            updateGroupedEvents()
        }
    }
    
    private func updateGroupedEvents() {
        let filtered = filteredEvents
        groupedEvents = Dictionary(grouping: filtered) { event in
            return event.category.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty == false
                ? event.category : "Uncategorized"
        }.filter { !$0.value.isEmpty }
    }
    
    private func handleEventTap(event: EventResponse) {
        let eventId = event._id
        guard !eventId.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty else {
            print("Event ID is null or blank for event: \(event.name)")
            return
        }
        
        print("Event clicked: \(event.name), ID: \(eventId)")
        // TODO: Navigate to event detail view
        // You can implement navigation here
    }
    
    // MARK: - Scroll Handling
    private func handleScrollOffset(_ offset: CGFloat) {
        let scrollDelta = offset - lastScrollOffset
        let threshold: CGFloat = 10 // Minimum scroll distance to trigger
        
        // Debug logging
        print("📊 Scroll offset: \(offset), delta: \(scrollDelta), headerVisible: \(isHeaderVisible)")
        
        // Only react to significant scroll movements
        if abs(scrollDelta) > threshold {
            withAnimation(.easeInOut(duration: 0.3)) {
                if scrollDelta < -threshold {
                    // Scrolling down - hide header
                    if isHeaderVisible {
                        print("🔽 Hiding header (scrolling down)")
                        isHeaderVisible = false
                    }
                } else if scrollDelta > threshold {
                    // Scrolling up - show header
                    if !isHeaderVisible {
                        print("🔼 Showing header (scrolling up)")
                        isHeaderVisible = true
                    }
                }
            }
            lastScrollOffset = offset
        }
    }
    
    // MARK: - Drag Handling (Alternative scroll detection)
    private func handleDragOffset(_ offset: CGFloat) {
        let threshold: CGFloat = 30
        
        print("🖱️ Drag offset: \(offset), headerVisible: \(isHeaderVisible)")
        
        withAnimation(.easeInOut(duration: 0.3)) {
            if offset < -threshold {
                // Dragging up (scrolling down) - hide header
                if isHeaderVisible {
                    print("🔽 Hiding header (drag up)")
                    isHeaderVisible = false
                }
            } else if offset > threshold {
                // Dragging down (scrolling up) - show header
                if !isHeaderVisible {
                    print("🔼 Showing header (drag down)")
                    isHeaderVisible = true
                }
            }
        }
    }
}

// MARK: - iOS Version Compatibility
struct RefreshableModifier: ViewModifier {
    let action: () async -> Void
    
    func body(content: Content) -> some View {
        if #available(iOS 15.0, *) {
            content
                .refreshable {
                    await action()
                }
        } else {
            content
        }
    }
}

// MARK: - Scroll Offset Preference Key
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Animated Category Section View with Card Rotation
struct AnimatedCategorySectionView: View {
    let category: String
    let events: [EventResponse]
    let onEventTapped: (EventResponse) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Category Title
            Text(category)
                .font(.custom("Urbanist-Regular", size: 18))
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.leading, 16)
                .padding(.bottom, 12)
            
            // Horizontal Scrolling Events with Rotation Animation
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(events.indices, id: \.self) { index in
                        let event = events[index]
                        
                        AnimatedEventCard(
                            event: event,
                            onClick: {
                                onEventTapped(event)
                            },
                            animationDelay: Double(index) * 0.1
                        )
                    }
                }
                .padding(.leading, 16)
                .padding(.trailing, 80)
                .padding(.vertical, 30) // Extra vertical padding to prevent clipping
            }
            // SwiftUI doesn't clip by default, so rotation overflow is allowed
        }
    }
}

// MARK: - Animated Event Card with Rotation Effect
struct AnimatedEventCard: View {
    let event: EventResponse
    let onClick: () -> Void
    let animationDelay: Double
    
    @State private var rotationY: Double = 0
    @State private var isVisible = false
    
    var body: some View {
        EventCard(
            event: event,
            onClick: onClick,
            isCenter: false,
            isFocused: true
        )
        .rotation3DEffect(
            .degrees(rotationY),
            axis: (x: 0, y: 1, z: 0), // Rotate around Y-axis (vertical)
            anchor: .center, // Rotate around center point
            perspective: 0.5 // Add perspective for 3D effect
        )
        .padding(.vertical, 20) // Add vertical padding to prevent clipping
        .padding(.horizontal, 10) // Add horizontal padding for rotation space
        // SwiftUI allows overflow by default for 3D transforms
        .opacity(isVisible ? 1.0 : 0.0)
        .scaleEffect(isVisible ? 1.0 : 0.8)
        .onAppear {
            // Entrance animation
            withAnimation(.easeOut(duration: 0.6).delay(animationDelay)) {
                isVisible = true
            }
            
            // Continuous 3D rotation animation around center axis
            withAnimation(
                .easeInOut(duration: 6.0)
                .repeatForever(autoreverses: true)
                .delay(animationDelay)
            ) {
                rotationY = 8.0 // 8-degree 3D rotation for visible effect
            }
        }
        .onDisappear {
            rotationY = 0
            isVisible = false
        }
    }
}

// MARK: - Preview
struct ExploreEventsView_Previews: PreviewProvider {
    static var previews: some View {
        ExploreEventsView()
            .preferredColorScheme(.dark)
    }
}
