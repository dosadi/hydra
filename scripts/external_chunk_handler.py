#!/usr/bin/env python3
"""
External Chunk Handler for Hydra Project

Processes chunks of information/tasks from external chat clients and integrates
them into the Hydra project workflow according to established protocols.

Usage:
    python3 scripts/external_chunk_handler.py [--process-all|--webhook]
    python3 scripts/external_chunk_handler.py --validate-schema <file>
    python3 scripts/external_chunk_handler.py --status

Author: Hydra Development Team
Created: 2025-11-28
"""

import json
import os
import sys
import argparse
import hashlib
import time
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Any
import re

# Add project root to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

class ChunkProcessor:
    """Main chunk processing engine"""

    def __init__(self, base_dir: str = None):
        self.base_dir = Path(base_dir) if base_dir else Path(__file__).parent.parent
        self.chunks_dir = self.base_dir / "out" / "external_chunks"
        self.pending_dir = self.chunks_dir / "pending"
        self.processing_dir = self.chunks_dir / "processing"
        self.completed_dir = self.chunks_dir / "completed"
        self.failed_dir = self.chunks_dir / "failed"

        # Ensure directories exist
        for dir_path in [self.pending_dir, self.processing_dir,
                        self.completed_dir, self.failed_dir]:
            dir_path.mkdir(parents=True, exist_ok=True)

    def validate_chunk_schema(self, chunk_data: Dict[str, Any]) -> List[str]:
        """Validate chunk against JSON schema"""
        errors = []

        # Required fields
        required_fields = ["source", "type", "content", "timestamp"]
        for field in required_fields:
            if field not in chunk_data:
                errors.append(f"Missing required field: {field}")

        # Source validation
        if "source" in chunk_data:
            valid_sources = ["discord", "slack", "webhook", "manual", "api"]
            if chunk_data["source"] not in valid_sources:
                errors.append(f"Invalid source: {chunk_data['source']}. Must be one of {valid_sources}")

        # Type validation
        if "type" in chunk_data:
            valid_types = ["bug_report", "feature_request", "code_snippet",
                          "documentation", "question", "task", "feedback"]
            if chunk_data["type"] not in valid_types:
                errors.append(f"Invalid type: {chunk_data['type']}. Must be one of {valid_types}")

        # Content validation
        if "content" in chunk_data:
            if not isinstance(chunk_data["content"], dict):
                errors.append("Content must be a dictionary")
            else:
                if "title" not in chunk_data["content"]:
                    errors.append("Content must have a 'title' field")
                if "description" not in chunk_data["content"]:
                    errors.append("Content must have a 'description' field")

        # Priority validation (optional)
        if "priority" in chunk_data:
            valid_priorities = ["P0", "P1", "P2", "P3"]
            if chunk_data["priority"] not in valid_priorities:
                errors.append(f"Invalid priority: {chunk_data['priority']}. Must be one of {valid_priorities}")

        # Metadata validation (optional)
        if "metadata" in chunk_data:
            if not isinstance(chunk_data["metadata"], dict):
                errors.append("Metadata must be a dictionary")

        return errors

    def generate_chunk_id(self, chunk_data: Dict[str, Any]) -> str:
        """Generate unique chunk ID based on content hash"""
        content_str = json.dumps(chunk_data, sort_keys=True)
        return hashlib.sha256(content_str.encode()).hexdigest()[:16]

    def save_chunk(self, chunk_data: Dict[str, Any], status: str = "pending") -> str:
        """Save chunk to appropriate directory"""
        chunk_id = self.generate_chunk_id(chunk_data)

        # Add processing metadata
        chunk_data["_chunk_id"] = chunk_id
        chunk_data["_status"] = status
        chunk_data["_processed_at"] = datetime.now().isoformat()

        # Determine target directory
        if status == "pending":
            target_dir = self.pending_dir
        elif status == "processing":
            target_dir = self.processing_dir
        elif status == "completed":
            target_dir = self.completed_dir
        elif status == "failed":
            target_dir = self.failed_dir
        else:
            raise ValueError(f"Invalid status: {status}")

        # Save chunk
        chunk_file = target_dir / f"{chunk_id}.json"
        with open(chunk_file, 'w') as f:
            json.dump(chunk_data, f, indent=2)

        return chunk_id

    def load_chunk(self, chunk_id: str) -> Optional[Dict[str, Any]]:
        """Load chunk from any status directory"""
        for status_dir in [self.pending_dir, self.processing_dir,
                          self.completed_dir, self.failed_dir]:
            chunk_file = status_dir / f"{chunk_id}.json"
            if chunk_file.exists():
                with open(chunk_file, 'r') as f:
                    return json.load(f)
        return None

    def move_chunk(self, chunk_id: str, new_status: str) -> bool:
        """Move chunk between status directories"""
        # Find current location
        current_chunk = None
        current_file = None

        for status_dir in [self.pending_dir, self.processing_dir,
                          self.completed_dir, self.failed_dir]:
            chunk_file = status_dir / f"{chunk_id}.json"
            if chunk_file.exists():
                current_file = chunk_file
                with open(chunk_file, 'r') as f:
                    current_chunk = json.load(f)
                break

        if not current_chunk:
            return False

        # Update status and move
        current_chunk["_status"] = new_status
        current_chunk["_processed_at"] = datetime.now().isoformat()

        # Remove old file
        if current_file:
            current_file.unlink()

        # Save to new location
        self.save_chunk(current_chunk, new_status)
        return True

    def process_chunk(self, chunk_data: Dict[str, Any]) -> Dict[str, Any]:
        """Process a single chunk and integrate into project workflow"""
        result = {
            "chunk_id": chunk_data.get("_chunk_id", "unknown"),
            "success": False,
            "actions_taken": [],
            "errors": []
        }

        try:
            # Move to processing
            self.move_chunk(result["chunk_id"], "processing")

            # Extract content
            content = chunk_data["content"]
            chunk_type = chunk_data["type"]
            priority = chunk_data.get("priority", "P2")  # Default to P2

            # Route based on type
            if chunk_type == "bug_report":
                result["actions_taken"].append(self._process_bug_report(content, priority))
            elif chunk_type == "feature_request":
                result["actions_taken"].append(self._process_feature_request(content, priority))
            elif chunk_type == "code_snippet":
                result["actions_taken"].append(self._process_code_snippet(content, priority))
            elif chunk_type == "documentation":
                result["actions_taken"].append(self._process_documentation(content, priority))
            elif chunk_type == "question":
                result["actions_taken"].append(self._process_question(content, priority))
            elif chunk_type == "task":
                result["actions_taken"].append(self._process_task(content, priority))
            elif chunk_type == "feedback":
                result["actions_taken"].append(self._process_feedback(content, priority))
            else:
                result["errors"].append(f"Unknown chunk type: {chunk_type}")

            if not result["errors"]:
                result["success"] = True
                self.move_chunk(result["chunk_id"], "completed")
            else:
                self.move_chunk(result["chunk_id"], "failed")

        except Exception as e:
            result["errors"].append(f"Processing failed: {str(e)}")
            self.move_chunk(result["chunk_id"], "failed")

        return result

    def _process_bug_report(self, content: Dict[str, Any], priority: str) -> str:
        """Process bug report chunk"""
        title = content.get("title", "Bug Report")
        description = content.get("description", "")

        # Add to appropriate TODO tracker
        tracker_file = self.base_dir / "docs" / "todo" / "todo_testing_ci.md"

        todo_entry = f"""- **[{priority}]:** {title}
  - **Description:** {description}
  - **Source:** External chunk processing
  - **Status:** New bug report - needs investigation
  - **Reproduction:** {content.get("reproduction", "TBD")}
  - **Expected:** {content.get("expected", "TBD")}
  - **Actual:** {content.get("actual", "TBD")}"""

        self._append_to_tracker(tracker_file, todo_entry)
        return f"Added bug report to {tracker_file.name}"

    def _process_feature_request(self, content: Dict[str, Any], priority: str) -> str:
        """Process feature request chunk"""
        title = content.get("title", "Feature Request")
        description = content.get("description", "")

        tracker_file = self.base_dir / "docs" / "todo" / "todo_master.md"

        todo_entry = f"""- **[{priority}]:** {title}
  - **Description:** {description}
  - **Source:** External chunk processing
  - **Status:** New feature request - needs evaluation
  - **Use Case:** {content.get("use_case", "TBD")}
  - **Priority Assessment:** {content.get("priority_reason", "TBD")}"""

        self._append_to_tracker(tracker_file, todo_entry)
        return f"Added feature request to {tracker_file.name}"

    def _process_code_snippet(self, content: Dict[str, Any], priority: str) -> str:
        """Process code snippet chunk"""
        title = content.get("title", "Code Snippet")
        description = content.get("description", "")
        code = content.get("code", "")

        # Save to chunks directory
        chunks_dir = self.base_dir / "chunks" / "external"
        chunks_dir.mkdir(parents=True, exist_ok=True)

        chunk_file = chunks_dir / f"{title.lower().replace(' ', '_')}.txt"
        with open(chunk_file, 'w') as f:
            f.write(f"# {title}\n\n")
            f.write(f"Description: {description}\n\n")
            f.write("Code:\n")
            f.write(code)

        return f"Saved code snippet to {chunk_file}"

    def _process_documentation(self, content: Dict[str, Any], priority: str) -> str:
        """Process documentation chunk"""
        title = content.get("title", "Documentation")
        description = content.get("description", "")

        tracker_file = self.base_dir / "docs" / "todo" / "todo_documentation.md"

        todo_entry = f"""- **[{priority}]:** {title}
  - **Description:** {description}
  - **Source:** External chunk processing
  - **Status:** New documentation - needs review and integration"""

        self._append_to_tracker(tracker_file, todo_entry)
        return f"Added documentation task to {tracker_file.name}"

    def _process_question(self, content: Dict[str, Any], priority: str) -> str:
        """Process question chunk"""
        title = content.get("title", "Question")
        description = content.get("description", "")

        # Add to community tracker
        tracker_file = self.base_dir / "docs" / "todo" / "todo_community_contributors.md"

        todo_entry = f"""- **[{priority}]:** {title}
  - **Description:** {description}
  - **Source:** External chunk processing
  - **Status:** Community question - needs response
  - **Answer:** TBD"""

        self._append_to_tracker(tracker_file, todo_entry)
        return f"Added question to {tracker_file.name}"

    def _process_task(self, content: Dict[str, Any], priority: str) -> str:
        """Process task chunk"""
        title = content.get("title", "Task")
        description = content.get("description", "")

        tracker_file = self.base_dir / "docs" / "todo" / "todo_master.md"

        todo_entry = f"""- **[{priority}]:** {title}
  - **Description:** {description}
  - **Source:** External chunk processing
  - **Status:** New task - needs assignment"""

        self._append_to_tracker(tracker_file, todo_entry)
        return f"Added task to {tracker_file.name}"

    def _process_feedback(self, content: Dict[str, Any], priority: str) -> str:
        """Process feedback chunk"""
        title = content.get("title", "Feedback")
        description = content.get("description", "")

        tracker_file = self.base_dir / "docs" / "todo" / "todo_community_contributors.md"

        todo_entry = f"""- **[{priority}]:** {title}
  - **Description:** {description}
  - **Source:** External chunk processing
  - **Status:** Community feedback - needs review
  - **Action:** TBD"""

        self._append_to_tracker(tracker_file, todo_entry)
        return f"Added feedback to {tracker_file.name}"

    def _append_to_tracker(self, tracker_file: Path, entry: str) -> None:
        """Append entry to TODO tracker file"""
        if not tracker_file.exists():
            # Create basic tracker structure
            content = f"""# {tracker_file.stem.replace('todo_', '').replace('_', ' ').title()} TODO Tracker

**Last Updated:** {datetime.now().strftime('%Y-%m-%d')}
**Owner:** External Chunk Processor

{entry}
"""
        else:
            # Append to existing file
            with open(tracker_file, 'r') as f:
                content = f.read()
            content += f"\n{entry}"

        with open(tracker_file, 'w') as f:
            f.write(content)

    def process_pending_chunks(self) -> Dict[str, Any]:
        """Process all pending chunks"""
        results = {
            "processed": 0,
            "successful": 0,
            "failed": 0,
            "details": []
        }

        # Find all pending chunks
        for chunk_file in self.pending_dir.glob("*.json"):
            try:
                with open(chunk_file, 'r') as f:
                    chunk_data = json.load(f)

                result = self.process_chunk(chunk_data)
                results["processed"] += 1

                if result["success"]:
                    results["successful"] += 1
                else:
                    results["failed"] += 1

                results["details"].append(result)

            except Exception as e:
                results["failed"] += 1
                results["details"].append({
                    "chunk_id": chunk_file.stem,
                    "success": False,
                    "errors": [str(e)]
                })

        return results

    def get_status(self) -> Dict[str, Any]:
        """Get current processing status"""
        status = {
            "pending": len(list(self.pending_dir.glob("*.json"))),
            "processing": len(list(self.processing_dir.glob("*.json"))),
            "completed": len(list(self.completed_dir.glob("*.json"))),
            "failed": len(list(self.failed_dir.glob("*.json"))),
            "total": 0
        }

        status["total"] = sum(status.values())
        return status

def main():
    parser = argparse.ArgumentParser(description="External Chunk Handler for Hydra")
    parser.add_argument("--process-all", action="store_true",
                       help="Process all pending chunks")
    parser.add_argument("--webhook", action="store_true",
                       help="Run as webhook server for real-time chunk processing")
    parser.add_argument("--validate-schema", type=str,
                       help="Validate chunk file against schema")
    parser.add_argument("--status", action="store_true",
                       help="Show current processing status")
    parser.add_argument("--create-test-chunk", type=str,
                       help="Create a test chunk of specified type")

    args = parser.parse_args()

    processor = ChunkProcessor()

    if args.validate_schema:
        # Validate a specific chunk file
        chunk_file = Path(args.validate_schema)
        if not chunk_file.exists():
            print(f"Error: Chunk file {chunk_file} does not exist")
            sys.exit(1)

        with open(chunk_file, 'r') as f:
            chunk_data = json.load(f)

        errors = processor.validate_chunk_schema(chunk_data)
        if errors:
            print("Validation errors:")
            for error in errors:
                print(f"  - {error}")
            sys.exit(1)
        else:
            print("Chunk schema validation passed!")

    elif args.create_test_chunk:
        # Create a test chunk
        chunk_type = args.create_test_chunk

        test_chunks = {
            "bug_report": {
                "source": "manual",
                "type": "bug_report",
                "timestamp": datetime.now().isoformat(),
                "content": {
                    "title": "Test Bug Report",
                    "description": "This is a test bug report from the chunk processor",
                    "reproduction": "Steps to reproduce the bug",
                    "expected": "Expected behavior",
                    "actual": "Actual behavior"
                },
                "priority": "P2"
            },
            "feature_request": {
                "source": "manual",
                "type": "feature_request",
                "timestamp": datetime.now().isoformat(),
                "content": {
                    "title": "Test Feature Request",
                    "description": "This is a test feature request from the chunk processor",
                    "use_case": "How this feature would be used",
                    "priority_reason": "Why this should be prioritized"
                },
                "priority": "P2"
            }
        }

        if chunk_type not in test_chunks:
            print(f"Unknown test chunk type: {chunk_type}")
            print(f"Available types: {', '.join(test_chunks.keys())}")
            sys.exit(1)

        chunk_id = processor.save_chunk(test_chunks[chunk_type])
        print(f"Created test chunk: {chunk_id}")
        print(f"File: {processor.pending_dir / f'{chunk_id}.json'}")

    elif args.status:
        # Show status
        status = processor.get_status()
        print("External Chunk Processing Status:")
        print(f"  Pending: {status['pending']}")
        print(f"  Processing: {status['processing']}")
        print(f"  Completed: {status['completed']}")
        print(f"  Failed: {status['failed']}")
        print(f"  Total: {status['total']}")

    elif args.process_all:
        # Process all pending chunks
        print("Processing pending chunks...")
        results = processor.process_pending_chunks()

        print(f"Processed {results['processed']} chunks")
        print(f"  Successful: {results['successful']}")
        print(f"  Failed: {results['failed']}")

        if results['details']:
            print("\nDetails:")
            for detail in results['details']:
                status = "✓" if detail.get('success', False) else "✗"
                print(f"  {status} {detail.get('chunk_id', 'unknown')}")
                if detail.get('actions_taken'):
                    for action in detail['actions_taken']:
                        print(f"    → {action}")
                if detail.get('errors'):
                    for error in detail['errors']:
                        print(f"    ✗ {error}")

    elif args.webhook:
        print("Starting chunk webhook server...")
        print("This will provide real-time chunk processing via HTTP endpoints")
        print("Use Ctrl+C to stop the server")
        print()

        # Import here to avoid circular imports
        from scripts.chunk_webhook_server import ChunkWebhookServer

        server = ChunkWebhookServer()
        try:
            server.start()
        except KeyboardInterrupt:
            print("\nWebhook server stopped")
        except Exception as e:
            print(f"Webhook server error: {e}")
            sys.exit(1)

    else:
        parser.print_help()

if __name__ == "__main__":
    main()