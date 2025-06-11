#!/usr/bin/env python3
import os
import sys
import subprocess
import time
import platform

# Determine the current directory
current_dir = os.path.dirname(os.path.abspath(__file__))
ai_backend_path = os.path.join(current_dir, 'lib', 'features', 'ai_service', 'ai_backend_service.py')

def check_dependencies():
    """Check if required dependencies are installed."""
    required_packages = [
        'flask', 'flask-cors', 'waitress', 'pillow', 'PyPDF2', 'requests'
    ]
    
    missing_packages = []
    for package in required_packages:
        try:
            if package == 'flask-cors':
                __import__('flask_cors')
            elif package == 'pillow':
                __import__('PIL')
            else:
                __import__(package)
        except ImportError:
            missing_packages.append(package)
    
    return missing_packages

def install_dependencies(missing_packages):
    """Install missing dependencies."""
    print(f"Installing missing dependencies: {', '.join(missing_packages)}")
    try:
        subprocess.check_call([sys.executable, '-m', 'pip', 'install'] + missing_packages)
        print("All dependencies installed successfully!")
        return True
    except subprocess.CalledProcessError:
        print("Failed to install dependencies. Please install them manually using:")
        print(f"pip install {' '.join(missing_packages)}")
        return False

def check_ollama_installed():
    """Check if Ollama is installed and accessible."""
    try:
        result = subprocess.run(['ollama', 'list'], capture_output=True, text=True)
        return result.returncode == 0
    except FileNotFoundError:
        return False

def check_gemma_model_installed():
    """Check if the gemma2:2b model is installed in Ollama."""
    try:
        result = subprocess.run(['ollama', 'list'], capture_output=True, text=True)
        if result.returncode == 0:
            return 'gemma2:2b' in result.stdout
        return False
    except FileNotFoundError:
        return False

def install_gemma_model():
    """Install the gemma2:2b model in Ollama."""
    print("Installing gemma2:2b model... (this may take a while)")
    try:
        subprocess.check_call(['ollama', 'pull', 'gemma2:2b'])
        print("Gemma 2 model installed successfully!")
        return True
    except subprocess.CalledProcessError:
        print("Failed to install Gemma 2 model. Please install it manually using:")
        print("ollama pull gemma2:2b")
        return False

def get_install_ollama_instructions():
    """Get platform-specific Ollama installation instructions."""
    system = platform.system().lower()
    
    if system == 'windows':
        return "Download and install Ollama from https://ollama.com/download/windows"
    elif system == 'darwin':  # macOS
        return "Install Ollama with Homebrew: brew install ollama"
    elif system == 'linux':
        return "Install Ollama with: curl -fsSL https://ollama.com/install.sh | sh"
    else:
        return "Visit https://ollama.com for installation instructions"

def main():
    print("🏥 Medical App AI Service Starter")
    print("=" * 40)
    
    # Check Python version
    if sys.version_info < (3, 8):
        print("❌ Python 3.8 or higher is required")
        sys.exit(1)
    
    print("✅ Python version check passed")
    
    # Check and install dependencies
    print("📦 Checking dependencies...")
    missing_packages = check_dependencies()
    if missing_packages:
        print(f"⚠️  Missing packages: {', '.join(missing_packages)}")
        if not install_dependencies(missing_packages):
            print("❌ Failed to install dependencies")
            sys.exit(1)
    else:
        print("✅ All dependencies are installed")
    
    # Check if the AI backend service file exists
    if not os.path.exists(ai_backend_path):
        print(f"❌ AI backend service file not found at: {ai_backend_path}")
        print("Please ensure the file exists or run this script from the correct directory")
        sys.exit(1)
    
    print("✅ AI backend service file found")
    
    # Check if Ollama is installed (optional)
    print("🤖 Checking Ollama installation...")
    if not check_ollama_installed():
        print("⚠️  Ollama is not installed or not in PATH")
        print("The AI service will work with basic responses, but for full AI features:")
        print(get_install_ollama_instructions())
        print("Then run: ollama pull gemma2:2b")
    else:
        print("✅ Ollama is installed")
        
        # Check if Gemma 2 model is installed
        print("🧠 Checking AI model...")
        if not check_gemma_model_installed():
            print("⚠️  Gemma2:2b model not found")
            print("Installing model (this may take several minutes)...")
            if not install_gemma_model():
                print("⚠️  Model installation failed, but service will still work with basic responses")
        else:
            print("✅ Gemma2:2b model is available")
    
    # Start the AI backend service
    print("\n🚀 Starting AI backend service...")
    print("📍 Service will be available at:")
    print("   - Local: http://localhost:5000")
    print("   - Android Emulator: http://10.0.2.2:5000")
    print("\n⏳ Starting server...")
    
    try:
        # Start the service
        process = subprocess.Popen([sys.executable, ai_backend_path])
        print("✅ AI backend service started successfully!")
        print("🔍 Check health at: http://localhost:5000/health")
        print("\n📋 Available endpoints:")
        print("   - POST /chat (text messages)")
        print("   - POST /analyze-image (image analysis)")
        print("   - POST /analyze-pdf (PDF analysis)")
        print("   - GET /health (health check)")
        print("\n💡 Tip: Keep this terminal open to see server logs")
        print("Press Ctrl+C to stop the service")
        
        # Wait for the process
        process.wait()
        
    except KeyboardInterrupt:
        print("\n🛑 Service stopped by user")
        if 'process' in locals():
            process.terminate()
    except Exception as e:
        print(f"❌ Failed to start AI backend service: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main() 