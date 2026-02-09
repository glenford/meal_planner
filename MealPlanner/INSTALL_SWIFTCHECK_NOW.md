# Install SwiftCheck - Step by Step Instructions

## Quick Installation via Swift Package Manager (5 minutes)

### Step 1: Open Xcode
- Open `MyApp.xcodeproj` in Xcode

### Step 2: Add Package Dependency
1. In Xcode, click on the **MyApp** project in the Project Navigator (left sidebar)
2. Select the **MyApp** project (blue icon at the top)
3. In the main editor area, click on the **Package Dependencies** tab
4. Click the **"+"** button at the bottom left

### Step 3: Add SwiftCheck Repository
1. In the search field, paste: `https://github.com/typelift/SwiftCheck.git`
2. Press Enter or click "Add Package"
3. For "Dependency Rule", select **"Up to Next Major Version"**
4. Ensure the version shows `0.12.0` or higher
5. Click **"Add Package"**

### Step 4: Add to Test Target
1. A dialog will appear asking which target to add SwiftCheck to
2. **Check the box next to "MyAppTests"** (NOT MyApp)
3. Click **"Add Package"**

### Step 5: Verify Installation
1. Wait for Xcode to download and integrate the package (progress bar at top)
2. You should see "SwiftCheck" appear under "Package Dependencies" in the Project Navigator
3. Build the test target: **Cmd+Shift+U** or Product > Build For > Testing

## Verification Test

Once installed, you can verify by adding this to any test file:

```swift
import SwiftCheck

func testSwiftCheckWorks() {
    property("Addition is commutative") <- forAll { (x: Int, y: Int) in
        return x + y == y + x
    }
}
```

## Troubleshooting

**If you don't see "Package Dependencies" tab:**
- Make sure you selected the PROJECT (blue icon), not the target
- You might be using an older Xcode version - try File > Add Packages instead

**If the package fails to download:**
- Check your internet connection
- Try File > Packages > Reset Package Caches
- Then retry adding the package

**If you get build errors:**
- Make sure SwiftCheck is added to MyAppTests target, not MyApp target
- Clean build folder: Shift+Cmd+K
- Rebuild: Cmd+B

## Ready to Continue

Once SwiftCheck is installed and builds successfully, let me know and I'll implement the property tests for MealRepository!
