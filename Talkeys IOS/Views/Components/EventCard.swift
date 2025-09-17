import SwiftUI

// MARK: - Event Model (matching Talkeys Official Android structure)
struct EventResponse: Codable, Hashable, Identifiable {
    let _id: String
    let name: String
    let category: String
    let ticketPrice: TicketPrice // Handles both Int and String from API
    let mode: String
    let location: String?
    let duration: String
    let slots: Int
    let visibility: String
    let startDate: String
    let startTime: String
    let endRegistrationDate: String?
    let totalSeats: TotalSeats // Handles both Int and String from API
    let eventDescription: String?
    let photographs: [String]?
    let prizes: String?
    let isTeamEvent: Bool
    let isPaid: Bool
    let isLive: Bool
    let organizerName: String?
    let organizerEmail: String?
    let organizerContact: String?
    
    // Computed property for SwiftUI Identifiable
    var id: String { _id }
    
    // Helper computed properties for backward compatibility
    var dateTime: String {
        return startDate
    }
    
    var description: String? {
        return eventDescription
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(_id)
    }
    
    static func == (lhs: EventResponse, rhs: EventResponse) -> Bool {
        return lhs._id == rhs._id
    }
}

// MARK: - Helper Types for API Compatibility
enum TicketPrice: Codable, Hashable {
    case int(Int)
    case string(String)
    case double(Double)
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            self = .int(intValue)
        } else if let doubleValue = try? container.decode(Double.self) {
            self = .double(doubleValue)
        } else if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else {
            throw DecodingError.typeMismatch(TicketPrice.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected Int, Double, or String"))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .int(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        }
    }
    
    var doubleValue: Double? {
        switch self {
        case .int(let value):
            return Double(value)
        case .double(let value):
            return value
        case .string(let value):
            return Double(value)
        }
    }
}

enum TotalSeats: Codable, Hashable {
    case int(Int)
    case string(String)
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            self = .int(intValue)
        } else if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else {
            throw DecodingError.typeMismatch(TotalSeats.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected Int or String"))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .int(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        }
    }
    
    var intValue: Int? {
        switch self {
        case .int(let value):
            return value
        case .string(let value):
            return Int(value)
        }
    }
}

// MARK: - Main Event Card
struct EventCard: View {
    let event: EventResponse
    let onClick: () -> Void
    var isCenter: Bool = false
    var isFocused: Bool = true
    
    // Animation states
    @State private var isPressed = false
    @State private var rotationY: Double = -1.5
    @State private var isVisible = false
    @State private var slideOffset: CGFloat = 100
    @State private var entranceAlpha: Double = 0
    
    // Calculated dimensions
    private var cardWidth: CGFloat { isFocused ? 165 : 130 }
    private var cardHeight: CGFloat { isFocused ? 286 : 247 }
    private var imageHeight: CGFloat { isFocused ? 165 : 130 }
    
    var body: some View {
        VStack(spacing: 0) {
            // Image Section
            AsyncImage(url: URL(string: event.photographs?.first ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color(red: 167/255, green: 167/255, blue: 167/255))
            }
            .frame(width: cardWidth - 4, height: imageHeight)
            .clipped()
            .cornerRadius(8.18715, corners: [.topLeft, .topRight])
            
            // Content Section
            VStack(alignment: .leading, spacing: 6) {
                // Title
                Text(event.name)
                    .font(.custom("Urbanist-Regular", size: isFocused ? 14 : 12))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Location Row
                HStack(alignment: .center, spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                    
                    Text(event.location ?? "Location not available")
                        .font(.system(size: isFocused ? 10 : 9))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                
                // Date Row
                HStack(alignment: .center, spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                    
                    Text("\(formatDate(event.startDate)) | \(event.startTime)")
                        .font(.system(size: isFocused ? 10 : 9))
                        .foregroundColor(.white)
                }
                
                // Bottom Tags Row
                HStack(spacing: 6) {
                    // Price Tag
                    TagView(
                        text: {
                            let priceValue = event.ticketPrice.doubleValue ?? 0.0
                            return priceValue == 0.0 ? "Free" : "₹\(Int(priceValue))"
                        }(),
                        isFocused: isFocused
                    )
                    
                    // Category Tag
                    TagView(
                        text: event.category,
                        isFocused: isFocused
                    )
                    
                    Spacer()
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: cardWidth, height: cardHeight)
        .background(Color(red: 38/255, green: 38/255, blue: 38/255))
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color(red: 112/255, green: 60/255, blue: 160/255), lineWidth: 2)
        )
        // Tap Animation
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0), value: isPressed)
        // 3D Rotation for center card
        .rotation3DEffect(
            .degrees(isCenter ? rotationY : 0),
            axis: (x: 0, y: 1, z: 0)
        )
        // Entrance Animation
        .offset(y: slideOffset)
        .opacity(entranceAlpha)
        .onTapGesture {
            onClick()
        }
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .onAppear {
            // Entrance animation
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)) {
                slideOffset = 0
            }
            withAnimation(.easeInOut(duration: 0.6)) {
                entranceAlpha = 1.0
            }
            
            // 3D rotation animation for center card
            if isCenter {
                withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
                    rotationY = 1.5
                }
            }
        }
    }
}

// MARK: - Tag View Component
struct TagView: View {
    let text: String
    let isFocused: Bool
    
    var body: some View {
        Text(text)
            .font(.system(size: isFocused ? 9 : 8, weight: .semibold))
            .foregroundColor(.white)
            .frame(width: 63, height: 24)
            .background(
                Color(red: 112/255, green: 60/255, blue: 160/255).opacity(0.3)
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(red: 220/255, green: 182/255, blue: 255/255), lineWidth: 1)
            )
    }
}

// MARK: - Skeleton Loading Card
struct SkeletonEventCard: View {
    var isFocused: Bool = true
    
    @State private var shimmerOffset: CGFloat = -200
    @State private var pulseAlpha: Double = 0.3
    @State private var pulseScale: CGFloat = 1.0
    
    private var cardWidth: CGFloat { isFocused ? 165 : 130 }
    private var cardHeight: CGFloat { isFocused ? 286 : 247 }
    private var imageHeight: CGFloat { isFocused ? 165 : 130 }
    
    var body: some View {
        VStack(spacing: 0) {
            // Image Skeleton
            Rectangle()
                .fill(Color(red: 64/255, green: 64/255, blue: 64/255).opacity(pulseAlpha))
                .frame(width: cardWidth - 4, height: imageHeight)
                .cornerRadius(8.18715, corners: [.topLeft, .topRight])
                .shimmer(offset: shimmerOffset)
            
            // Content Skeleton
            VStack(alignment: .leading, spacing: 6) {
                // Title skeleton
                VStack(alignment: .leading, spacing: 6) {
                    SkeletonBox(width: cardWidth * 0.9, height: isFocused ? 16 : 14, alpha: pulseAlpha, shimmerOffset: shimmerOffset)
                    SkeletonBox(width: cardWidth * 0.7, height: isFocused ? 16 : 14, alpha: pulseAlpha * 0.8, shimmerOffset: shimmerOffset)
                }
                
                Spacer().frame(height: 6)
                
                // Location row skeleton
                HStack(spacing: 4) {
                    SkeletonBox(width: 12, height: 12, alpha: pulseAlpha * 0.6, shimmerOffset: shimmerOffset, cornerRadius: 2)
                    SkeletonBox(width: 80, height: 10, alpha: pulseAlpha * 0.7, shimmerOffset: shimmerOffset)
                    Spacer()
                }
                
                Spacer().frame(height: 6)
                
                // Date row skeleton
                HStack(spacing: 4) {
                    SkeletonBox(width: 12, height: 12, alpha: pulseAlpha * 0.6, shimmerOffset: shimmerOffset, cornerRadius: 2)
                    SkeletonBox(width: 90, height: 10, alpha: pulseAlpha * 0.7, shimmerOffset: shimmerOffset)
                    Spacer()
                }
                
                Spacer().frame(height: 6)
                
                // Tags skeleton
                HStack(spacing: 6) {
                    SkeletonBox(width: 63, height: 24, alpha: pulseAlpha * 0.5, shimmerOffset: shimmerOffset, cornerRadius: 16)
                    SkeletonBox(width: 63, height: 24, alpha: pulseAlpha * 0.5, shimmerOffset: shimmerOffset, cornerRadius: 16)
                    Spacer()
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: cardWidth, height: cardHeight)
        .background(Color(red: 38/255, green: 38/255, blue: 38/255))
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color(red: 112/255, green: 60/255, blue: 160/255).opacity(0.3), lineWidth: 2)
        )
        .scaleEffect(pulseScale)
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // Shimmer animation
        withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
            shimmerOffset = 1000
        }
        
        // Pulse alpha animation
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulseAlpha = 0.7
        }
        
        // Pulse scale animation
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            pulseScale = 1.01
        }
    }
}

// MARK: - Skeleton Box Component
struct SkeletonBox: View {
    let width: CGFloat
    let height: CGFloat
    let alpha: Double
    let shimmerOffset: CGFloat
    var cornerRadius: CGFloat = 4
    
    var body: some View {
        Rectangle()
            .fill(Color(red: 64/255, green: 64/255, blue: 64/255).opacity(alpha))
            .frame(width: width, height: height)
            .cornerRadius(cornerRadius)
            .shimmer(offset: shimmerOffset)
    }
}

// MARK: - Shimmer Effect
struct ShimmerEffect: ViewModifier {
    let offset: CGFloat
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color(red: 112/255, green: 60/255, blue: 160/255).opacity(0.1),
                        Color.white.opacity(0.2),
                        Color(red: 112/255, green: 60/255, blue: 160/255).opacity(0.1),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: offset)
                .clipped()
            )
    }
}

extension View {
    func shimmer(offset: CGFloat) -> some View {
        self.modifier(ShimmerEffect(offset: offset))
    }
}

// MARK: - Corner Radius Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Date Formatting Helper
func formatDate(_ dateString: String) -> String {
    let datePart = dateString.contains("T") ? String(dateString.split(separator: "T")[0]) : dateString
    let parts = datePart.split(separator: "-")
    
    guard parts.count >= 3 else { return dateString }
    
    let year = String(parts[0])
    let monthNumber = String(parts[1])
    let dayNumber = String(parts[2])
    
    let month: String
    switch monthNumber {
    case "01": month = "Jan"
    case "02": month = "Feb"
    case "03": month = "Mar"
    case "04": month = "Apr"
    case "05": month = "May"
    case "06": month = "Jun"
    case "07": month = "Jul"
    case "08": month = "Aug"
    case "09": month = "Sep"
    case "10": month = "Oct"
    case "11": month = "Nov"
    case "12": month = "Dec"
    default: month = "Month"
    }
    
    let day = Int(dayNumber)?.description ?? dayNumber
    return "\(day) \(month) \(year)"
}

// MARK: - Usage Example
struct EventCardPreview: View {
    let sampleEvent = EventResponse(
        _id: "sample123",
        name: "Sample Event Title That Might Be Long",
        category: "Music",
        ticketPrice: .double(500.0),
        mode: "Online",
        location: "Sample Location",
        duration: "2 hours",
        slots: 100,
        visibility: "public",
        startDate: "2025-02-12T18:00:00.000Z",
        startTime: "6:00 PM",
        endRegistrationDate: "2025-02-11T23:59:59.000Z",
        totalSeats: .int(100),
        eventDescription: "A sample event description",
        photographs: ["https://example.com/image.jpg"],
        prizes: "Cash Prize",
        isTeamEvent: false,
        isPaid: true,
        isLive: true,
        organizerName: "Sample Organizer",
        organizerEmail: "organizer@example.com",
        organizerContact: "+1234567890"
    )
    
    var body: some View {
        VStack(spacing: 20) {
            // Regular Event Card
            EventCard(event: sampleEvent, onClick: {
                print("Event card tapped!")
            }, isCenter: false, isFocused: true)
            
            // Center Event Card with 3D rotation
            EventCard(event: sampleEvent, onClick: {
                print("Center event card tapped!")
            }, isCenter: true, isFocused: true)
            
            // Skeleton Loading Card
            SkeletonEventCard(isFocused: true)
        }
        .padding()
        .background(Color.black)
    }
}
