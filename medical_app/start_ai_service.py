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
        'flask', 'waitress', 'pillow', 'torch', 'transformers', 'PyPDF2', 'ollama'
    ]
    
    missing_packages = []
    for package in required_packages:
        try:
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
    """Check if the gemma3:1b model is installed in Ollama."""
    try:
        result = subprocess.run(['ollama', 'list'], capture_output=True, text=True)
        if result.returncode == 0:
            return 'gemma3:1b' in result.stdout
        return False
    except FileNotFoundError:
        return False

def install_gemma_model():
    """Install the gemma3:1b model in Ollama."""
    print("Installing gemma3:1b model... (this may take a while)")
    try:
        subprocess.check_call(['ollama', 'pull', 'gemma3:1b'])
        print("Gemma 3 model installed successfully!")
        return True
    except subprocess.CalledProcessError:
        print("Failed to install Gemma 3 model. Please install it manually using:")
        print("ollama pull gemma3:1b")
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
    # Check Python version
    if sys.version_info < (3, 8):
        print("Python 3.8 or higher is required")
        sys.exit(1)
    
    # Check and install dependencies
    print("Checking dependencies...")
    missing_packages = check_dependencies()
    if missing_packages:
        if not install_dependencies(missing_packages):
            sys.exit(1)
    
    # Check if Ollama is installed
    print("Checking if Ollama is installed...")
    if not check_ollama_installed():
        print("Ollama is not installed or not in PATH. Please install Ollama:")
        print(get_install_ollama_instructions())
        sys.exit(1)
    
    # Check if Gemma 3 model is installed
    print("Checking if Gemma 3 model is installed...")
    if not check_gemma_model_installed():
        if not install_gemma_model():
            sys.exit(1)
    
    # Check if the AI backend service file exists
    if not os.path.exists(ai_backend_path):
        print(f"AI backend service file not found at: {ai_backend_path}")
        sys.exit(1)
    
    # Set environment variables
    os.environ['USE_FLORENCE'] = 'False'  # Ensure Florence-2 model is disabled
    
    # Start the AI backend service
    print("Starting AI backend service...")
    try:
        subprocess.Popen([sys.executable, ai_backend_path])
        print("AI backend service started successfully!")
        print("The service is running at http://localhost:5000")
    except Exception as e:
        print(f"Failed to start AI backend service: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main() 