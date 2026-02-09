# Setting Up SwiftCheck for Property-Based Testing

This document provides instructions for adding SwiftCheck to the MyApp project for property-based testing.

## Option 1: Using Swift Package Manager (Recommended)

1. Open `MyApp.xcodeproj` in Xcode
2. Select the project in the Project Navigator
3. Select the "MyApp" target
4. Click on the "Package Dependencies" tab
5. Click the "+" button to add a package dependency
6. Enter the SwiftCheck repository URL: `https://github.com/typelift/SwiftCheck.git`
7. Select "Up to Next Major Version" with version `0.12.0` (or latest)
8. Click "Add Package"
9. Select "SwiftCheck" and add it to the "MyAppTests" target
10. Click "Add Package"

## Option 2: Using Carthage

If you prefer Carthage, add this to your `Cartfile`:

```
github "typelift/SwiftCheck" ~> 0.12.0
```

Then run:
```bash
carthage update --platform iOS
```

## Option 3: Manual Installation

1. Clone the SwiftCheck repository:
   ```bash
   git clone https://github.com/typelift/SwiftCheck.git
   ```

2. Drag the `SwiftCheck.xcodeproj` into your Xcode project
3. Add SwiftCheck as a dependency to your test target

## Verifying Installation

After installation, add this import to your test files:

```swift
import SwiftCheck
```

Create a simple property test to verify:

```swift
func testSwiftCheckInstalled() {
    property("Addition is commutative") <- forAll { (x: Int, y: Int) in
        return x + y == y + x
    }
}
```

## Configuration

SwiftCheck tests should be configured with a minimum of 100 iterations per property test as specified in the design document. You can configure this in your test setup:

```swift
override func setUp() {
    super.setUp()
    // Configure SwiftCheck for 100 iterations minimum
}
```

## Next Steps

Once SwiftCheck is installed, you can proceed with implementing property-based tests as outlined in the tasks:
- Task 3.2: Property tests for MealRepository
- Task 3.4: Property tests for AssignmentRepository
- Task 4.2: Property tests for FilterService
- Task 4.5: Property tests for PlannerService
- And more...

## Resources

- [SwiftCheck GitHub Repository](https://github.com/typelift/SwiftCheck)
- [SwiftCheck Documentation](https://github.com/typelift/SwiftCheck/blob/master/Documentation/README.md)
- [Property-Based Testing Guide](https://github.com/typelift/SwiftCheck/blob/master/Documentation/PropertyBasedTesting.md)
