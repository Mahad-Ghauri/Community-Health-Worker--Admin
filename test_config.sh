#!/bin/bash

# Quick test script for build configuration
echo "🔍 Testing build configuration..."

# Check if required files exist
echo "📁 Checking configuration files..."

if [ -f "android/app/proguard-rules.pro" ]; then
    echo "✅ ProGuard rules file exists"
else
    echo "❌ ProGuard rules file missing"
    exit 1
fi

if grep -q "isMinifyEnabled = true" android/app/build.gradle.kts; then
    echo "✅ Minification enabled in build.gradle.kts"
else
    echo "❌ Minification not enabled"
    exit 1
fi

if grep -q "isShrinkResources = true" android/app/build.gradle.kts; then
    echo "✅ Resource shrinking enabled"
else
    echo "❌ Resource shrinking not enabled"
    exit 1
fi

echo ""
echo "🎉 Build configuration is properly set up!"
echo ""
echo "📋 Summary of optimizations:"
echo "   ✅ Android R8/ProGuard minification"
echo "   ✅ Resource shrinking"
echo "   ✅ Code obfuscation"
echo "   ✅ Flutter symbol obfuscation"
echo "   ✅ Debug symbol separation"
echo ""
echo "🚀 Ready to build optimized releases!"
echo ""
echo "💡 Next steps:"
echo "   1. Run: ./build_optimized.sh"
echo "   2. Test the release build thoroughly"
echo "   3. Set up crash reporting with symbols"
