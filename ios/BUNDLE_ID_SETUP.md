# iOS Bundle ID Setup

## Update Bundle ID to com.emanneul.knot

To update the iOS bundle ID, you need to:

1. **Open the project in Xcode:**
   ```bash
   open ios/Runner.xcworkspace
   ```
   (Not .xcodeproj - use .xcworkspace)

2. **In Xcode:**
   - Select the "Runner" project in the left sidebar
   - Select the "Runner" target
   - Go to "Signing & Capabilities" tab
   - Change "Bundle Identifier" to: `com.emanneul.knot`

3. **Or manually edit** (if you prefer):
   - Open `ios/Runner.xcodeproj/project.pbxproj` in a text editor
   - Find and replace: `PRODUCT_BUNDLE_IDENTIFIER = com.example.knot;`
   - With: `PRODUCT_BUNDLE_IDENTIFIER = com.emanneul.knot;`

## For Firebase

When adding iOS app in Firebase Console:
- Use bundle ID: `com.emanneul.knot`
- Download `GoogleService-Info.plist`
- Place in: `ios/Runner/GoogleService-Info.plist`
