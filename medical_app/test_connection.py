#!/usr/bin/env python3
"""
Test script for AI Backend Service
Tests all endpoints and connection from different perspectives
"""

import requests
import json
import time

def test_health_check(base_url):
    """Test the health check endpoint"""
    try:
        print(f"🔍 Testing health check: {base_url}/health")
        response = requests.get(f"{base_url}/health", timeout=10)
        
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Health check successful!")
            print(f"   Status: {data.get('status')}")
            print(f"   Ollama: {data.get('ollama_connected')}")
            print(f"   Message: {data.get('message')}")
            return True
        else:
            print(f"❌ Health check failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Health check error: {e}")
        return False

def test_text_chat(base_url):
    """Test the text chat endpoint"""
    try:
        print(f"\n💬 Testing text chat: {base_url}/chat")
        payload = {"message": "Hello, this is a test message"}
        response = requests.post(
            f"{base_url}/chat", 
            json=payload, 
            headers={"Content-Type": "application/json"},
            timeout=30
        )
        
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Text chat successful!")
            print(f"   Response: {data.get('response', 'No response')[:100]}...")
            return True
        else:
            print(f"❌ Text chat failed: {response.status_code}")
            print(f"   Response: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Text chat error: {e}")
        return False

def main():
    print("=" * 60)
    print("🏥 Medical App AI Service Connection Test")
    print("=" * 60)
    
    # Test different URLs
    test_urls = [
        "http://localhost:5000",
        "http://127.0.0.1:5000", 
        "http://192.168.0.100:5000"
    ]
    
    for url in test_urls:
        print(f"\n🌐 Testing URL: {url}")
        print("-" * 40)
        
        # Test health check
        health_ok = test_health_check(url)
        
        if health_ok:
            # Test text chat
            test_text_chat(url)
            print(f"✅ {url} is working!")
        else:
            print(f"❌ {url} is not accessible")
    
    print("\n" + "=" * 60)
    print("📋 Connection Test Summary")
    print("=" * 60)
    print("If any URL shows ✅, your server is running correctly.")
    print("For Android devices, use the 192.168.0.100 URL.")
    print("If all tests fail, check:")
    print("1. Server is running (python ai_backend_service.py)")
    print("2. Windows Firewall allows port 5000")
    print("3. Both devices on same WiFi network")

if __name__ == "__main__":
    main() 