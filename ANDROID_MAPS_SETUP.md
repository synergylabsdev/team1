# Android Maps Setup Guide

## Permissions Added

The following permissions have been added to `android/app/src/main/AndroidManifest.xml`:

1. **INTERNET** - Required for loading map tiles and data
2. **ACCESS_FINE_LOCATION** - Required for precise GPS location
3. **ACCESS_COARSE_LOCATION** - Required for network-based location
4. **ACCESS_NETWORK_STATE** - Required to check network connectivity

## Google Maps API Key Setup

### Step 1: Get Google Maps API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the following APIs:
   - Maps SDK for Android
   - Places API (optional, for future use)
4. Go to "Credentials" → "Create Credentials" → "API Key"
5. Copy your API key

### Step 2: Add API Key to AndroidManifest.xml

1. Open `android/app/src/main/AndroidManifest.xml`
2. Find the line:
   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="YOUR_API_KEY"/>
   ```
3. Replace `YOUR_API_KEY` with your actual API key

### Step 3: Restrict API Key (Recommended for Production)

1. In Google Cloud Console, go to your API key
2. Click "Edit" → "Application restrictions"
3. Select "Android apps"
4. Add your app's package name and SHA-1 certificate fingerprint
5. Click "Save"

### Getting SHA-1 Fingerprint

**For Debug builds:**
```bash
cd android
./gradlew signingReport
```

Look for the SHA1 value under `Variant: debug`

**For Release builds:**
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

## Testing

After adding the API key, rebuild the app:

```bash
flutter clean
flutter pub get
flutter run
```

The map should now load properly on Android devices.

## Troubleshooting

### Map not loading
- Verify API key is correct
- Check that Maps SDK for Android is enabled
- Ensure API key restrictions allow your app

### Location not working
- Check that location permissions are granted in device settings
- Verify `ACCESS_FINE_LOCATION` and `ACCESS_COARSE_LOCATION` are in manifest
- Test on a physical device (emulators may have location issues)

### Build errors
- Run `flutter clean` and rebuild
- Ensure `google_maps_flutter` is in `pubspec.yaml`
- Check that `compileSdk` is set to at least 33 in `build.gradle`

