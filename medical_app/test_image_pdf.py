#!/usr/bin/env python3
"""
Test script for Image and PDF processing endpoints
"""

import requests
import json
import os

def test_image_endpoint():
    """Test the image analysis endpoint"""
    print("🖼️  Testing Image Analysis Endpoint")
    print("-" * 40)
    
    # Create a simple test image file (1x1 pixel PNG)
    test_image_data = b'\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90wS\xde\x00\x00\x00\tpHYs\x00\x00\x0b\x13\x00\x00\x0b\x13\x01\x00\x9a\x9c\x18\x00\x00\x00\nIDATx\x9cc\xf8\x00\x00\x00\x01\x00\x01\x00\x00\x00\x00IEND\xaeB`\x82'
    
    with open('test_image.png', 'wb') as f:
        f.write(test_image_data)
    
    try:
        url = 'http://192.168.0.100:5000/analyze-image'
        
        with open('test_image.png', 'rb') as f:
            files = {'image': ('test_image.png', f, 'image/png')}
            data = {
                'task_prompt': '<MEDICAL_ANALYSIS>',
                'text_input': 'Analyze this test image'
            }
            
            print(f"📤 Sending POST request to: {url}")
            response = requests.post(url, files=files, data=data, timeout=30)
            
            print(f"📥 Response status: {response.status_code}")
            
            if response.status_code == 200:
                result = response.json()
                print("✅ Image analysis successful!")
                print(f"📝 Response: {result}")
                return True
            else:
                print(f"❌ Image analysis failed: {response.status_code}")
                print(f"📝 Error: {response.text}")
                return False
                
    except Exception as e:
        print(f"❌ Image analysis error: {e}")
        return False
    finally:
        # Clean up test file
        if os.path.exists('test_image.png'):
            os.remove('test_image.png')

def test_pdf_endpoint():
    """Test the PDF analysis endpoint"""
    print("\n📄 Testing PDF Analysis Endpoint")
    print("-" * 40)
    
    # Create a simple test PDF file
    test_pdf_data = b'%PDF-1.4\n1 0 obj\n<<\n/Type /Catalog\n/Pages 2 0 R\n>>\nendobj\n2 0 obj\n<<\n/Type /Pages\n/Kids [3 0 R]\n/Count 1\n>>\nendobj\n3 0 obj\n<<\n/Type /Page\n/Parent 2 0 R\n/MediaBox [0 0 612 792]\n/Contents 4 0 R\n>>\nendobj\n4 0 obj\n<<\n/Length 44\n>>\nstream\nBT\n/F1 12 Tf\n72 720 Td\n(Hello World) Tj\nET\nendstream\nendobj\nxref\n0 5\n0000000000 65535 f \n0000000009 00000 n \n0000000058 00000 n \n0000000115 00000 n \n0000000206 00000 n \ntrailer\n<<\n/Size 5\n/Root 1 0 R\n>>\nstartxref\n299\n%%EOF'
    
    with open('test_document.pdf', 'wb') as f:
        f.write(test_pdf_data)
    
    try:
        url = 'http://192.168.0.100:5000/analyze-pdf'
        
        with open('test_document.pdf', 'rb') as f:
            files = {'pdf': ('test_document.pdf', f, 'application/pdf')}
            
            print(f"📤 Sending POST request to: {url}")
            response = requests.post(url, files=files, timeout=30)
            
            print(f"📥 Response status: {response.status_code}")
            
            if response.status_code == 200:
                result = response.json()
                print("✅ PDF analysis successful!")
                print(f"📝 Response: {result}")
                return True
            else:
                print(f"❌ PDF analysis failed: {response.status_code}")
                print(f"📝 Error: {response.text}")
                return False
                
    except Exception as e:
        print(f"❌ PDF analysis error: {e}")
        return False
    finally:
        # Clean up test file
        if os.path.exists('test_document.pdf'):
            os.remove('test_document.pdf')

def main():
    print("=" * 60)
    print("🧪 AI Service Image & PDF Processing Test")
    print("=" * 60)
    
    # Test image endpoint
    image_success = test_image_endpoint()
    
    # Test PDF endpoint
    pdf_success = test_pdf_endpoint()
    
    print("\n" + "=" * 60)
    print("📋 Test Summary")
    print("=" * 60)
    print(f"🖼️  Image Analysis: {'✅ PASS' if image_success else '❌ FAIL'}")
    print(f"📄 PDF Analysis:   {'✅ PASS' if pdf_success else '❌ FAIL'}")
    
    if image_success and pdf_success:
        print("\n🎉 All tests passed! Image and PDF processing are working correctly.")
    else:
        print("\n⚠️  Some tests failed. Check the server logs for more details.")

if __name__ == '__main__':
    main() 