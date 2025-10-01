# Events Screen Fixes

## Changes Made

### 1. **Default to Live Events**
- **Before**: App opened showing "Past Events" by default
- **After**: App now opens showing "Live Events" by default
- **Change**: Modified `@State private var showLiveEvents = false` to `true` in ExploreEventsView.swift

### 2. **Fixed Black Line Above Event Images**
The black line/spacing issue above event images was caused by several layout problems:

#### **Image Width Fix**
- **Before**: `frame(width: cardWidth - 4, height: imageHeight)` - created 2px gaps on each side
- **After**: `frame(width: cardWidth, height: imageHeight)` - image now fills full card width

#### **VStack Alignment Fix**
- **Before**: `VStack(spacing: 0)` - no explicit alignment
- **After**: `VStack(alignment: .leading, spacing: 0)` - proper left alignment

#### **Background and Clipping Fix**
- **Before**: Simple background color with separate cornerRadius
- **After**: Proper RoundedRectangle background with clipShape for clean edges

```swift
// Before
.background(Color(red: 38/255, green: 38/255, blue: 38/255))
.cornerRadius(15)

// After
.background(
    RoundedRectangle(cornerRadius: 15)
        .fill(Color(red: 38/255, green: 38/255, blue: 38/255))
)
.clipShape(RoundedRectangle(cornerRadius: 15))
```

## Files Modified

### `Talkeys IOS/Views/ExploreEventsView.swift`
- Changed default state to show Live Events first

### `Talkeys IOS/Views/Components/EventCard.swift`
- Fixed image width to eliminate black spacing
- Improved VStack alignment
- Enhanced background and clipping for cleaner edges

## Result

1. **Live Events Default**: Users now see live events immediately when opening the events screen
2. **Clean Event Cards**: No more black lines or unwanted spacing above event images
3. **Better Visual Alignment**: Event cards now have proper edge-to-edge image display

## Testing

To verify the fixes:
1. Open the events screen - should show "Live Events" tab selected by default
2. Check event cards - images should align perfectly with card edges, no black lines
3. Switch between Live/Past events - filtering should work correctly
4. Scroll through events - all cards should have consistent, clean appearance