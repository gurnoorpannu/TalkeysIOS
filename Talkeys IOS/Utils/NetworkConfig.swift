import Foundation
import Network

// MARK: - Network Configuration
class NetworkConfig {
    static let shared = NetworkConfig()
    
    // API Configuration matching Talkeys Official
    struct API {
        static let baseURL = "https://api.talkeys.xyz/"
        static let timeoutInterval: TimeInterval = 30.0
    }
    
    // Network monitoring
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    @Published var isConnected = false
    
    private init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
    }
}

// MARK: - Network Utilities
class NetworkUtils {
    
    /// Check if the device has internet connectivity
    static var isConnected: Bool {
        return NetworkConfig.shared.isConnected
    }
    
    /// Create a URLRequest with common headers
    static func createRequest(for urlString: String, method: HTTPMethod = .GET) -> URLRequest? {
        guard let url = URL(string: urlString) else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.timeoutInterval = NetworkConfig.API.timeoutInterval
        
        // Common headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("iOS", forHTTPHeaderField: "Platform")
        request.setValue(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0", forHTTPHeaderField: "App-Version")
        
        // Add authorization header if available
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        return request
    }
    
    /// Handle common API responses and errors
    static func handleResponse<T: Codable>(_ data: Data, _ response: URLResponse, responseType: T.Type) throws -> T {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        // Log response for debugging
        #if DEBUG
        if let responseString = String(data: data, encoding: .utf8) {
            print("API Response (\(httpResponse.statusCode)): \(responseString)")
        }
        #endif
        
        // Handle different status codes
        switch httpResponse.statusCode {
        case 200...299:
            // Success - decode the response
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(responseType, from: data)
            } catch {
                print("Decoding error: \(error)")
                throw APIError.decodingError(error)
            }
            
        case 401:
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        case 500...599:
            throw APIError.serverError(httpResponse.statusCode)
        default:
            throw APIError.serverError(httpResponse.statusCode)
        }
    }
}

// MARK: - HTTP Methods
enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

// MARK: - Extended API Errors
extension APIError {
    static let notFound = APIError.serverError(404)
    
    var isNetworkError: Bool {
        switch self {
        case .networkError, .invalidURL, .invalidResponse:
            return true
        default:
            return false
        }
    }
    
    var isServerError: Bool {
        switch self {
        case .serverError:
            return true
        default:
            return false
        }
    }
    
    var shouldRetry: Bool {
        switch self {
        case .networkError, .serverError:
            return true
        case .unauthorized, .decodingError:
            return false
        default:
            return true
        }
    }
}

// MARK: - Request Builder
class RequestBuilder {
    private var baseURL: String
    private var endpoint: String = ""
    private var method: HTTPMethod = .GET
    private var headers: [String: String] = [:]
    private var queryParameters: [String: String] = [:]
    private var body: Data?
    
    init(baseURL: String = NetworkConfig.API.baseURL) {
        self.baseURL = baseURL
    }
    
    func endpoint(_ endpoint: String) -> RequestBuilder {
        self.endpoint = endpoint
        return self
    }
    
    func method(_ method: HTTPMethod) -> RequestBuilder {
        self.method = method
        return self
    }
    
    func header(_ key: String, value: String) -> RequestBuilder {
        headers[key] = value
        return self
    }
    
    func queryParameter(_ key: String, value: String) -> RequestBuilder {
        queryParameters[key] = value
        return self
    }
    
    func body(_ body: Data) -> RequestBuilder {
        self.body = body
        return self
    }
    
    func body<T: Codable>(_ object: T) -> RequestBuilder {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            self.body = try encoder.encode(object)
        } catch {
            print("Failed to encode body: \(error)")
        }
        return self
    }
    
    func build() -> URLRequest? {
        var urlString = baseURL + endpoint
        
        // Add query parameters
        if !queryParameters.isEmpty {
            let queryString = queryParameters.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
            urlString += "?\(queryString)"
        }
        
        guard let url = URL(string: urlString) else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.timeoutInterval = NetworkConfig.API.timeoutInterval
        
        // Set headers
        headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        
        // Set default headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add auth token if available
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Set body
        request.httpBody = body
        
        return request
    }
}
