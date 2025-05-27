# Google Maps API Troubleshooting Guide

## Your API Key

```
AIzaSyCyFbbtuqs1CIezXzXPkE1HA7nCh83uXWY
```

## Quick Test Steps

### 1. Test the Map Display

1. Open your app
2. Go to Settings
3. Scroll down to the "About" section
4. Tap "Test Google Maps" button
5. Check if the map loads with a marker in Tunis

### 2. Check Console Logs

When testing, watch the console for these messages:

- ✅ `Google Maps loaded successfully!` = API key works
- ❌ Gray screen = API configuration issue

## Common Issues & Solutions

### Issue 1: Gray Screen (Most Common)

**Symptoms:** Map area shows gray/blank screen **Causes:**

1. **API not enabled** - Most likely cause
2. **API key restrictions**
3. **Billing not enabled**

**Solution:**

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project
3. Go to "APIs & Services" > "Library"
4. Enable these APIs:
   - **Maps SDK for Android** ✅
   - **Maps SDK for iOS** ✅
   - **Places API** ✅
   - **Geocoding API** ✅ (recommended)
   - **Directions API** ✅ (for navigation)

### Issue 2: API Key Restrictions

**Check your API key restrictions:**

1. Go to "APIs & Services" > "Credentials"
2. Click on your API key
3. Under "API restrictions":
   - Either select "Don't restrict key" (for testing)
   - Or add the specific APIs listed above

### Issue 3: Application Restrictions

**For production, set up application restrictions:**

1. **Android apps:**

   - Package name: `com.example.medical_app` (check your
     android/app/build.gradle)
   - SHA-1 certificate fingerprint (get from your keystore)

2. **iOS apps:**
   - Bundle identifier: check your ios/Runner.xcodeproj

### Issue 4: Billing Account

**Google Maps requires billing to be enabled:**

1. Go to "Billing" in Google Cloud Console
2. Link a billing account to your project
3. Google provides $200 free credits monthly

## Testing Commands

### Test API Key Directly

Open this URL in your browser (replace with your coordinates):

```
https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=36.8189,10.1657&radius=1000&type=hospital&key=AIzaSyCyFbbtuqs1CIezXzXPkE1HA7nCh83uXWY
```

**Expected Response:**

- `"status": "OK"` = Working ✅
- `"status": "REQUEST_DENIED"` = API key issue ❌
- `"status": "OVER_QUERY_LIMIT"` = Billing issue ❌

## Debug Steps

### 1. Enable Detailed Logging

Add this to your main.dart:

```dart
import 'dart:developer' as developer;

void main() {
  // Enable detailed logging
  developer.log('Starting Medical App with Google Maps');
  runApp(MyApp());
}
```

### 2. Check Network Connectivity

Make sure your device/emulator has internet access.

### 3. Test on Different Devices

- Try on physical device vs emulator
- Test on both Android and iOS if possible

## Quick Fixes to Try

### 1. Clean and Rebuild

```bash
flutter clean
flutter pub get
flutter run
```

### 2. Update Dependencies

In pubspec.yaml, try updating:

```yaml
google_maps_flutter: ^2.15.0 # Latest version
```

### 3. Check Permissions

Make sure these permissions are in AndroidManifest.xml:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

## Expected Behavior

### When Working Correctly:

1. **Map Test Page:** Shows map of Tunis with a red marker
2. **Pharmacy Page:** Shows your location + nearby
   hospitals/pharmacies
3. **Console Logs:** Shows successful API calls and map creation

### When Not Working:

1. **Gray screen** instead of map
2. **Error messages** in console
3. **No places found** even in populated areas

## Next Steps

1. **First:** Try the "Test Google Maps" button in Settings
2. **If gray screen:** Check Google Cloud Console API settings
3. **If still issues:** Check the browser URL test above
4. **Contact support:** If all APIs are enabled but still not working

## API Usage Limits (Free Tier)

- **Maps SDK:** 28,000 loads per month
- **Places API:** $17 worth of free usage per month
- **Geocoding:** 40,000 requests per month

Your current usage should be well within free limits for testing.
