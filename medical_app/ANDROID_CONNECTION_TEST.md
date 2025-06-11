# Android Device Connection Test

## Quick Test from Your Android Device

### Step 1: Test Server Accessibility
Open your Android device's browser (Chrome, Firefox, etc.) and try these URLs:

1. **Primary URL (Real Device)**: `http://192.168.0.100:5000/health`
2. **Emulator URL**: `http://10.0.2.2:5000/health`
3. **Localhost**: `http://localhost:5000/health`

### Expected Response
You should see something like:
```json
{
  "status": "healthy",
  "ollama_connected": true,
  "message": "AI Backend Service is running"
}
```

### Step 2: Test Text Chat
If the health check works, try this URL in your browser:
```
http://192.168.0.100:5000/chat
```

You should see a "Method Not Allowed" error (this is normal - it means the server is accessible).

---

## Troubleshooting

### ❌ If you get "This site can't be reached" or timeout:

1. **Check WiFi Connection**
   - Make sure both your computer and Android device are on the same WiFi network
   - Check your computer's IP address: `ipconfig` (Windows) or `ifconfig` (Mac/Linux)

2. **Update IP Address**
   - If your computer's IP is different from `192.168.0.100`, update the Flutter app
   - Edit: `lib/features/ai_chatbot/data/datasources/ai_chatbot_remote_datasource.dart`
   - Change the first URL in `baseUrls` to your actual IP

3. **Windows Firewall**
   - Run PowerShell as Administrator
   - Execute: `netsh advfirewall firewall add rule name="Medical App AI Service" dir=in action=allow protocol=TCP localport=5000`

4. **Router/Network Issues**
   - Some routers block device-to-device communication
   - Try using mobile hotspot from your phone
   - Connect computer to the hotspot and test

### ✅ If the health check works:

Your AI service is accessible! The Flutter app should now work properly.

---

## Current Configuration

The Flutter app now automatically tries multiple URLs:
1. `http://192.168.0.100:5000` (Real Android device)
2. `http://10.0.2.2:5000` (Android emulator)
3. `http://localhost:5000` (Localhost fallback)
4. `http://127.0.0.1:5000` (IP fallback)

It will automatically find and use the first working URL.

---

## Success Indicators

✅ **Browser Test**: Can access health endpoint  
✅ **Flutter App**: Shows "✅ Flask server is running and responding!"  
✅ **Text Chat**: Can send messages and get AI responses  
✅ **Image Upload**: Can upload and analyze images  
✅ **PDF Upload**: Can upload and analyze PDF documents  

---

## Need Help?

1. **Test browser access first** - this is the most important step
2. **Check IP address** - make sure it matches your computer
3. **Verify same network** - both devices must be on same WiFi
4. **Configure firewall** - Windows often blocks incoming connections
5. **Try mobile hotspot** - if router blocks device communication

The app now automatically handles different network configurations! 