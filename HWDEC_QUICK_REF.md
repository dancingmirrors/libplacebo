# Hardware Decoding Quick Reference

## TL;DR - What to Check in Your Driver

If `plplay -Hvulkan` hangs with "Using 39-bit DMA addresses":

### Quick Fix (Recommended)
```bash
# Use VAAPI instead (works better with Intel/AMD and libplacebo)
plplay -Hvaapi video.mp4
```

### Driver Checks

1. **Run the diagnostic script:**
   ```bash
   ./check_hwdec.sh
   ```

2. **Check Vulkan is working:**
   ```bash
   vulkaninfo | head -20
   # Should show your GPU, not errors
   ```

3. **Check Mesa version (Intel/AMD):**
   ```bash
   glxinfo | grep "OpenGL version"
   # Recommended: Mesa 23.0+ for good Vulkan support
   ```

4. **Check i915 firmware (Intel):**
   ```bash
   dmesg | grep i915
   # Look for "firmware loaded" messages
   # Update if you see "firmware failed to load"
   ```

5. **Check VAAPI works:**
   ```bash
   vainfo
   # Should list supported profiles without errors
   ```

6. **Test FFmpeg Vulkan directly:**
   ```bash
   # If this hangs, it's an FFmpeg+driver issue, not plplay
   ffmpeg -init_hw_device vulkan -hwaccel vulkan -i video.mp4 -f null - 2>&1
   ```

### Common Issues

| Symptom | Likely Cause | Fix |
|---------|--------------|-----|
| Hangs at "Using 39-bit DMA" | Multiple Vulkan contexts conflict | Use `-Hvaapi` instead |
| "Failed opening HW device" | Driver not installed/loaded | Install mesa-vulkan-drivers (Intel/AMD) |
| VAAPI works, Vulkan doesn't | Older Mesa version | Update to Mesa 23.0+ |
| Neither hwdec works | Missing drivers | Install intel-media-driver or libva-mesa-driver |

### Environment Variables to Try

```bash
# Force specific Vulkan device (if you have multiple GPUs)
VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/intel_icd.x86_64.json plplay -Hvulkan video.mp4

# Use integrated GPU instead of discrete (Mesa)
MESA_VK_DEVICE_SELECT=0 plplay -Hvulkan video.mp4

# Enable debug output
VK_LOADER_DEBUG=all plplay -Hvulkan video.mp4 2>&1 | tee vulkan-debug.log
```

### System-Specific Recommendations

**Intel (i915):**
- ✅ VAAPI: `plplay -Hvaapi video.mp4` (BEST)
- ⚠️ Vulkan: May hang, see troubleshooting
- Update: `sudo apt install intel-media-driver mesa-vulkan-drivers`

**AMD (AMDGPU):**
- ✅ VAAPI: `plplay -Hvaapi video.mp4` (BEST)
- ✅ Vulkan: Usually works on newer drivers
- Update: `sudo apt install mesa-va-drivers mesa-vulkan-drivers`

**NVIDIA:**
- ✅ CUDA: `plplay -Hcuda video.mp4` (BEST)
- ❌ Vulkan: Limited FFmpeg support
- Note: Requires proprietary drivers

### Still Having Issues?

See [VULKAN_HWDEC_TROUBLESHOOTING.md](VULKAN_HWDEC_TROUBLESHOOTING.md) for:
- Detailed driver diagnostics
- Kernel parameter tuning
- Firmware updates
- Known driver bugs
- How to report issues

### Why Does VAAPI Work Better?

VAAPI and libplacebo work better together because:
1. VAAPI uses separate decode/render contexts (no conflict)
2. VAAPI → libplacebo interop is well-tested
3. Vulkan hwdec creates its own Vulkan instance (conflicts with libplacebo's)
4. Future versions may fix this by sharing Vulkan contexts
