#!/usr/bin/env python3
"""
Chunk Processing Dashboard Integration

Integrates chunk processing status into the Hydra admin dashboard.
Provides real-time monitoring and management of external chunks.

Usage:
    python3 scripts/chunk_dashboard.py [--web] [--status] [--monitor]

Author: Hydra Development Team
Created: 2025-11-29
"""

import json
import os
import sys
import argparse
import time
from datetime import datetime
from pathlib import Path

# Add project root to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from scripts.external_chunk_handler import ChunkProcessor

class ChunkDashboard:
    """Dashboard integration for chunk processing"""

    def __init__(self):
        self.processor = ChunkProcessor()
        self.base_dir = Path(__file__).parent.parent

    def get_dashboard_data(self):
        """Get comprehensive dashboard data"""
        status = self.processor.get_status()

        # Get recent chunks
        recent_chunks = self._get_recent_chunks()

        # Get processing statistics
        stats = self._get_processing_stats()

        return {
            "timestamp": datetime.now().isoformat(),
            "status": status,
            "recent_chunks": recent_chunks,
            "statistics": stats,
            "health": self._get_health_status()
        }

    def _get_recent_chunks(self, limit=10):
        """Get recent chunks from all directories"""
        recent_chunks = []

        for status_dir in ["pending", "processing", "completed", "failed"]:
            dir_path = getattr(self.processor, f"{status_dir}_dir")

            if dir_path.exists():
                for chunk_file in sorted(dir_path.glob("*.json"),
                                       key=lambda x: x.stat().st_mtime,
                                       reverse=True)[:limit]:
                    try:
                        with open(chunk_file, 'r') as f:
                            chunk_data = json.load(f)

                        recent_chunks.append({
                            "id": chunk_data.get("_chunk_id", chunk_file.stem),
                            "type": chunk_data.get("type", "unknown"),
                            "source": chunk_data.get("source", "unknown"),
                            "status": status_dir,
                            "title": chunk_data.get("content", {}).get("title", "No title"),
                            "timestamp": chunk_data.get("_processed_at", chunk_data.get("timestamp", "unknown")),
                            "priority": chunk_data.get("priority", "P3")
                        })
                    except Exception as e:
                        print(f"Error reading chunk {chunk_file}: {e}")

        # Sort by timestamp and limit
        recent_chunks.sort(key=lambda x: x["timestamp"], reverse=True)
        return recent_chunks[:limit]

    def _get_processing_stats(self):
        """Get processing statistics"""
        stats = {
            "total_processed": 0,
            "success_rate": 0.0,
            "avg_processing_time": 0.0,
            "chunk_types": {},
            "sources": {},
            "daily_stats": {}
        }

        # Analyze completed chunks
        completed_dir = self.processor.completed_dir
        if completed_dir.exists():
            for chunk_file in completed_dir.glob("*.json"):
                try:
                    with open(chunk_file, 'r') as f:
                        chunk_data = json.load(f)

                    stats["total_processed"] += 1

                    # Count types and sources
                    chunk_type = chunk_data.get("type", "unknown")
                    source = chunk_data.get("source", "unknown")

                    stats["chunk_types"][chunk_type] = stats["chunk_types"].get(chunk_type, 0) + 1
                    stats["sources"][source] = stats["sources"].get(source, 0) + 1

                except Exception as e:
                    print(f"Error analyzing chunk {chunk_file}: {e}")

        # Calculate success rate
        total_chunks = sum(self.processor.get_status().values())
        if total_chunks > 0:
            completed_count = len(list(completed_dir.glob("*.json"))) if completed_dir.exists() else 0
            stats["success_rate"] = (completed_count / total_chunks) * 100

        return stats

    def _get_health_status(self):
        """Get health status of chunk processing system"""
        health = {
            "status": "healthy",
            "issues": [],
            "checks": {
                "directories_exist": True,
                "processor_initialized": True,
                "recent_activity": True
            }
        }

        # Check directories
        for attr in ["pending_dir", "processing_dir", "completed_dir", "failed_dir"]:
            dir_path = getattr(self.processor, attr)
            if not dir_path.exists():
                health["issues"].append(f"Directory {attr} does not exist")
                health["checks"]["directories_exist"] = False

        # Check recent activity (chunks processed in last 24 hours)
        recent_activity = False
        cutoff_time = time.time() - (24 * 60 * 60)  # 24 hours ago

        for status_dir in [self.processor.completed_dir, self.processor.failed_dir]:
            if status_dir.exists():
                for chunk_file in status_dir.glob("*.json"):
                    if chunk_file.stat().st_mtime > cutoff_time:
                        recent_activity = True
                        break
                if recent_activity:
                    break

        health["checks"]["recent_activity"] = recent_activity
        if not recent_activity:
            health["issues"].append("No chunk processing activity in last 24 hours")

        # Set overall status
        if health["issues"]:
            health["status"] = "warning" if len(health["issues"]) == 1 else "error"

        return health

    def print_status_dashboard(self):
        """Print status dashboard to console"""
        data = self.get_dashboard_data()

        print("🔄 External Chunk Processing Dashboard")
        print("=" * 50)
        print(f"📊 Status: {data['status']}")
        print(f"⏰ Last Update: {data['timestamp']}")
        print()

        # Status counts
        status = data['status']
        print("📈 Processing Status:")
        for key, value in status.items():
            print(f"  {key.capitalize()}: {value}")
        print()

        # Health status
        health = data['health']
        health_icon = "✅" if health['status'] == 'healthy' else "⚠️" if health['status'] == 'warning' else "❌"
        print(f"{health_icon} Health Status: {health['status'].upper()}")
        if health['issues']:
            for issue in health['issues']:
                print(f"  • {issue}")
        print()

        # Recent chunks
        recent = data['recent_chunks'][:5]  # Show top 5
        if recent:
            print("🕒 Recent Chunks:")
            for chunk in recent:
                status_icon = {
                    "pending": "⏳",
                    "processing": "🔄",
                    "completed": "✅",
                    "failed": "❌"
                }.get(chunk['status'], "❓")

                print(f"  {status_icon} [{chunk['priority']}] {chunk['type']} - {chunk['title'][:50]}")
            print()

        # Statistics
        stats = data['statistics']
        print("📊 Processing Statistics:")
        print(f"  Total Processed: {stats['total_processed']}")
        print(".1f")
        if stats['chunk_types']:
            print("  Chunk Types:")
            for chunk_type, count in stats['chunk_types'].items():
                print(f"    {chunk_type}: {count}")
        print()

    def export_dashboard_json(self, output_file=None):
        """Export dashboard data to JSON file"""
        data = self.get_dashboard_data()

        if not output_file:
            output_file = self.base_dir / "out" / "chunk_dashboard.json"

        output_file.parent.mkdir(parents=True, exist_ok=True)

        with open(output_file, 'w') as f:
            json.dump(data, f, indent=2)

        print(f"Dashboard data exported to {output_file}")

    def monitor_mode(self, interval=30):
        """Monitor mode - continuously update dashboard"""
        print("🔄 Starting chunk processing monitor...")
        print("Press Ctrl+C to stop")
        print()

        try:
            while True:
                os.system('clear' if os.name == 'posix' else 'cls')
                self.print_status_dashboard()
                print(f"Next update in {interval} seconds...")
                time.sleep(interval)
        except KeyboardInterrupt:
            print("\n👋 Monitor stopped by user")

def main():
    parser = argparse.ArgumentParser(description="Chunk Processing Dashboard")
    parser.add_argument('--status', action='store_true',
                       help='Show current status dashboard')
    parser.add_argument('--export', type=str,
                       help='Export dashboard data to JSON file')
    parser.add_argument('--monitor', type=int, nargs='?', const=30,
                       help='Monitor mode with update interval in seconds (default: 30)')
    parser.add_argument('--web', action='store_true',
                       help='Start web dashboard (not implemented yet)')

    args = parser.parse_args()

    dashboard = ChunkDashboard()

    if args.status:
        dashboard.print_status_dashboard()
    elif args.export:
        dashboard.export_dashboard_json(Path(args.export))
    elif args.monitor:
        dashboard.monitor_mode(args.monitor)
    elif args.web:
        print("Web dashboard not implemented yet")
        print("Use --status for console dashboard")
    else:
        dashboard.print_status_dashboard()

if __name__ == "__main__":
    main()