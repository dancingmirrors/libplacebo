#!/bin/bash
# Quick diagnostic script for Vulkan hwdec issues
# Run this to check your driver setup

echo "=== Vulkan Hardware Decoding Diagnostic ==="
echo ""

echo "1. Checking Vulkan driver installation..."
if command -v vulkaninfo &> /dev/null; then
    echo "   ✓ vulkaninfo found"
    vulkaninfo --summary 2>/dev/null | grep -E "Instance|Device Name|Driver" | head -10
else
    echo "   ✗ vulkaninfo not found - install vulkan-tools"
fi
echo ""

echo "2. Checking Mesa/i915 driver version..."
if command -v glxinfo &> /dev/null; then
    glxinfo | grep "OpenGL version" | head -1
else
    echo "   glxinfo not found - install mesa-utils"
fi
dmesg 2>/dev/null | grep "i915.*firmware" | tail -3
echo ""

echo "3. Checking VAAPI support (recommended for Intel)..."
if command -v vainfo &> /dev/null; then
    echo "   ✓ vainfo found"
    vainfo 2>&1 | grep -E "Driver|VAProfile" | head -8
else
    echo "   ✗ vainfo not found - install vainfo/libva-utils"
fi
echo ""

echo "4. Checking FFmpeg hardware acceleration support..."
if command -v ffmpeg &> /dev/null; then
    echo "   Available hwaccels:"
    ffmpeg -hide_banner -hwaccels 2>&1 | grep -v "Hardware"
else
    echo "   ✗ ffmpeg not found"
fi
echo ""

echo "5. Checking Vulkan ICD files..."
ls -la /usr/share/vulkan/icd.d/ 2>/dev/null || echo "   No ICD files in /usr/share/vulkan/icd.d/"
echo ""

echo "6. Checking DRI3 support..."
if command -v xdpyinfo &> /dev/null; then
    xdpyinfo 2>/dev/null | grep -E "DRI3|Present" || echo "   DRI3 info not found (may not be running X11)"
else
    echo "   xdpyinfo not found"
fi
echo ""

echo "=== Recommendations ==="
echo ""
echo "For Intel GPUs with i915 driver:"
echo "  • Use: plplay -Hvaapi video.mp4 (RECOMMENDED)"
echo "  • Avoid: plplay -Hvulkan video.mp4 (may hang)"
echo ""
echo "For NVIDIA GPUs:"
echo "  • Use: plplay -Hcuda video.mp4"
echo ""
echo "For AMD GPUs:"
echo "  • Use: plplay -Hvaapi video.mp4"
echo ""
echo "If you still want to try Vulkan:"
echo "  • Update Mesa to 23.0+"
echo "  • Update kernel to 5.15+"
echo "  • Update i915 firmware"
echo "  • See VULKAN_HWDEC_TROUBLESHOOTING.md for details"
echo ""
