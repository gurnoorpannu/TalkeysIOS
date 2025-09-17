import Foundation
import Combine

// MARK: - API Response Models (matching Talkeys Official Android structure)
struct EventListResponse: Codable {
    let status: String
    let data: EventData
}

struct EventData: Codable {
    let events: [EventResponse]
    let pagination: Pagination
}

struct Pagination: Codable {
    let total: Int
    let page: Int
    let pages: Int
    let limit: Int
}

// MARK: - Event API Service
class EventAPIService {
    static let shared = EventAPIService()
    private let baseURL = "https://api.talkeys.xyz/"
    
    private init() {}
    
    func getAllEvents() async throws -> [EventResponse] {
        guard let url = URL(string: "\(baseURL)getEvents") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authorization header if needed
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        do {
            let eventListResponse = try JSONDecoder().decode(EventListResponse.self, from: data)
            return eventListResponse.data.events
        } catch {
            print("JSON Decoding Error: \(error)")
            throw APIError.decodingError(error)
        }
    }
    
    func getEventById(_ eventId: String) async throws -> EventResponse {
        guard let url = URL(string: "\(baseURL)getEventById/\(eventId)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authorization header if needed
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        // For single event response, it might have a different structure
        // Adjust based on your API response structure
        do {
            let eventResponse = try JSONDecoder().decode(EventResponse.self, from: data)
            return eventResponse
        } catch {
            print("JSON Decoding Error: \(error)")
            throw APIError.decodingError(error)
        }
    }
}

// MARK: - Event Repository
class EventRepository: ObservableObject {
    static let shared = EventRepository()
    private let apiService = EventAPIService.shared
    
    @Published var events: [EventResponse] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let cache = NSCache<NSString, NSArray>()
    private let cacheExpiryTime: TimeInterval = 300 // 5 minutes
    private var lastFetchTime: Date?
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Fetch all events from API with caching support
    /// - Parameter forceRefresh: If true, bypasses cache and fetches fresh data
    func fetchAllEvents(forceRefresh: Bool = false) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        // Check cache first unless force refresh is requested
        if !forceRefresh, let cachedEvents = getCachedEvents() {
            await MainActor.run {
                self.events = cachedEvents
                self.isLoading = false
            }
            return
        }
        
        do {
            let fetchedEvents = try await apiService.getAllEvents()
            
            await MainActor.run {
                self.events = fetchedEvents
                self.isLoading = false
                self.cacheEvents(fetchedEvents)
                self.lastFetchTime = Date()
            }
            
            print("Successfully fetched \(fetchedEvents.count) events")
            
        } catch let apiError as APIError {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = apiError.localizedDescription
            }
            print("API Error: \(apiError)")
            
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "Failed to load events. Please try again."
            }
            print("Unexpected error: \(error)")
        }
    }
    
    /// Fetch event by ID
    /// - Parameter eventId: The ID of the event to fetch
    /// - Returns: EventResponse object
    func fetchEventById(_ eventId: String) async throws -> EventResponse {
        return try await apiService.getEventById(eventId)
    }
    
    /// Get live events only
    func getLiveEvents() -> [EventResponse] {
        return events.filter { $0.isLive == true }
    }
    
    /// Get past events only  
    func getPastEvents() -> [EventResponse] {
        return events.filter { $0.isLive != true }
    }
    
    /// Get events by category
    /// - Parameter category: The category to filter by
    /// - Returns: Array of events in the specified category
    func getEventsByCategory(_ category: String) -> [EventResponse] {
        return events.filter { 
            $0.category.lowercased() == category.lowercased() 
        }
    }
    
    /// Search events by text
    /// - Parameter searchText: The text to search for
    /// - Returns: Array of events matching the search criteria
    func searchEvents(_ searchText: String) -> [EventResponse] {
        guard !searchText.isEmpty else { return events }
        
        return events.filter { event in
            event.name.lowercased().contains(searchText.lowercased()) ||
            (event.location?.lowercased().contains(searchText.lowercased()) == true) ||
            event.category.lowercased().contains(searchText.lowercased()) ||
            (event.eventDescription?.lowercased().contains(searchText.lowercased()) == true) ||
            (event.organizerName?.lowercased().contains(searchText.lowercased()) == true)
        }
    }
    
    /// Get events grouped by category
    /// - Returns: Dictionary with category as key and array of events as value
    func getEventsGroupedByCategory() -> [String: [EventResponse]] {
        return Dictionary(grouping: events) { event in
            return event.category.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty == false
                ? event.category : "Uncategorized"
        }.filter { !$0.value.isEmpty }
    }
    
    // MARK: - Cache Management
    
    private func cacheEvents(_ events: [EventResponse]) {
        cache.setObject(events as NSArray, forKey: "all_events")
    }
    
    private func getCachedEvents() -> [EventResponse]? {
        // Check if cache is expired
        if let lastFetch = lastFetchTime,
           Date().timeIntervalSince(lastFetch) > cacheExpiryTime {
            cache.removeObject(forKey: "all_events")
            return nil
        }
        
        guard let cachedArray = cache.object(forKey: "all_events") as? [EventResponse] else {
            return nil
        }
        
        return cachedArray
    }
    
    /// Clear all cached data
    func clearCache() {
        cache.removeAllObjects()
        lastFetchTime = nil
    }
    
    /// Refresh events (force fetch from API)
    func refreshEvents() async {
        await fetchAllEvents(forceRefresh: true)
    }
}

// MARK: - API Error Handling
enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case noData
    case decodingError(Error)
    case serverError(Int)
    case networkError
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .noData:
            return "No data received"
        case .decodingError(let error):
            return "Failed to decode data: \(error.localizedDescription)"
        case .serverError(let statusCode):
            return "Server error with status code: \(statusCode)"
        case .networkError:
            return "Network connection error"
        case .unauthorized:
            return "Unauthorized access"
        }
    }
    
    var localizedDescription: String {
        return errorDescription ?? "Unknown error occurred"
    }
}
