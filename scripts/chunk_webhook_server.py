#!/usr/bin/env python3
"""
Webhook Server for External Chunk Processing

Provides HTTP endpoints for real-time chunk submission and processing.
Integrates with the external_chunk_handler.py for immediate processing.

Usage:
    python3 scripts/chunk_webhook_server.py [--port PORT] [--host HOST]

Endpoints:
    POST /chunks - Submit a new chunk for processing
    GET /status - Get current processing status
    GET /health - Health check endpoint

Author: Hydra Development Team
Created: 2025-11-29
"""

import json
import os
import sys
import argparse
import logging
from datetime import datetime
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse, parse_qs
import threading
import time

# Add project root to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from scripts.external_chunk_handler import ChunkProcessor

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class ChunkWebhookHandler(BaseHTTPRequestHandler):
    """HTTP request handler for chunk processing"""

    def __init__(self, processor, *args, **kwargs):
        self.processor = processor
        super().__init__(*args, **kwargs)

    def do_GET(self):
        """Handle GET requests"""
        parsed_path = urlparse(self.path)

        if parsed_path.path == '/status':
            self._handle_status()
        elif parsed_path.path == '/health':
            self._handle_health()
        else:
            self._send_error(404, "Endpoint not found")

    def do_POST(self):
        """Handle POST requests"""
        parsed_path = urlparse(self.path)

        if parsed_path.path == '/chunks':
            self._handle_chunk_submission()
        else:
            self._send_error(404, "Endpoint not found")

    def _handle_chunk_submission(self):
        """Handle chunk submission"""
        try:
            # Read request body
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            chunk_data = json.loads(post_data.decode('utf-8'))

            # Validate chunk
            errors = self.processor.validate_chunk_schema(chunk_data)
            if errors:
                self._send_error(400, f"Invalid chunk schema: {', '.join(errors)}")
                return

            # Save chunk
            chunk_id = self.processor.save_chunk(chunk_data)

            # Process chunk asynchronously
            def process_async():
                try:
                    result = self.processor.process_chunk(chunk_data)
                    logger.info(f"Processed chunk {chunk_id}: success={result['success']}")
                except Exception as e:
                    logger.error(f"Failed to process chunk {chunk_id}: {e}")

            thread = threading.Thread(target=process_async)
            thread.daemon = True
            thread.start()

            # Send response
            response = {
                "status": "accepted",
                "chunk_id": chunk_id,
                "message": "Chunk accepted for processing"
            }
            self._send_json_response(202, response)

        except json.JSONDecodeError:
            self._send_error(400, "Invalid JSON in request body")
        except Exception as e:
            logger.error(f"Error processing chunk submission: {e}")
            self._send_error(500, "Internal server error")

    def _handle_status(self):
        """Handle status request"""
        try:
            status = self.processor.get_status()
            self._send_json_response(200, status)
        except Exception as e:
            logger.error(f"Error getting status: {e}")
            self._send_error(500, "Internal server error")

    def _handle_health(self):
        """Handle health check"""
        health_status = {
            "status": "healthy",
            "timestamp": datetime.now().isoformat(),
            "version": "1.0.0"
        }
        self._send_json_response(200, health_status)

    def _send_json_response(self, status_code, data):
        """Send JSON response"""
        self.send_response(status_code)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()
        self.wfile.write(json.dumps(data, indent=2).encode('utf-8'))

    def _send_error(self, status_code, message):
        """Send error response"""
        error_response = {
            "error": message,
            "timestamp": datetime.now().isoformat()
        }
        self._send_json_response(status_code, error_response)

    def do_OPTIONS(self):
        """Handle CORS preflight requests"""
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()

    def log_message(self, format, *args):
        """Override to use our logger"""
        logger.info(f"{self.address_string()} - {format % args}")

class ChunkWebhookServer:
    """Webhook server for chunk processing"""

    def __init__(self, host='localhost', port=8080):
        self.host = host
        self.port = port
        self.processor = ChunkProcessor()
        self.server = None

    def create_handler(self):
        """Create handler with processor instance"""
        def handler_class(*args, **kwargs):
            return ChunkWebhookHandler(self.processor, *args, **kwargs)
        return handler_class

    def start(self):
        """Start the webhook server"""
        handler_class = self.create_handler()
        self.server = HTTPServer((self.host, self.port), handler_class)

        logger.info(f"Starting chunk webhook server on {self.host}:{self.port}")
        logger.info("Endpoints:")
        logger.info("  POST /chunks - Submit chunks for processing")
        logger.info("  GET /status  - Get processing status")
        logger.info("  GET /health  - Health check")

        try:
            self.server.serve_forever()
        except KeyboardInterrupt:
            logger.info("Server stopped by user")
        except Exception as e:
            logger.error(f"Server error: {e}")
        finally:
            if self.server:
                self.server.shutdown()

    def stop(self):
        """Stop the webhook server"""
        if self.server:
            logger.info("Stopping webhook server...")
            self.server.shutdown()

def main():
    parser = argparse.ArgumentParser(description="Chunk Webhook Server")
    parser.add_argument('--host', default='localhost',
                       help='Host to bind to (default: localhost)')
    parser.add_argument('--port', type=int, default=8080,
                       help='Port to bind to (default: 8080)')
    parser.add_argument('--verbose', '-v', action='store_true',
                       help='Enable verbose logging')

    args = parser.parse_args()

    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)

    server = ChunkWebhookServer(host=args.host, port=args.port)

    try:
        server.start()
    except Exception as e:
        logger.error(f"Failed to start server: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()