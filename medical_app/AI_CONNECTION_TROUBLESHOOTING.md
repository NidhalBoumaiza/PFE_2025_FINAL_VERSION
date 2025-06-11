# AI Service Connection Troubleshooting Guide

## Problem: AI Chatbot Cannot Connect to Server

### Current Status
✅ **Flask Server**: Running on `http://192.168.0.100:5000`  
✅ **Ollama**: Connected and working  
❌ **Android Connection**: Failed to connect from device  

---

## Quick Fix Steps

### 1. **Check Your Network Setup**
Your computer IP: `192.168.0.100`  
Server URL: `http://192.168.0.100:5000`

**Test server accessibility:**
```bash
# On your computer, test if server is running:
curl http://192.168.0.100:5000/health

# Should return: {"status":"healthy","ollama_connected":true}
```

### 2. **Configure Windows Firewall**
**Option A: Run as Administrator**
```cmd
# Right-click PowerShell -> "Run as Administrator"
netsh advfirewall firewall add rule name="Medical App AI Service" dir=in action=allow protocol=TCP localport=5000
```

**Option B: Manual Firewall Setup**
1. Open Windows Defender Firewall
2. Click "Advanced settings"
3. Click "Inbound Rules" → "New Rule"
4. Select "Port" → Next
5. Select "TCP" → Specific local ports: `5000`
6. Select "Allow the connection"
7. Apply to all profiles
8. Name: "Medical App AI Service"

### 3. **Verify Network Connectivity**

**From your Android device:**
- Make sure both devices are on the same WiFi network
- Try opening `http://192.168.0.100:5000/health` in your phone's browser
- You should see: `{"status":"healthy","ollama_connected":true}`

### 4. **Alternative IP Addresses**

If `192.168.0.100` doesn't work, try finding your actual IP:

```cmd
ipconfig
```

Look for "IPv4 Address" under your active network adapter, then update the Flutter app:

**File:** `lib/features/ai_chatbot/data/datasources/ai_chatbot_remote_datasource.dart`
```dart
static const String baseUrl = 'http://YOUR_ACTUAL_IP:5000';
```

---

## Common Network Configurations

### For Different Network Types:

1. **Home WiFi**: Use `192.168.1.x` or `192.168.0.x`
2. **Office Network**: May use `10.x.x.x` or `172.16.x.x`
3. **Mobile Hotspot**: Usually `192.168.43.x`

### For Android Emulator:
```dart
static const String baseUrl = 'http://10.0.2.2:5000';
```

### For Real Android Device:
```dart
static const String baseUrl = 'http://YOUR_COMPUTER_IP:5000';
```

---

## Testing Steps

### 1. **Test Server Health**
```bash
# On computer:
curl http://192.168.0.100:5000/health

# Expected response:
# {"message":"AI Backend Service is running","ollama_connected":true,"status":"healthy"}
```

### 2. **Test from Android Device Browser**
Open your phone's browser and go to:
```
http://192.168.0.100:5000/health
```

### 3. **Test Text Chat**
```bash
curl -X POST http://192.168.0.100:5000/chat \
  -H "Content-Type: application/json" \
  -d '{"message":"Hello, how are you?"}'
```

---

## Advanced Troubleshooting

### Check Network Connectivity
```cmd
# Ping your computer from Android device (if possible)
ping 192.168.0.100

# Check if port 5000 is listening
netstat -an | findstr :5000
```

### Disable Windows Firewall Temporarily
```cmd
# Turn off Windows Firewall (temporarily for testing)
netsh advfirewall set allprofiles state off

# Remember to turn it back on:
netsh advfirewall set allprofiles state on
```

### Use Different Port
If port 5000 is blocked, try port 8080:

**Update server:** `ai_backend_service.py`
```python
serve(app, host='0.0.0.0', port=8080, threads=4)
```

**Update Flutter app:** `ai_chatbot_remote_datasource.dart`
```dart
static const String baseUrl = 'http://192.168.0.100:8080';
```

---

## Success Indicators

✅ **Server Health Check**: Returns `{"status":"healthy"}`  
✅ **Browser Test**: Can access health endpoint from phone browser  
✅ **Flutter App**: Shows "✅ Flask server is running and responding!"  
✅ **Chat Works**: Can send text messages and get responses  
✅ **Image Analysis**: Can upload and analyze images  
✅ **PDF Analysis**: Can upload and analyze PDF files  

---

## Current Configuration

**Server IP**: `192.168.0.100`  
**Server Port**: `5000`  
**Flutter Base URL**: `http://192.168.0.100:5000`  
**Health Check**: `http://192.168.0.100:5000/health`  

**Endpoints:**
- `POST /chat` - Text conversations
- `POST /analyze-image` - Image analysis  
- `POST /analyze-pdf` - PDF analysis
- `GET /health` - Server health check

---

## Need Help?

1. **Check server logs** for connection attempts
2. **Test with phone browser** first
3. **Verify both devices on same network**
4. **Configure Windows Firewall** properly
5. **Try different IP address** if needed

The most common issue is Windows Firewall blocking incoming connections on port 5000. 