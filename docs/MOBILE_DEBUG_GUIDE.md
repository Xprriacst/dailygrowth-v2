# 📱 Mobile Authentication Debug Guide

## Problem: Authentication works on web but fails on mobile

### Quick Diagnosis Steps

1. **Test Environment Variables**
   ```bash
   # Run with explicit environment variables
   ./scripts/build_mobile.sh debug-android
   # or
   ./scripts/build_mobile.sh debug-ios
   ```

2. **Check Console Logs**
   Look for these messages in the debug console:
   - `✅ App configuration validated successfully`
   - `🔧 Initializing Supabase...`
   - `📍 URL: https://your-project.supabase.co`
   - `🔑 Key: eyJhbGciO...`

3. **Common Error Messages**
   - `SUPABASE_URL not properly configured` → Environment variables not passed
   - `SUPABASE_ANON_KEY not properly configured` → Missing API key
   - `Invalid API key` → Wrong key or URL
   - `Network error` → Connectivity issue

### Platform-Specific Issues

#### Android
- **Network Security**: Check if HTTP traffic is allowed
- **Permissions**: Verify internet permission in `android/app/src/main/AndroidManifest.xml`
- **Certificate Issues**: Corporate networks may block Supabase

#### iOS
- **App Transport Security**: Check `ios/Runner/Info.plist` for HTTPS requirements
- **Simulator vs Device**: Test on both to isolate issues
- **Code Signing**: Ensure proper provisioning profiles

### Debug Commands

```bash
# Test Android with full logging
flutter run --dart-define=SUPABASE_URL=your_url --dart-define=SUPABASE_ANON_KEY=your_key --verbose

# Test iOS with full logging  
flutter run --dart-define=SUPABASE_URL=your_url --dart-define=SUPABASE_ANON_KEY=your_key --verbose

# Check device connectivity
flutter doctor -v
```

### Troubleshooting Checklist

- [ ] Environment variables are correctly loaded
- [ ] Supabase URL is accessible from mobile device
- [ ] API key has correct permissions
- [ ] Device has internet connectivity
- [ ] App has internet permissions
- [ ] No corporate firewall blocking Supabase
- [ ] Same account works on web version
- [ ] Email is confirmed in Supabase dashboard

### Quick Fixes

1. **Restart the app completely** (not just hot reload)
2. **Clear app data** on device
3. **Test with a fresh user account**
4. **Check Supabase dashboard** for failed auth attempts
5. **Verify redirect URLs** in Supabase settings include mobile deep links

### Contact Support

If issues persist, provide:
- Platform (Android/iOS)
- Device model and OS version
- Console logs from app startup
- Supabase project URL (without sensitive data)
- Steps to reproduce the issue
