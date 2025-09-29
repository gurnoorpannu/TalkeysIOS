import SwiftUI
import Foundation

// MARK: - Explore Events View
struct ExploreEventsView: View {
    @StateObject private var eventRepository = EventRepository.shared
    @State private var groupedEvents: [String: [EventResponse]] = [:]
    @State private var showLiveEvents = false
    
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
                    // Header with filter buttons
                    headerView
                    
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
                .padding(.top, 12)
                .padding(.leading, 19)
            
            Spacer()
                .frame(height: 16)
            
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
        ScrollView {
            LazyVStack(spacing: 16) {
                // Show events grouped by category
                ForEach(Array(groupedEvents.keys.sorted()), id: \.self) { category in
                    if let categoryEvents = groupedEvents[category], !categoryEvents.isEmpty {
                        CategorySectionView(
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
            .padding(.bottom, 100) // Extra padding for bottom tab bar
        }
        .modifier(RefreshableModifier {
            await loadEventsWithRefresh()
        })
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
        VStack(spacing: 0) {
            ForEach(0..<3, id: \.self) { _ in
                LoadingCategorySection()
                    .padding(.bottom, 16)
            }
            Spacer()
        }
        .padding(.top, 16)
    }
    
    struct LoadingCategorySection: View {
        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                // Loading category title
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(red: 64/255, green: 64/255, blue: 64/255).opacity(0.6))
                    .frame(width: 120, height: 20)
                    .padding(.leading, 16)
                    .padding(.bottom, 12)
                
                // Loading cards row
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(0..<3, id: \.self) { _ in
                            SkeletonEventCard()
                        }
                    }
                    .padding(.leading, 16)
                    .padding(.trailing, 80)
                }
            }
        }
    }
    
    struct SkeletonEventCard: View {
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 64/255, green: 64/255, blue: 64/255).opacity(0.6))
                    .frame(width: 160, height: 200)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(red: 64/255, green: 64/255, blue: 64/255).opacity(0.6))
                    .frame(width: 120, height: 16)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(red: 64/255, green: 64/255, blue: 64/255).opacity(0.6))
                    .frame(width: 80, height: 12)
            }
            .frame(width: 160)
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

// MARK: - Preview
struct ExploreEventsView_Previews: PreviewProvider {
    static var previews: some View {
        ExploreEventsView()
            .preferredColorScheme(.dark)
    }
}
