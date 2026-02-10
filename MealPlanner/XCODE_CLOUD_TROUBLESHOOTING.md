# Xcode Cloud "Preparing build for App Store Connect failed" Troubleshooting

## Error Description
Build succeeds, all artifacts created, but fails at "Preparing build for App Store Connect" step with no visible errors in logs.

## Checklist to Fix

### 1. ✅ Verify App Exists in App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Click **Apps**
3. **Check if your app exists** with bundle ID `net.usersource.MealPlanner`

**If app doesn't exist:**
- Click **+** to create new app
- Bundle ID: `net.usersource.MealPlanner`
- Name: Choose a unique name (e.g., "Simple Meal Planner", "Weekly Meal Planner")
- Platform: iOS
- Language: English

### 2. ✅ Check Xcode Cloud Workflow Settings

1. Go to **App Store Connect** → **Your App** → **Xcode Cloud**
2. Click on your workflow
3. Check **Post-Actions**:
   - Should have "TestFlight Internal Testing" enabled
   - Or "App Store Connect" as destination
4. Check **Archive** settings:
   - Deployment Target: Should match your project (iOS 17.0+)
   - Signing: Automatic with your team selected

### 3. ✅ Verify Bundle Identifier Registration

1. Go to [developer.apple.com](https://developer.apple.com)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Click **Identifiers**
4. **Verify `net.usersource.MealPlanner` exists**

**If it doesn't exist:**
- Click **+** to add new identifier
- Select **App IDs**
- Description: MealPlanner
- Bundle ID: `net.usersource.MealPlanner`
- Capabilities: (select any you need)

### 4. ✅ Check Export Compliance (Already Set)

Your project already has:
```
INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO
```
This is correct for apps that don't use encryption beyond what iOS provides.

### 5. ✅ Verify Provisioning Profiles

1. In **App Store Connect** → **Xcode Cloud** → **Workflow**
2. Under **Archive** → **Signing**
3. Ensure provisioning profiles are generated:
   - Development
   - Ad Hoc (for TestFlight)
   - App Store

### 6. ✅ Check for Missing Metadata

Sometimes App Store Connect needs basic metadata before accepting builds:

1. Go to **App Store Connect** → **Your App**
2. Click **App Information**
3. Fill in required fields:
   - Privacy Policy URL (can be placeholder for now)
   - Category
   - Content Rights

### 7. ✅ Review Xcode Cloud Logs Carefully

Look for these specific sections in the logs:
- "Export Archive" - Should show success
- "Upload to App Store Connect" - This is where it likely fails
- Look for any warnings about:
  - Missing entitlements
  - Provisioning profile issues
  - Bundle identifier mismatches

### 8. ✅ Try Manual Upload First

To isolate the issue:
1. Archive locally in Xcode (Product → Archive)
2. Try uploading to App Store Connect manually
3. If this works, the issue is Xcode Cloud configuration
4. If this fails, the issue is with your app/account setup

## Most Likely Cause

Based on "no errors in logs but fails at prepare step", the most common cause is:

**The app doesn't exist in App Store Connect yet**

Create the app in App Store Connect first, then re-run the Xcode Cloud build.

## After Fixing

1. Make any necessary changes
2. Commit and push to trigger new build
3. Monitor the "Preparing build for App Store Connect" step specifically
4. Check if build appears in TestFlight after success
