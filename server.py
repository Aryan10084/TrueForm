#!/usr/bin/env python3
"""
Simple HTTP server to test ML Kit Pose Detection
Run this and open http://localhost:8000/test_mlkit.html
"""

import http.server
import socketserver
import os
import webbrowser
from pathlib import Path

PORT = 8000

class MyHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        # Add CORS headers for webcam access
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        super().end_headers()

def main():
    # Change to the directory containing this script
    os.chdir(Path(__file__).parent)
    
    # Create server
    with socketserver.TCPServer(("", PORT), MyHTTPRequestHandler) as httpd:
        print(f"🚀 ML Kit Pose Detection Test Server")
        print(f"📁 Serving files from: {os.getcwd()}")
        print(f"🌐 Server running at: http://localhost:{PORT}")
        print(f"📄 Test page: http://localhost:{PORT}/test_mlkit.html")
        print(f"⏹️  Press Ctrl+C to stop the server")
        print()
        
        # Try to open the test page automatically
        try:
            webbrowser.open(f'http://localhost:{PORT}/test_mlkit.html')
            print("✅ Opened test page in your browser!")
        except:
            print("⚠️  Please manually open: http://localhost:8000/test_mlkit.html")
        
        print()
        
        # Start server
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n⏹️  Server stopped by user")
            httpd.shutdown()

if __name__ == "__main__":
    main() 