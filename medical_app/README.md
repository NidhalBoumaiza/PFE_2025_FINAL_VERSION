# Medical App with AI Assistant

This medical app includes an AI assistant feature powered by Gemma 3 (for text and PDF analysis) and Florence-2 (for image analysis).

## Setup Instructions

### Prerequisites

1. **Flutter**: Make sure you have Flutter installed and set up correctly.
2. **Python 3.8+**: Required for the AI backend service.
3. **Ollama**: Required to run the Gemma 3 LLM locally.

### Setting up the AI Backend Service

1. Install Ollama from [ollama.com](https://ollama.com/download)
2. Run the AI backend service setup script:

```bash
cd medical_app
python start_ai_service.py
```

This script will:
- Check and install required Python dependencies
- Verify Ollama is installed
- Download the Gemma 3 model if needed
- Start the AI backend service

### Running the Flutter App

Once the AI backend service is running, you can start the Flutter app:

```bash
cd medical_app
flutter run
```

## Using the AI Assistant

The AI assistant supports:

1. **Text Chat**: Ask medical questions and get intelligent responses
2. **Image Analysis**: Upload medical images for analysis
3. **PDF Analysis**: Upload medical reports for summarization

## Configuration Options

- **Base URL**: By default, the AI service connects to `http://10.0.2.2:5000` for Android emulators. 
  - For iOS simulators, use `http://localhost:5000`
  - For real devices, use the IP address of the computer running the backend

- **Florence Model**: To enable the Florence-2 image analysis model, edit `start_ai_service.py` and change:
  ```python
  os.environ['USE_FLORENCE'] = 'True'
  ```
  Note: Florence-2 requires significant GPU resources.

## Troubleshooting

- **Connection Issues**: Make sure the AI backend service is running before using the AI assistant
- **Model Loading Errors**: Check if your system meets the requirements for the AI models
- **Ollama Installation**: If you encounter issues with Ollama, visit [ollama.com](https://ollama.com) for platform-specific instructions

## New Features

### Dossier Medical (Medical Records)

The app now includes a complete system for patients to manage their
medical records:

1. **Patient Requirements**: Patients must upload their medical files
   before they can schedule appointments.

2. **File Types Supported**:

   - Images (JPG, JPEG, PNG)
   - PDF documents

3. **Features**:

   - Upload, view, and manage medical files
   - Add descriptions to files
   - Delete individual files
   - Access medical records through patient profile

4. **Architecture**:

   - Follows clean architecture with Domain, Data, and Presentation
     layers
   - Uses BLoC pattern for state management
   - Integrates with the MongoDB database for storing file metadata
   - Files are physically stored on the server with paths saved in the
     database

5. **Server-Side Implementation**:

   - RESTful API endpoints in Express.js server (medical-app-mailer)
   - Multer middleware for file uploads
   - Secure storage system with patient-specific directories

6. **Integration Points**:
   - Profile screen for accessing medical records
   - Appointment scheduling (prevents scheduling without medical
     records)

## Getting Started

### Dossier Medical Setup

1. Make sure the Express server (medical-app-mailer) is running to
   handle file uploads
2. Verify MongoDB connection for storing dossier medical metadata
3. Ensure proper permissions are set for file uploads

### Using the Feature

As a patient:

1. Go to your profile
2. Tap on "Gérer mon dossier médical"
3. Upload your medical files
4. Once files are uploaded, you can schedule appointments

As a doctor:

1. Access patient profiles to view their medical files

A few resources to get you started if this is your first Flutter
project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers
tutorials, samples, guidance on mobile development, and a full API
reference.
