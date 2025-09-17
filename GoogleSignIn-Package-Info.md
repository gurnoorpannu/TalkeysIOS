# Adding Google Sign-In SDK to Your Project

## 📦 Swift Package Manager Instructions

Since your project needs the Google Sign-In SDK, follow these steps to add it:

### 1. Open Xcode
- Open your `Talkeys IOS.xcodeproj` file in Xcode

### 2. Add Package Dependency
- In Xcode, go to **File → Add Package Dependencies...**
- Enter this URL: `https://github.com/google/GoogleSignIn-iOS`
- Click **Add Package**
- Select your target: `Talkeys IOS`
- Click **Add Package**

### 3. Verify Installation
- The Google Sign-In framework should now appear in your project navigator
- Build the project to ensure it compiles without errors

### 4. Alternative: Manual Installation
If Swift Package Manager doesn't work, you can:
- Download the GoogleSignIn framework from the official Google repository
- Drag it into your Xcode project
- Add it to your target's "Frameworks, Libraries, and Embedded Content"

## ⚠️ Important Notes

- **URL**: `https://github.com/google/GoogleSignIn-iOS`
- **Target**: Make sure to add it to the `Talkeys IOS` target only
- **Version**: Use the latest stable version (recommended)

Once you've added the package, the imports in your Swift files will work correctly.
