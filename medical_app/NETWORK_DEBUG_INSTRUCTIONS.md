# 🔍 Network Connection Debug Instructions

## 🚨 Current Issue
The server is running perfectly but the Android app can't connect to it. The server is accessible at `http://192.168.0.100:5000/health` from the computer, but the Android device cannot reach it.

## ✅ Server Status: WORKING
- ✅ Server running on `http://192.168.0.100:5000`
- ✅ Health check responds with: `{"status":"healthy","ollama_connected":true}`
- ✅ All endpoints functional

## 🔧 Manual Testing Steps

### Step 1: Test from Android Device Browser
1. **Open Chrome/Firefox on your Android device**
2. **Navigate to**: `http://192.168.0.100:5000/health`
3. **Expected result**: Should show JSON response with server status
4. **If fails**: Connection problem between device and computer

### Step 2: Check Network Configuration
1. **Verify same WiFi network**: 
   - Computer and Android device must be on the same WiFi
   - Check WiFi name on both devices
2. **Test with mobile hotspot**: 
   - Create hotspot on Android device
   - Connect computer to this hotspot
   - Update IP address and test

### Step 3: Get Current IP Address
1. **On your computer, run**: `ipconfig`
2. **Look for IPv4 Address** under your WiFi adapter
3. **If different from 192.168.0.100**, update the Flutter code

### Step 4: Configure Windows Firewall
1. **Open PowerShell as Administrator**
2. **Run**: 
   ```cmd
   netsh advfirewall firewall add rule name="Medical App AI Service" dir=in action=allow protocol=TCP localport=5000
   ```
3. **Alternative**: Temporarily disable Windows Firewall for testing

### Step 5: Test Different URLs
Try these URLs from Android browser:
1. `http://192.168.0.100:5000/health`
2. `http://localhost:5000/health` (won't work from device)
3. `http://10.0.2.2:5000/health` (emulator only)

## 🛠️ Quick Fixes to Try

### Fix 1: Update IP Address
1. **Check current IP**: `ipconfig`
2. **If different**, update this file: `lib/features/ai_chatbot/data/datasources/ai_chatbot_remote_datasource.dart`
3. **Change line 18**: `'http://YOUR_ACTUAL_IP:5000'`

### Fix 2: Use Mobile Hotspot
1. **Create hotspot on Android device**
2. **Connect computer to hotspot**
3. **Get new IP address**: `ipconfig`
4. **Update Flutter code with new IP**
5. **Test connection**

### Fix 3: Disable Firewall Temporarily
1. **Windows Security** → **Firewall & network protection**
2. **Turn off** Domain/Private/Public network firewall
3. **Test connection**
4. **Turn firewall back on** after testing

## 📱 Update Flutter Code (If Needed)

If your IP address is different, update this file:
```dart
// lib/features/ai_chatbot/data/datasources/ai_chatbot_remote_datasource.dart
static const List<String> baseUrls = [
  'http://YOUR_ACTUAL_IP:5000',  // Update this line
  'http://10.0.2.2:5000',        // Keep this
  'http://localhost:5000',       // Keep this
  'http://127.0.0.1:5000',       // Keep this
];
```

## 🧪 Test Commands

### Test from Computer
```bash
# Test health endpoint
Invoke-WebRequest -Uri http://192.168.0.100:5000/health

# Test chat endpoint
Invoke-WebRequest -Uri http://192.168.0.100:5000/chat -Method POST -Body '{"message":"test"}' -ContentType "application/json"
```

### Test Network Connectivity
```bash
# Check current IP
ipconfig

# Test connection to device
ping YOUR_ANDROID_DEVICE_IP
```

## 🎯 Common Solutions

### Solution 1: Router Configuration
- **Some routers block device-to-device communication**
- **Enable "AP Isolation" or "Device Isolation"** in router settings
- **Or use mobile hotspot as temporary solution**

### Solution 2: Use USB Tethering
1. **Connect Android device to computer via USB**
2. **Enable USB tethering** in Android settings
3. **Computer will get new network adapter**
4. **Get new IP address** and update Flutter code

### Solution 3: Use Computer's Hotspot
1. **Windows Settings** → **Network & Internet** → **Mobile hotspot**
2. **Turn on mobile hotspot**
3. **Connect Android device to this hotspot**
4. **Get hotspot IP address** and update Flutter code

## 🔍 Debug Steps in Order

1. ✅ **Server is running** (confirmed)
2. ❓ **Test Android browser** → Try `http://192.168.0.100:5000/health`
3. ❓ **Check same WiFi network** → Verify both devices connected
4. ❓ **Check firewall** → Temporarily disable or add rule
5. ❓ **Try mobile hotspot** → Alternative network connection
6. ❓ **Update IP address** → Use `ipconfig` to get current IP

## 📞 Need Help?
1. **Test the Android browser first** - this is the most important step
2. **Check firewall settings** - most common issue
3. **Try mobile hotspot** - bypasses router issues
4. **Update IP address** - if computer IP changed

The server is working perfectly - this is purely a network connectivity issue between your Android device and computer! 