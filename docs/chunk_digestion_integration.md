# Enhanced Chunk Digestion Integration

This document describes the improved integration of the chunk digestion system into the Hydra project workflow.

## Overview

The chunk digestion system has been significantly enhanced with better integration across multiple components:

- **Automated Processing**: Integrated into priority sector automation
- **Real-time Webhook**: HTTP API for external chunk submission
- **Dashboard Monitoring**: Real-time status monitoring and health checks
- **Admin Interface**: Integrated into the codespaces admin suite

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   External      │    │   Webhook        │    │   Chunk         │
│   Sources       │───▶│   Server         │───▶│   Processor     │
│                 │    │   (HTTP API)     │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Automation    │    │   Dashboard      │    │   Admin         │
│   Scripts       │    │   Monitor        │    │   Interface     │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## Integration Points

### 1. Automation Scripts

**Files Modified:**
- `scripts/automate_priority.sh` - Added chunk processing to integration sector
- `scripts/automate_top_level.sh` - Added chunk processing to full automation

**Integration:**
```bash
# In integration sector automation
python3 scripts/external_chunk_handler.py --process-all

# In top-level automation
python3 scripts/external_chunk_handler.py --process-all
```

### 2. Webhook Server

**New File:** `scripts/chunk_webhook_server.py`

**Endpoints:**
- `POST /chunks` - Submit chunks for processing
- `GET /status` - Get processing status
- `GET /health` - Health check

**Usage:**
```bash
# Start webhook server
python3 scripts/external_chunk_handler.py --webhook

# Or directly
python3 scripts/chunk_webhook_server.py --port 8080
```

### 3. Dashboard Integration

**New File:** `scripts/chunk_dashboard.py`

**Features:**
- Real-time status monitoring
- Health checks
- Processing statistics
- Recent chunks display

**Usage:**
```bash
# Console dashboard
python3 scripts/chunk_dashboard.py --status

# Monitor mode
python3 scripts/chunk_dashboard.py --monitor 30

# Export to JSON
python3 scripts/chunk_dashboard.py --export dashboard.json
```

### 4. Admin Interface Integration

**File Modified:** `scripts/codespaces_admin.sh`

**New Menu Option:** "11. Chunk Processing Status"

**Integration:**
- Added `chunk_processing_status()` function
- Integrated into main menu and direct command calls
- Shows real-time chunk processing status

## Workflow Integration

### Automated Processing

Chunks are now automatically processed as part of:

1. **Priority Sector Automation** (`make automate-priority`)
2. **Full Automation** (`make automate-top-level`)
3. **Quick Automation** (`make automate-quick`)

### Manual Processing

```bash
# Process all pending chunks
python3 scripts/external_chunk_handler.py --process-all

# Check status
python3 scripts/external_chunk_handler.py --status

# Create test chunks
python3 scripts/external_chunk_handler.py --create-test-chunk bug_report
```

### Real-time Processing

```bash
# Start webhook server for real-time processing
python3 scripts/external_chunk_handler.py --webhook
```

### Monitoring

```bash
# View dashboard
python3 scripts/chunk_dashboard.py --status

# Continuous monitoring
python3 scripts/chunk_dashboard.py --monitor
```

## Chunk Types Supported

The system processes the following chunk types:

- **bug_report** → Added to `docs/todo/todo_testing_ci.md`
- **feature_request** → Added to `docs/todo/todo_master.md`
- **code_snippet** → Saved to `chunks/external/`
- **documentation** → Added to `docs/todo/todo_documentation.md`
- **question** → Added to `docs/todo/todo_community_contributors.md`
- **task** → Added to `docs/todo/todo_master.md`
- **feedback** → Added to `docs/todo/todo_community_contributors.md`

## Directory Structure

```
out/external_chunks/
├── pending/          # Chunks waiting for processing
├── processing/       # Chunks currently being processed
├── completed/        # Successfully processed chunks
└── failed/           # Failed chunks

chunks/external/      # Saved code snippets and external content
```

## API Examples

### Submitting a Chunk via Webhook

```bash
curl -X POST http://localhost:8080/chunks \
  -H "Content-Type: application/json" \
  -d '{
    "source": "discord",
    "type": "bug_report",
    "timestamp": "2025-11-29T00:43:40.494863Z",
    "content": {
      "title": "Test Bug Report",
      "description": "This is a test bug report",
      "reproduction": "Steps to reproduce",
      "expected": "Expected behavior",
      "actual": "Actual behavior"
    },
    "priority": "P2"
  }'
```

### Checking Status

```bash
curl http://localhost:8080/status
curl http://localhost:8080/health
```

## Health Monitoring

The system includes comprehensive health checks:

- **Directory Structure**: Ensures all required directories exist
- **Processor Initialization**: Verifies chunk processor is working
- **Recent Activity**: Monitors processing activity (last 24 hours)
- **Error Tracking**: Tracks failed chunks and processing errors

## Benefits

1. **Automated Integration**: Chunks are processed as part of regular automation
2. **Real-time Processing**: Webhook server enables immediate chunk handling
3. **Comprehensive Monitoring**: Dashboard provides full visibility into processing
4. **Admin Integration**: Status available through admin interface
5. **Error Handling**: Robust error handling and recovery mechanisms
6. **Extensible Architecture**: Easy to add new chunk types and processing logic

## Usage Examples

### Daily Automation
```bash
# Run full automation including chunk processing
make automate-top-level
```

### Real-time Monitoring
```bash
# Start dashboard monitor
python3 scripts/chunk_dashboard.py --monitor 60
```

### Admin Interface
```bash
# Access chunk status through admin menu
./scripts/codespaces_admin.sh chunks
```

### Webhook Integration
```bash
# Start webhook server for external integrations
python3 scripts/external_chunk_handler.py --webhook
```

This enhanced integration provides a complete chunk digestion pipeline that seamlessly integrates with the Hydra project's existing automation and monitoring infrastructure.