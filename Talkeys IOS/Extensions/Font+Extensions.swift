import SwiftUI

extension Font {
    // MARK: - Urbanist Font Family
    
    /// Primary app font - Urbanist Regular
    static func urbanist(size: CGFloat) -> Font {
        return Font.custom("Urbanist-Regular", size: size)
    }
    
    // MARK: - Predefined Font Styles
    
    /// Large title - 34pt Urbanist
    static var urbanistLargeTitle: Font {
        return .urbanist(size: 34)
    }
    
    /// Title 1 - 28pt Urbanist
    static var urbanistTitle1: Font {
        return .urbanist(size: 28)
    }
    
    /// Title 2 - 22pt Urbanist
    static var urbanistTitle2: Font {
        return .urbanist(size: 22)
    }
    
    /// Title 3 - 20pt Urbanist
    static var urbanistTitle3: Font {
        return .urbanist(size: 20)
    }
    
    /// Headline - 17pt Urbanist
    static var urbanistHeadline: Font {
        return .urbanist(size: 17)
    }
    
    /// Body - 17pt Urbanist
    static var urbanistBody: Font {
        return .urbanist(size: 17)
    }
    
    /// Callout - 16pt Urbanist
    static var urbanistCallout: Font {
        return .urbanist(size: 16)
    }
    
    /// Subheadline - 15pt Urbanist
    static var urbanistSubheadline: Font {
        return .urbanist(size: 15)
    }
    
    /// Footnote - 13pt Urbanist
    static var urbanistFootnote: Font {
        return .urbanist(size: 13)
    }
    
    /// Caption 1 - 12pt Urbanist
    static var urbanistCaption1: Font {
        return .urbanist(size: 12)
    }
    
    /// Caption 2 - 11pt Urbanist
    static var urbanistCaption2: Font {
        return .urbanist(size: 11)
    }
    
    // MARK: - Custom App Styles
    
    /// Button text - 16pt Urbanist
    static var urbanistButton: Font {
        return .urbanist(size: 16)
    }
    
    /// Navigation title - 20pt Urbanist
    static var urbanistNavTitle: Font {
        return .urbanist(size: 20)
    }
    
    /// Card title - 18pt Urbanist
    static var urbanistCardTitle: Font {
        return .urbanist(size: 18)
    }
    
    /// Small text - 14pt Urbanist
    static var urbanistSmall: Font {
        return .urbanist(size: 14)
    }
}

// MARK: - Font Utility Functions
extension Font {
    /// Check if Urbanist font is available
    static func isUrbanistAvailable() -> Bool {
        return UIFont(name: "Urbanist-Regular", size: 12) != nil
    }
    
    /// Get all available font names (useful for debugging)
    static func printAvailableFonts() {
        for family in UIFont.familyNames.sorted() {
            let names = UIFont.fontNames(forFamilyName: family)
            print("Family: \(family) Font names: \(names)")
        }
    }
}
