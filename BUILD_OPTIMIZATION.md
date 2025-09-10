# Build Optimization Guide

This document explains the minification and obfuscation setup for the CHW TB Tracker app.

## What's Enabled

### 1. Android Minification
- **R8/ProGuard**: Removes unused code and resources
- **Resource Shrinking**: Removes unused resources (images, strings, etc.)
- **Code Obfuscation**: Renames classes, methods, and fields to meaningless names

### 2. Flutter Optimizations
- **Tree Shaking**: Removes unused Dart code
- **Symbol Obfuscation**: Obscures Dart symbol names
- **Debug Info Separation**: Splits debug symbols for crash reporting

## Build Commands

### Standard Optimized Build
```bash
# Build optimized APK
flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols

# Build optimized AAB (for Play Store)
flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols
```

### Using the Build Script
```bash
# Run the automated build script
./build_optimized.sh
```

## Configuration Files

### 1. `android/app/build.gradle.kts`
- Enables R8 minification
- Enables resource shrinking
- References ProGuard rules

### 2. `android/app/proguard-rules.pro`
- Flutter engine protection
- Firebase/Firestore rules
- Plugin-specific rules
- Logging removal
- Aggressive obfuscation settings

## File Size Reduction

With these optimizations enabled, you can expect:
- **APK Size**: 30-50% reduction
- **Code Obfuscation**: 100% (all symbols renamed)
- **Resource Optimization**: 20-40% reduction
- **Performance**: Slight improvement due to smaller binary

## Important Notes

### 1. Debug Symbols
- Always keep debug symbols for crash reporting
- Upload symbols to Firebase Crashlytics or your crash reporting service
- Symbols are stored in: `build/app/outputs/symbols/`

### 2. Testing
- Always test release builds thoroughly
- Obfuscation can sometimes break reflection or dynamic code
- Test on different device architectures

### 3. Crash Reporting
- With obfuscation enabled, stack traces will show obfuscated names
- You need debug symbols to deobfuscate crash reports
- Consider setting up automated symbol upload

## Build Outputs

After running optimized builds:

```
build/app/outputs/
├── flutter-apk/
│   ├── app-release.apk              # Single APK
│   ├── app-arm64-v8a-release.apk    # ARM64 devices
│   ├── app-armeabi-v7a-release.apk  # ARM32 devices
│   └── app-x86_64-release.apk       # x64 devices
├── bundle/release/
│   └── app-release.aab              # Play Store bundle
└── symbols/                         # Debug symbols
```

## Security Benefits

1. **Code Protection**: Makes reverse engineering significantly harder
2. **Size Optimization**: Smaller app downloads faster
3. **Performance**: Slightly faster startup due to smaller binary
4. **Resource Protection**: Removes unused assets that could leak information

## Troubleshooting

### Build Failures
- Check ProGuard rules if builds fail after enabling obfuscation
- Add keep rules for any dynamically accessed classes
- Test with `--verbose` flag for detailed error messages

### Runtime Issues
- Add keep rules for classes accessed via reflection
- Check plugin documentation for specific ProGuard requirements
- Use `--debug` builds during development

### Performance Issues
- Monitor app startup time after obfuscation
- Profile memory usage in release builds
- Compare performance metrics before/after optimization

## Firebase Integration

Special considerations for Firebase:
- All Firebase keep rules are included in `proguard-rules.pro`
- Firestore model classes are protected
- Authentication flows are preserved
- Cloud Storage operations are maintained

## Next Steps

1. Test the optimized build on various devices
2. Set up crash reporting with symbol upload
3. Monitor app performance post-optimization
4. Consider additional security measures if needed
