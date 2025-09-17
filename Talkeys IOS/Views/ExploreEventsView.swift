import SwiftUI
import Foundation

// MARK: - Explore Events View
struct ExploreEventsView: View {
    @StateObject private var eventRepository = EventRepository.shared
    @State private var groupedEvents: [String: [EventResponse]] = [:]
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    @State private var showFilterSheet = false
    @State private var showLiveEvents = false
    
    // Sample categories for filtering
    private let categories = ["All", "Music", "Sports", "Food", "Art", "Tech", "Comedy", "Business"]
    
    // Grid layout configuration
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
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
                    // Header with search and filter
                    headerView
                    
                    // Events Grid or Category Sections
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
        .sheet(isPresented: $showFilterSheet) {
            filterSheetView
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 16) {
            // Title and Filter Button
            HStack {
                Text("Explore Events")
                    .font(.custom("Urbanist-Regular", size: 28))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    showFilterSheet = true
                }) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.system(size: 24))
                        .foregroundColor(Color(red: 112/255, green: 60/255, blue: 160/255))
                }
            }
            
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
            
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .font(.system(size: 16))
                
                TextField("Search events...", text: $searchText)
                    .font(.custom("Urbanist-Regular", size: 16))
                    .foregroundColor(.white)
                    .accentColor(Color(red: 112/255, green: 60/255, blue: 160/255))
                    .onChange(of: searchText) { _ in
                        updateGroupedEvents()
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        updateGroupedEvents()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: 16))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(red: 38/255, green: 38/255, blue: 38/255))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(red: 60/255, green: 60/255, blue: 60/255), lineWidth: 1)
            )
            
            // Category Filter Pills
            if selectedCategory != "All" {
                HStack {
                    Text("Filtered by: ")
                        .font(.custom("Urbanist-Regular", size: 14))
                        .foregroundColor(.gray)
                    
                    Button(action: {
                        selectedCategory = "All"
                        updateGroupedEvents()
                    }) {
                        HStack(spacing: 4) {
                            Text(selectedCategory)
                                .font(.custom("Urbanist-Regular", size: 14))
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                            
                            Image(systemName: "xmark")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(red: 112/255, green: 60/255, blue: 160/255))
                        .cornerRadius(16)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 16)
    }
    
    // MARK: - Events Content View
    private var eventsContentView: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
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
            }
            .padding(.horizontal, 20)
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
        
        private let columns = [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                // Category Title
                Text(category)
                    .font(.custom("Urbanist-Regular", size: 18))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                // Events Grid
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(events.indices, id: \.self) { index in
                        let event = events[index]
                        
                        EventCard(
                            event: convertToEventCard(event),
                            onClick: {
                                onEventTapped(event)
                            },
                            isCenter: false,
                            isFocused: true
                        )
                        .animation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0).delay(Double(index) * 0.05), value: events.count)
                    }
                }
            }
        }
        
        // Convert EventResponse to EventCard compatible format
        private func convertToEventCard(_ event: EventResponse) -> EventResponse {
            return event // Since both models are now the same, just return the event
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .accentColor(Color(red: 112/255, green: 60/255, blue: 160/255))
            
            Text("Loading events...")
                .font(.custom("Urbanist-Regular", size: 16))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
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
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
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
                .background(Color(red: 112/255, green: 60/255, blue: 160/255))
                .cornerRadius(8)
                .foregroundColor(.white)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 32)
        .padding(.top, 100)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Text(showLiveEvents ? "No live events available" : "No past events available")
                .font(.custom("Urbanist-Regular", size: 18))
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text("Check back later for new events")
                .font(.custom("Urbanist-Regular", size: 16))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
    
    // MARK: - Filter Sheet
    private var filterSheetView: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Filter Events")
                    .font(.custom("Urbanist-Regular", size: 24))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Categories")
                        .font(.custom("Urbanist-Regular", size: 18))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(categories, id: \.self) { category in
                            Button(action: {
                                selectedCategory = category
                            }) {
                                Text(category)
                                    .font(.custom("Urbanist-Regular", size: 16))
                                    .fontWeight(.medium)
                                    .foregroundColor(selectedCategory == category ? .white : .gray)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        selectedCategory == category ?
                                        Color(red: 112/255, green: 60/255, blue: 160/255) :
                                        Color(red: 38/255, green: 38/255, blue: 38/255)
                                    )
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(
                                                selectedCategory == category ?
                                                Color(red: 112/255, green: 60/255, blue: 160/255) :
                                                Color(red: 60/255, green: 60/255, blue: 60/255),
                                                lineWidth: 1
                                            )
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer()
                
                // Apply Button
                Button(action: {
                    updateGroupedEvents()
                    showFilterSheet = false
                }) {
                    Text("Apply Filters")
                        .font(.custom("Urbanist-Regular", size: 18))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(red: 112/255, green: 60/255, blue: 160/255))
                        .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(
                Image("background")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
                    .clipped()
            )
            .navigationBarHidden(true)
        }
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
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(
                        isSelected ?
                        Color(red: 112/255, green: 60/255, blue: 160/255) :
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
        
        // Filter by category
        if selectedCategory != "All" {
            filtered = filtered.filter { event in
                event.category.lowercased() == selectedCategory.lowercased()
            }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { event in
                event.name.lowercased().contains(searchText.lowercased()) ||
                (event.location?.lowercased().contains(searchText.lowercased()) == true) ||
                event.category.lowercased().contains(searchText.lowercased()) ||
                (event.eventDescription?.lowercased().contains(searchText.lowercased()) == true) ||
                (event.organizerName?.lowercased().contains(searchText.lowercased()) == true)
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
