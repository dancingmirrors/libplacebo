# Vulkan Hardware Decoding Troubleshooting

## Issue: plplay -Hvulkan hangs with "Using 39-bit DMA addresses"

This indicates a conflict between FFmpeg's Vulkan hwdec and libplacebo's Vulkan context,
typically seen with Intel i915 drivers.

## Driver Diagnostics

### 1. Check Vulkan Driver Installation
```bash
# Verify Vulkan is properly installed
vulkaninfo | head -50

# Check for multiple Vulkan ICDs (can cause conflicts)
ls -la /usr/share/vulkan/icd.d/
ls -la /etc/vulkan/icd.d/

# Look for both Intel and other vendors
cat /usr/share/vulkan/icd.d/*.json
```

### 2. Check Mesa/i915 Driver Version
```bash
# Check Mesa version (should be recent for Vulkan support)
glxinfo | grep "OpenGL version"
vulkaninfo | grep "driverVersion"

# Check kernel driver version
dmesg | grep i915
modinfo i915 | grep version

# Recommended: Mesa 23.0+ for good Intel Vulkan support
```

### 3. Environment Variables to Try

```bash
# Force specific Vulkan device (if you have multiple GPUs)
VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/intel_icd.x86_64.json plplay -Hvulkan video.mp4

# Enable Vulkan validation layers for debugging
VK_INSTANCE_LAYERS=VK_LAYER_KHRONOS_validation plplay -Hvulkan video.mp4

# Disable Vulkan device simulation
VK_LOADER_DEBUG=all plplay -Hvulkan video.mp4

# Use specific Vulkan device by index
# (if vulkaninfo shows multiple devices)
MESA_VK_DEVICE_SELECT=0 plplay -Hvulkan video.mp4
```

### 4. Check for DRI3/Present Issues
```bash
# Check if DRI3 is enabled (required for Vulkan)
xdpyinfo | grep "DRI3"

# If missing, add to /etc/X11/xorg.conf.d/20-intel.conf:
# Section "Device"
#   Identifier "Intel Graphics"
#   Driver "modesetting"
#   Option "DRI" "3"
# EndSection
```

### 5. Verify FFmpeg Vulkan Support
```bash
# Check if FFmpeg was built with Vulkan support
ffmpeg -hwaccels | grep vulkan

# Check available decoders
ffmpeg -decoders | grep vulkan

# Test FFmpeg Vulkan decoding directly (without plplay)
ffmpeg -init_hw_device vulkan -hwaccel vulkan -i video.mp4 -f null -
```

### 6. Intel-Specific Checks
```bash
# Check for i915 firmware
ls -la /lib/firmware/i915/

# Update firmware if needed
sudo apt update
sudo apt install intel-microcode firmware-misc-nonfree

# Check for GuC/HuC firmware loading
sudo dmesg | grep -E "GuC|HuC"

# Enable GuC/HuC if not loaded (in /etc/modprobe.d/i915.conf):
# options i915 enable_guc=2
```

## Workarounds

### Option 1: Use VAAPI Instead (Recommended for Intel)
```bash
# VAAPI works better with Intel GPUs and libplacebo
plplay -Hvaapi video.mp4

# Check VAAPI support
vainfo
```

### Option 2: Use Software Decoding with GPU Rendering
```bash
# Don't use hardware decoding, but still get GPU rendering
plplay video.mp4
```

### Option 3: Try Different FFmpeg Build
```bash
# If using distribution FFmpeg, try building from source
# or use a different build without Vulkan hwdec
```

## Known Issues

1. **FFmpeg Vulkan + libplacebo Conflict**: FFmpeg's Vulkan hwdec creates its own 
   Vulkan instance, conflicting with libplacebo's existing Vulkan context.

2. **Intel i915 Multiple Contexts**: Some Intel drivers don't handle multiple 
   Vulkan instances well, causing hangs.

3. **DMA-BUF Import Issues**: Vulkan video frames may not import correctly 
   into libplacebo's Vulkan context.

## Expected Behavior

When working correctly, you should see:
```
Requesting hardware decoder: vulkan
Using hardware decoder: vulkan (vulkan)
```

Without hanging or DMA messages.

## Reporting Issues

If the issue persists, gather this information:
```bash
# System info
uname -a
lspci | grep VGA

# Driver versions
vulkaninfo --summary
vainfo

# FFmpeg info
ffmpeg -version
ffmpeg -hwaccels

# libplacebo GPU info
plplay -v video.mp4 2>&1 | grep -i vulkan
```

## Future Improvement

The proper fix would be to share libplacebo's Vulkan device with FFmpeg,
which requires:
- Accessing libplacebo's VkInstance/VkDevice
- Creating FFmpeg's AVHWDeviceContext from existing Vulkan handles
- This is a larger change requiring libplacebo API extensions
