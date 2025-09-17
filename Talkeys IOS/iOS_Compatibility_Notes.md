# iOS Version Compatibility Notes

## Current Implementation Compatibility

### iOS 15.0+ Features Used:
- `async/await` syntax (EventRepository)
- `@MainActor` (EventRepository)  
- `.refreshable` modifier (ExploreEventsView - with fallback)
- URLSession async methods

### iOS 13.0+ Features Used:
- `@StateObject` (ExploreEventsView)
- `@Published` (NetworkConfig, EventRepository)
- SwiftUI LazyVGrid, LazyVStack
- Combine framework

### Compatibility Handled:
- ✅ `.tint` replaced with `.accentColor` (iOS 13+ compatible)
- ✅ `.presentationDetents` removed (was iOS 16+ only)
- ✅ `.refreshable` wrapped in version check with fallback

## Recommended Minimum Deployment Target

**Recommendation: iOS 15.0**

### Why iOS 15.0?
- Enables full async/await support for clean API calls
- @MainActor for thread-safe UI updates
- Native pull-to-refresh support
- Better performance and stability
- Still supports 90%+ of active iOS devices

### To Set iOS 15.0 Minimum:

1. **In Xcode Project Settings:**
   - Select your project in the navigator
   - Go to "Deployment Target" 
   - Set to iOS 15.0

2. **Alternative: iOS 14.0 with Compatibility Layer:**
   If you need iOS 14 support, you can:
   - Replace async/await with completion handlers
   - Remove @MainActor and use DispatchQueue.main
   - Use traditional networking with URLSession completion handlers

## Current API Integration Status

✅ **Fully Integrated with Talkeys Official API:**
- Base URL: `https://api.talkeys.xyz/`
- Endpoints: `/getEvents`, `/getEventById/{id}`
- Models match Android EventResponse exactly
- Authentication headers included
- Caching implemented (5-minute TTL)
- Error handling with retry logic

## Performance Features

✅ **Implemented:**
- Local caching (NSCache)
- Pull-to-refresh
- Lazy loading of UI elements
- Network connectivity monitoring
- Automatic cache expiry
- Optimistic UI updates

## Next Steps

1. **Set deployment target to iOS 15.0** (recommended)
2. **Test API connectivity** with real backend
3. **Add authentication token management** if needed
4. **Configure network security** (App Transport Security)
5. **Add offline support** if required

## Network Configuration

The app is configured to call the production Talkeys API:
- Production URL: `https://api.talkeys.xyz/`
- Timeout: 30 seconds
- Auth header: `Bearer {token}` (from UserDefaults)
- Platform header: `iOS`

Make sure your backend API is accessible from iOS devices and CORS is properly configured.
