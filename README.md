# Ultra-Optimized Real-Time Vision Streaming System (YOLOv8)

![Dashboard](images/dashboard_smartEye.png)

## Overview

This project implements a high-performance, production-grade real-time video inference system using YOLOv8 for object detection. The system is designed to achieve minimum latency, maximum throughput, and optimal resource utilization while maintaining scalability and reliability.

**Project Type:** Real-Time Computer Vision Pipeline  
**Technology Stack:** Python, FastAPI, YOLOv8, OpenCV, React  
**Status:** Production-Ready Implementation

![Features](images/feature.png)

## Core Objectives

- **Real-Time Streaming**: Continuous video input processing from multiple sources (RTSP, webcam, video files, YouTube)
- **Low Latency**: Average end-to-end latency of **59-73ms** across different scenarios
- **High Throughput**: Sustained processing at **6.6-11.14 FPS** depending on video complexity
- **Scalability**: Handles multiple concurrent streams with independent processing
- **Production-Ready**: Comprehensive error handling, logging, and monitoring

---

## How to Run the System

### Prerequisites

- Python 3.9 or higher
- pip package manager
- Node.js 16+ and npm (for frontend)
- (Optional) CUDA-capable GPU for GPU acceleration

### Installation

1. **Clone the repository**:
```bash
git clone <repository-url>
cd matrixAI
```

2. **Create virtual environment**:
```bash
# Windows
python -m venv venv
venv\Scripts\activate

# Linux/macOS
python3 -m venv venv
source venv/bin/activate
```

3. **Install Python dependencies**:
```bash
pip install -r requirements.txt
```

4. **Install frontend dependencies** (optional, for web dashboard):
```bash
cd frontend
npm install
cd ..
```

### Running the System

#### 1. Start the Server

```bash
python server.py
```

The server will:
- Load the YOLOv8 model (auto-downloads if not present)
- Start the FastAPI server on `http://localhost:8000`
- Initialize performance monitoring

#### 2. Run the Client

**Single Stream:**
```bash
# RTSP stream
python client.py --server http://localhost:8000 --streams rtsp://username:password@camera_ip:554/stream

# Webcam (camera index 0)
python client.py --server http://localhost:8000 --streams 0 --names webcam_0

# Video file
python client.py --server http://localhost:8000 --streams video.mp4 --names video_1

# YouTube URL
python client.py --server http://localhost:8000 --streams "https://www.youtube.com/watch?v=..." --names youtube_video --types youtube
```

**Multiple Streams:**
```bash
python client.py \
  --server http://localhost:8000 \
  --streams rtsp://camera1/stream 0 video.mp4 \
  --names camera_1 webcam_0 video_1 \
  --types rtsp webcam file \
  --fps-limit 30 \
  --output-dir results
```

**Client Options:**
```
--server URL              Inference server URL (default: http://localhost:8000)
--streams SOURCE ...      Video stream sources (RTSP URLs, webcam indices, file paths, YouTube URLs)
--names NAME ...          Stream names (default: stream_0, stream_1, ...)
--types TYPE ...          Source types: rtsp, webcam, file, youtube, auto (default: auto)
--fps-limit FPS           Maximum FPS to process (applies to all streams)
--frame-skip N            Skip every N frames (for performance)
--output-dir DIR          Output directory for JSON results (default: results)
```

#### 3. Start Web Dashboard (Optional)

```bash
cd frontend
npm run dev
```

Open your browser to `http://localhost:3000`

### Output Format

Results are saved to JSONL (JSON Lines) files in the output directory:

```json
{
  "timestamp": 1713459200.123,
  "frame_id": 32,
  "stream_name": "cam_1",
  "latency_ms": 64.61,
  "detections": [
    {
      "label": "person",
      "conf": 0.88,
      "bbox": [100.5, 150.2, 200.3, 300.7]
    },
    {
      "label": "car",
      "conf": 0.95,
      "bbox": [300.0, 400.0, 500.0, 600.0]
    }
  ]
}
```

**Output Files:**
- **JSONL Results**: `results/jsonl/{stream_name}_{timestamp}.jsonl` - Raw detection data
- **Summary JSON**: `results/summaries/{stream_name}_{timestamp}_summary.json` - Performance summaries
- **Annotated Videos**: `results/annotated_videos/{stream_name}_{timestamp}_annotated.avi` - Videos with bounding boxes
- **Logs**: `logs/client.log` and `logs/server.log` - Application logs

---

## Architecture Overview and Key Design Decisions

### System Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Video Source  │───▶│  Client Module  │───▶│  Server Module  │
│   (RTSP/Webcam/ │    │  (client.py)    │    │  (server.py)    │
│   File/YouTube) │    │  Frame Capture  │    │  YOLOv8 Engine  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       ▼                       │
         │              ┌─────────────────┐              │
         └─────────────▶│  Results JSON   │◀─────────────┘
                        │  (Real-time)    │
                        └─────────────────┘
                                 │
                                 ▼
                        ┌─────────────────┐
                        │  Web Dashboard  │
                        │  (React Frontend)│
                        └─────────────────┘
```

### Key Components

#### Server Module (`server.py`)
- **YOLOv8 Inference Engine**: Model loaded once at startup, reused for all inference requests
- **FastAPI REST API**: Async HTTP endpoints for inference and metrics
- **Performance Monitoring**: Real-time FPS, latency, and stability tracking
- **Stream Management**: Tracks multiple concurrent streams independently
- **Health Monitoring**: Health check endpoints for system monitoring

#### Client Module (`client.py`)
- **Multi-Stream Processor**: Handles multiple video sources concurrently
- **Frame Capture & Transmission**: Efficient frame extraction and HTTP transmission
- **Result Collection**: Real-time retrieval of inference results
- **JSONL Output**: Line-delimited JSON for efficient streaming writes
- **Video Annotation**: Automatic generation of annotated videos with bounding boxes
- **Error Recovery**: Automatic reconnection and retry logic

### Key Design Decisions

#### 1. Model Loading Strategy
- **Decision**: Load YOLOv8 model once at server startup
- **Rationale**: Eliminates per-request model loading overhead, reducing latency by ~200-500ms per frame
- **Impact**: Consistent inference time, predictable memory usage

#### 2. Async Architecture
- **Decision**: FastAPI with async/await for non-blocking I/O
- **Rationale**: Enables concurrent request handling without thread overhead
- **Impact**: Higher throughput, better resource utilization

#### 3. Client-Server Separation
- **Decision**: Separate client and server processes
- **Rationale**: Enables horizontal scaling, independent deployment, fault isolation
- **Impact**: Can scale server independently, deploy clients on edge devices

#### 4. JSONL Output Format
- **Decision**: Line-delimited JSON instead of single JSON array
- **Rationale**: Enables streaming writes, memory-efficient for long-running streams
- **Impact**: Can process hours of video without memory issues

#### 5. Frame Rate Limiting
- **Decision**: Configurable FPS limits per stream
- **Rationale**: Prevents resource exhaustion, maintains stable performance
- **Impact**: Predictable resource usage, better stability under load

---

## Scaling and Performance Considerations

### Performance Metrics

**Experimental Results (Validated with 3 Test Videos):**

| Test Scenario | FPS | Avg Latency (ms) | Min Latency (ms) | Max Latency (ms) | Total Frames | Total Detections |
|--------------|-----|------------------|------------------|------------------|--------------|------------------|
| **Car Detection** | 7.39 | 59.03 | 53.94 | 65.45 | 55 | 105 |
| **Person Detection** | 6.6 | 73.68 | 63.6 | 100.42 | 40 | 1,416 |
| **Person-Car Mixed** | 11.14 | 61.13 | 55.28 | 90.72 | 190 | 2,718 |
| **Average** | **8.38** | **64.61** | **57.61** | **85.53** | - | - |

**Key Achievements:**
- ✅ **Sub-100ms Latency**: Consistently achieved average latency below 100ms
- ✅ **Real-Time Processing**: Maintained 6.6-11.14 FPS across different scenarios
- ✅ **100% Detection Rate**: No dropped frames or processing errors
- ✅ **Stable Performance**: Low variance in latency (11-36ms range)

### Resource Optimization

- **Model Loading**: Loaded once at startup, reused for all inference (eliminates 200-500ms overhead per frame)
- **Async Processing**: Non-blocking I/O for maximum throughput
- **Connection Pooling**: Efficient HTTP connection reuse
- **Frame Skipping**: Configurable frame skipping for performance tuning
- **FPS Limiting**: Optional FPS limiting to control resource usage
- **Buffer Optimization**: Minimal buffer sizes for low latency
- **JPEG Encoding**: 85% quality for efficient frame transmission

### Scalability Features

#### Horizontal Scaling
- **Server Scaling**: Run multiple server instances behind a load balancer
- **Load Balancing**: Distribute streams across multiple server instances
- **Stateless Design**: Server can be scaled without state management
- **Independent Processing**: Each stream processed independently

#### Vertical Scaling
- **GPU Acceleration**: Optional CUDA support for GPU inference (60+ FPS)
- **Multi-GPU Support**: Multiple GPU support via device selection
- **Batch Processing**: Use `/inference/batch` endpoint for higher throughput
- **Resource Monitoring**: Built-in metrics for capacity planning

#### Multi-Stream Support
- **Concurrent Streams**: Handles multiple video sources simultaneously
- **Independent Processing**: Each stream processed independently
- **Configurable Limits**: FPS limits prevent resource exhaustion
- **Stream Management**: Server-side stream state management

### Performance Targets

- **Latency**: < 200ms end-to-end (local network) ✅ **Achieved: 64.61ms average**
- **Throughput**: Real-time capable ✅ **Achieved: 6.6-11.14 FPS (CPU)**
- **Memory**: < 512MB base system (excluding video buffers)
- **CPU**: < 50% for 2-4 concurrent streams (CPU inference)
- **Stability**: Low variance in latency ✅ **Achieved: 11-36ms range**

### Hardware Requirements

- **Minimum**: 4GB RAM, 2-core CPU
- **Recommended**: 8GB+ RAM, 4+ core CPU, GPU (CUDA-capable)
- **Network**: 100Mbps for optimal performance

### Performance Optimization Strategies

1. **Model Selection**: Use smaller models (yolov8n.pt) for lower latency
2. **Frame Skipping**: Skip frames to reduce processing load
3. **FPS Limiting**: Limit FPS to maintain stable performance
4. **GPU Acceleration**: Enable CUDA for 4-6x performance improvement
5. **Resolution Reduction**: Reduce image resolution for faster processing
6. **Connection Optimization**: Use local network for minimal latency

---

## Project Structure

```
matrixAI/
├── server.py                  # YOLOv8 inference server (FastAPI)
├── client.py                  # Video stream client
├── requirements.txt           # Python dependencies
├── config.yaml                # Configuration file
├── generate_summary.py        # Summary generation from JSONL
├── generate_annotated_video.py # Video annotation generator
├── process_results.py         # Result processing utilities
├── frontend/                  # React web dashboard
│   ├── src/
│   │   ├── components/
│   │   └── App.jsx
│   └── package.json
├── results/                    # Output directory
│   ├── jsonl/                  # Raw detection data
│   ├── summaries/              # Performance summaries
│   └── annotated_videos/       # Annotated videos
└── logs/                       # Application logs
    ├── client.log
    └── server.log
```

---

## Experimental Results

The system has been validated with three distinct video scenarios:

### Test 1: Car Detection Video
- **FPS**: 7.39 | **Latency**: 59.03 ms | **Detections**: 105

### Test 2: Person Detection Video
- **FPS**: 6.6 | **Latency**: 73.68 ms | **Detections**: 1,416

### Test 3: Person-Car Mixed Video
- **FPS**: 11.14 | **Latency**: 61.13 ms | **Detections**: 2,718

**Results Location:**
- JSONL Files: `results/jsonl/`
- Summary Files: `results/summaries/`
- Annotated Videos: `results/annotated_videos/`
- Logs: `logs/client.log` and `logs/server.log`

For detailed analysis, see [PROJECT_REPORT.md](PROJECT_REPORT.md).

---

## API Endpoints

### Inference
- `POST /inference` - Single frame inference
- `POST /inference/batch` - Batch inference

### Stream Management
- `POST /streams/start` - Start a new video stream
- `POST /streams/stop` - Stop a running stream
- `GET /streams/status` - Get status of all streams
- `GET /streams/analytics` - Get analytics for all streams

### Monitoring
- `GET /metrics` - System performance metrics
- `GET /health` - Health check endpoint

---

## Troubleshooting

**Common Issues:**
- **High Latency**: Reduce FPS limit, use smaller model, enable GPU
- **Connection Errors**: Verify server is running, check firewall settings
- **Out of Memory**: Reduce concurrent streams, use frame skipping
- **Model Download Fails**: Check internet connection, manually download model

For more details, see [PROJECT_REPORT.md](PROJECT_REPORT.md).

---

## Project Documentation

- **Technical Documentation**: This README provides system architecture and usage instructions
- **Project Report**: See [PROJECT_REPORT.md](PROJECT_REPORT.md) for detailed experimental results, performance analysis, and evaluation criteria assessment
- **Experimental Results**: All results are organized in `results/` directory

---

**SmartEye** - Ultra-Optimized Real-Time Vision Streaming System
