#!/usr/bin/env python3
"""
Quick Network Connectivity Test
Tests server accessibility from different perspectives
"""

import requests
import socket
import subprocess
import sys

def get_local_ip():
    """Get the local IP address"""
    try:
        # Connect to a remote address to determine local IP
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
            s.connect(("8.8.8.8", 80))
            local_ip = s.getsockname()[0]
        return local_ip
    except Exception:
        return "Unable to determine"

def test_url(url, description):
    """Test a specific URL"""
    print(f"\n🌐 Testing {description}")
    print(f"URL: {url}")
    print("-" * 50)
    
    try:
        response = requests.get(url, timeout=10)
        if response.status_code == 200:
            print(f"✅ SUCCESS - Status: {response.status_code}")
            data = response.json()
            print(f"📝 Response: {data}")
            return True
        else:
            print(f"❌ FAILED - Status: {response.status_code}")
            return False
    except requests.exceptions.ConnectionError:
        print("❌ CONNECTION ERROR - Cannot reach server")
        return False
    except requests.exceptions.Timeout:
        print("❌ TIMEOUT - Server not responding")
        return False
    except Exception as e:
        print(f"❌ ERROR - {e}")
        return False

def check_firewall():
    """Check if Windows Firewall might be blocking"""
    print("\n🛡️ Firewall Check")
    print("-" * 50)
    try:
        result = subprocess.run([
            "netsh", "advfirewall", "firewall", "show", "rule", 
            "name=\"Medical App AI Service\""
        ], capture_output=True, text=True, timeout=10)
        
        if "Medical App AI Service" in result.stdout:
            print("✅ Firewall rule exists for port 5000")
        else:
            print("⚠️  No firewall rule found for port 5000")
            print("💡 Run this as Administrator to add rule:")
            print('netsh advfirewall firewall add rule name="Medical App AI Service" dir=in action=allow protocol=TCP localport=5000')
    except Exception as e:
        print(f"⚠️  Could not check firewall: {e}")

def main():
    print("=" * 70)
    print("🔍 NETWORK CONNECTIVITY TEST")
    print("=" * 70)
    
    # Get network information
    local_ip = get_local_ip()
    print(f"🌐 Computer Local IP: {local_ip}")
    print(f"🏥 Server should be running on: http://{local_ip}:5000")
    
    # Test different URLs
    urls_to_test = [
        (f"http://{local_ip}:5000/health", f"Server on Local IP ({local_ip})"),
        ("http://localhost:5000/health", "Server on Localhost"),
        ("http://127.0.0.1:5000/health", "Server on 127.0.0.1"),
        ("http://192.168.0.100:5000/health", "Server on 192.168.0.100"),
    ]
    
    working_urls = []
    for url, description in urls_to_test:
        if test_url(url, description):
            working_urls.append(url)
    
    # Check firewall
    check_firewall()
    
    # Summary
    print("\n" + "=" * 70)
    print("📋 TEST SUMMARY")
    print("=" * 70)
    
    if working_urls:
        print(f"✅ Server is accessible from {len(working_urls)} URL(s):")
        for url in working_urls:
            print(f"   • {url}")
        
        print(f"\n🔧 For Android Device, use: http://{local_ip}:5000")
        print("📱 Test this URL in your Android device's browser:")
        print(f"   {local_ip}:5000/health")
        
        if local_ip != "192.168.0.100":
            print(f"\n⚠️  UPDATE FLUTTER CODE:")
            print("   File: lib/features/ai_chatbot/data/datasources/ai_chatbot_remote_datasource.dart")
            print(f"   Change first URL to: 'http://{local_ip}:5000'")
    else:
        print("❌ Server is not accessible from any URL")
        print("🔧 Troubleshooting steps:")
        print("   1. Make sure the Python server is running")
        print("   2. Check Windows Firewall settings")
        print("   3. Verify the server is bound to 0.0.0.0:5000")
    
    print("\n💡 NEXT STEPS:")
    print("1. Test the working URL in your Android device's browser")
    print("2. If browser works but app doesn't, it's a Flutter app issue")
    print("3. If browser doesn't work, it's a network connectivity issue")
    print("4. Update Flutter code with the correct IP address if needed")

if __name__ == '__main__':
    main() 