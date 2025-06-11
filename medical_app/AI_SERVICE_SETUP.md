# Medical App AI Service Setup Guide

This guide will help you set up and run the AI backend service for the Medical App.

## 🏥 Overview

The AI service provides:
- **Text Chat**: Conversational AI for medical questions
- **Image Analysis**: Medical image analysis and interpretation
- **PDF Analysis**: Medical document processing and summarization

## 📋 Prerequisites

### Required Software
1. **Python 3.8+** - [Download from python.org](https://python.org)
2. **Flutter SDK** - For the mobile app
3. **Android Studio/VS Code** - For development

### Optional (for enhanced AI features)
- **Ollama** - For advanced AI models [Download from ollama.com](https://ollama.com)

## 🚀 Quick Start

### Option 1: Windows Batch File (Easiest)
1. Double-click `start_ai_service.bat`
2. The script will automatically install dependencies and start the service

### Option 2: Manual Setup
1. **Install Python dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

2. **Start the AI service:**
   ```bash
   python start_ai_service.py
   ```

3. **Verify the service is running:**
   - Open browser and go to: http://localhost:5000/health
   - You should see a JSON response indicating the service is healthy

## 🔧 Configuration

### Server URLs
- **Local development**: `http://localhost:5000`
- **Android Emulator**: `http://10.0.2.2:5000`
- **Physical device**: Use your computer's IP address

### Endpoints
- `GET /health` - Health check
- `POST /chat` - Text chat
- `POST /analyze-image` - Image analysis
- `POST /analyze-pdf` - PDF analysis

## 🤖 Enhanced AI Features (Optional)

For better AI responses, install Ollama:

### Windows
1. Download from [ollama.com/download/windows](https://ollama.com/download/windows)
2. Install and run Ollama
3. Open command prompt and run:
   ```bash
   ollama pull gemma2:2b
   ```

### macOS
```bash
brew install ollama
ollama pull gemma2:2b
```

### Linux
```bash
curl -fsSL https://ollama.com/install.sh | sh
ollama pull gemma2:2b
```

## 📱 Flutter App Configuration

The Flutter app is already configured to connect to the AI service. Make sure:

1. **For Android Emulator**: Uses `http://10.0.2.2:5000`
2. **For Physical Device**: Update the `baseUrl` in `ai_chatbot_remote_datasource.dart` to your computer's IP address

## 🔍 Troubleshooting

### Common Issues

#### 1. "Connection failed" error
- **Solution**: Make sure the AI service is running
- **Check**: Visit http://localhost:5000/health in your browser

#### 2. "Python not found" error
- **Solution**: Install Python 3.8+ and add it to your PATH
- **Windows**: Check "Add Python to PATH" during installation

#### 3. "Module not found" errors
- **Solution**: Install dependencies:
  ```bash
  pip install -r requirements.txt
  ```

#### 4. Images not displaying in chat
- **Cause**: File path issues or permissions
- **Solution**: The app now handles image errors gracefully and shows error messages

#### 5. PDF analysis not working
- **Cause**: Large file size or corrupted PDF
- **Solution**: Use PDFs smaller than 50MB and ensure they're not corrupted

### Debug Mode

To see detailed logs, the AI service automatically prints debug information. Check the console where you started the service for detailed error messages.

## 🏗️ Architecture

```
Flutter App (Dart)
    ↓ HTTP Requests
AI Backend Service (Python Flask)
    ↓ Optional
Ollama (Local AI Model)
```

### File Structure
```
medical_app/
├── lib/features/ai_service/
│   └── ai_backend_service.py      # Main AI service
├── start_ai_service.py            # Service starter
├── start_ai_service.bat           # Windows batch file
├── requirements.txt               # Python dependencies
└── AI_SERVICE_SETUP.md           # This guide
```

## 🔒 Security Notes

- The AI service runs locally on your machine
- No data is sent to external servers (unless using Ollama models)
- Medical data stays on your device
- Always follow medical data privacy regulations

## 📊 Performance Tips

1. **Image Size**: Keep images under 10MB for faster processing
2. **PDF Size**: Keep PDFs under 50MB for optimal performance
3. **Network**: Use Wi-Fi for better performance with large files
4. **Memory**: Close other applications if experiencing slow performance

## 🆘 Support

If you encounter issues:

1. **Check the console logs** where you started the AI service
2. **Verify network connectivity** between your device and computer
3. **Ensure all dependencies are installed** correctly
4. **Check firewall settings** that might block port 5000

## 📝 Development Notes

### Adding New Features
- Modify `ai_backend_service.py` for new endpoints
- Update `ai_chatbot_remote_datasource.dart` for new API calls
- Test with both emulator and physical devices

### Model Customization
- Replace the Ollama model in `ai_backend_service.py`
- Adjust prompts for different medical specialties
- Add custom medical knowledge bases

---

**Happy coding! 🏥💻** 