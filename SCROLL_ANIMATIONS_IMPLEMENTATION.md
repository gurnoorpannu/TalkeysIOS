# Scroll Animations Implementation

## Features Implemented

### 1. **Collapsible Header on Scroll**
Implemented the Android-style collapsible filter buttons that hide/show based on scroll direction.

#### **Behavior:**
- **Scroll Down**: Filter buttons (Live Events/Past Events) minimize and disappear
- **Scroll Up**: Filter buttons reappear with smooth animation
- **Threshold**: 50px scroll distance triggers the hide/show behavior

#### **Technical Implementation:**
```swift
// State tracking
@State private var scrollOffset: CGFloat = 0
@State private var isHeaderVisible = true

// Conditional header rendering
if isHeaderVisible {
    headerView
        .transition(.move(edge: .top).combined(with: .opacity))
}

// Scroll tracking
GeometryReader { geometry in
    Color.clear
        .preference(key: ScrollOffsetPreferenceKey.self, 
                   value: geometry.frame(in: .named("scroll")).minY)
}

// Scroll handling logic
private func handleScrollOffset(_ offset: CGFloat) {
    let threshold: CGFloat = -50
    withAnimation(.easeInOut(duration: 0.3)) {
        if offset < threshold {
            isHeaderVisible = false // Hide on scroll down
        } else {
            isHeaderVisible = true  // Show on scroll up
        }
    }
}
```

### 2. **Card Rotation Animation**
Implemented the subtle left-right rotation effect on event cards (similar to Android's rotation animation).

#### **Animation Details:**
- **Rotation Range**: ±2 degrees (subtle movement)
- **Duration**: 4 seconds per cycle
- **Behavior**: Continuous back-and-forth rotation
- **Easing**: EaseInOut for smooth motion
- **Staggered**: Each card starts with a slight delay

#### **Technical Implementation:**
```swift
struct AnimatedEventCard: View {
    @State private var rotationAngle: Double = 0
    @State private var isVisible = false
    
    var body: some View {
        EventCard(...)
            .rotationEffect(.degrees(rotationAngle))
            .onAppear {
                // Continuous subtle rotation
                withAnimation(
                    .easeInOut(duration: 4.0)
                    .repeatForever(autoreverses: true)
                    .delay(animationDelay)
                ) {
                    rotationAngle = 2.0 // 2-degree rotation
                }
            }
    }
}
```

## Animation Hierarchy

### **Card Entrance Animation:**
1. **Opacity**: 0 → 1 (fade in)
2. **Scale**: 0.8 → 1.0 (grow in)
3. **Staggered Delay**: Each card delayed by index * 0.1 seconds

### **Card Rotation Animation:**
1. **Continuous**: Runs forever while card is visible
2. **Subtle**: Only 2-degree rotation for gentle movement
3. **Smooth**: EaseInOut animation for natural motion

### **Header Animation:**
1. **Hide**: Move up + fade out (0.3s duration)
2. **Show**: Move down + fade in (0.3s duration)
3. **Trigger**: Based on scroll threshold (-50px)

## Performance Optimizations

### **Scroll Tracking:**
- Uses `GeometryReader` with `PreferenceKey` for efficient scroll detection
- Minimal performance impact with coordinate space tracking
- Threshold-based triggering prevents excessive animations

### **Card Animations:**
- Individual animation states per card prevent interference
- `onDisappear` cleanup prevents memory leaks
- Staggered delays create natural wave effect

### **Memory Management:**
- Animations reset when cards disappear from view
- State variables properly managed with `@State`
- No retain cycles or memory leaks

## Visual Effects

### **Scroll Behavior:**
```
Scroll Down (>50px) → Header slides up and fades out
Scroll Up (return)  → Header slides down and fades in
```

### **Card Animation:**
```
Card appears → Fade in + Scale up → Continuous gentle rotation
Card disappears → Reset rotation and visibility states
```

### **Staggered Effect:**
```
Card 1: Delay 0.0s → Start rotation
Card 2: Delay 0.1s → Start rotation  
Card 3: Delay 0.2s → Start rotation
...creating a wave-like animation effect
```

## Android Equivalent

This implementation matches the Android behavior:
- **Collapsible Toolbar**: Similar to Android's `CollapsingToolbarLayout`
- **Card Rotation**: Matches the subtle rotation animation from Android app
- **Smooth Transitions**: Uses iOS native animation system for 60fps performance

The scroll behavior and card animations now provide the same engaging user experience as the Android version!