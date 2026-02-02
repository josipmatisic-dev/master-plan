#!/bin/bash

echo "==================================="
echo "Flutter CI Fixes Verification"
echo "==================================="
echo ""

echo "1. Checking analysis_options.yaml..."
if grep -q "avoid_returning_null" analysis_options.yaml; then
    echo "   ❌ FAIL: avoid_returning_null still present"
else
    echo "   ✅ PASS: avoid_returning_null removed"
fi
echo ""

echo "2. Checking lib/main.dart..."
if grep -q "theme/app_theme.dart" lib/main.dart; then
    echo "   ❌ FAIL: Unused import still present"
else
    echo "   ✅ PASS: Unused import removed"
fi
echo ""

echo "3. Checking lib/theme/app_theme.dart (deprecated properties)..."
if grep -q "background:" lib/theme/app_theme.dart; then
    echo "   ❌ FAIL: Deprecated 'background' still present"
else
    echo "   ✅ PASS: Deprecated 'background' removed"
fi

if grep -q "onBackground:" lib/theme/app_theme.dart; then
    echo "   ❌ FAIL: Deprecated 'onBackground' still present"
else
    echo "   ✅ PASS: Deprecated 'onBackground' removed"
fi
echo ""

echo "4. Checking lib/providers/settings_provider.dart..."
if grep -A2 "void dispose()" lib/providers/settings_provider.dart | grep -q "super.dispose()"; then
    echo "   ❌ FAIL: Unnecessary dispose override still present"
else
    echo "   ✅ PASS: Unnecessary dispose override removed"
fi
echo ""

echo "5. Checking lib/providers/theme_provider.dart..."
if grep -A2 "void dispose()" lib/providers/theme_provider.dart | grep -q "super.dispose()"; then
    echo "   ❌ FAIL: Unnecessary dispose override still present"
else
    echo "   ✅ PASS: Unnecessary dispose override removed"
fi
echo ""

echo "6. Checking Android structure..."
if [ -d "android" ] && [ -f "android/build.gradle" ] && [ -f "android/app/build.gradle" ]; then
    echo "   ✅ PASS: Android directory structure exists"
else
    echo "   ❌ FAIL: Android directory structure incomplete"
fi

if [ -f "android/app/src/main/AndroidManifest.xml" ]; then
    echo "   ✅ PASS: AndroidManifest.xml exists"
else
    echo "   ❌ FAIL: AndroidManifest.xml missing"
fi

if [ -f "android/app/src/main/kotlin/com/example/marine_nav_app/MainActivity.kt" ]; then
    echo "   ✅ PASS: MainActivity.kt exists"
else
    echo "   ❌ FAIL: MainActivity.kt missing"
fi
echo ""

echo "==================================="
echo "Verification Complete!"
echo "==================================="
