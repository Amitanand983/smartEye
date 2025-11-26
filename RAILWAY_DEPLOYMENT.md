# Railway Deployment Guide for SmartEye

## Overview

Deploy the SmartEye FastAPI backend to Railway for production-ready video streaming and object detection. Railway is ideal for this project because it supports:

- ✅ Long-running processes (video streaming)
- ✅ Generous free tier (512MB RAM, shared CPU)
- ✅ Automatic HTTPS
- ✅ Easy environment variable management
- ✅ GitHub integration for auto-deployment

---

## Prerequisites

1. **Railway Account:** Sign up at [railway.app](https://railway.app) (free tier available)
2. **GitHub Account:** (Optional) For automatic deployments
3. **Railway CLI:** (Optional) For command-line deployment

```bash
# Install Railway CLI (optional)
npm install -g @railway/cli

# Or use Homebrew on macOS
brew install railway
```

---

## Deployment Options

### Option 1: Deploy via Railway Dashboard (Easiest)

#### Step 1: Push to GitHub

```bash
cd /Users/amitanand/Desktop/CVPR\ Project/smartEye
git add .
git commit -m "Add Railway deployment configuration"
git push origin main
```

#### Step 2: Create Railway Project

1. Go to [railway.app](https://railway.app)
2. Click **"New Project"**
3. Select **"Deploy from GitHub repo"**
4. Choose your `smartEye` repository
5. Railway will auto-detect the Dockerfile and deploy

#### Step 3: Configure Environment Variables

In Railway dashboard, add these environment variables:

```
PORT=8000
PYTHONUNBUFFERED=1
```

#### Step 4: Wait for Deployment

- Railway will build the Docker image (~3-5 minutes)
- Once deployed, you'll get a URL like: `https://smarteye-production.up.railway.app`

### Option 2: Deploy via Railway CLI

```bash
# Login to Railway
railway login

# Initialize project
cd /Users/amitanand/Desktop/CVPR\ Project/smartEye
railway init

# Deploy
railway up

# Open in browser
railway open
```

---

## Post-Deployment Configuration

### 1. Test the Deployment

```bash
# Test health endpoint
curl https://your-app.railway.app/health

# Expected response:
# {"status": "healthy", "timestamp": 1234567890.123}
```

### 2. Test Inference Endpoint

```bash
curl -X POST https://your-app.railway.app/inference \
  -H "Content-Type: application/json" \
  -d '{
    "image_data": "base64_encoded_image_here",
    "stream_name": "test",
    "frame_id": 1,
    "timestamp": 1234567890.123
  }'
```

### 3. View Logs

```bash
# Via CLI
railway logs

# Or view in Railway dashboard
```

---

## Frontend Deployment

The React frontend should be deployed separately. Recommended options:

### Option A: Vercel (Recommended)

```bash
cd frontend
npm install
vercel

# Update API URL in frontend to point to Railway backend
# Example: https://smarteye-production.up.railway.app
```

### Option B: Netlify

```bash
cd frontend
npm run build

# Deploy dist/ folder to Netlify
```

### Option C: Railway (Same Project)

Add frontend as a separate service in the same Railway project:

1. In Railway dashboard, click **"+ New"**
2. Select **"Empty Service"**
3. Configure build command: `cd frontend && npm install && npm run build`
4. Configure start command: `cd frontend && npm run preview`

---

## Environment Variables Reference

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `PORT` | No | 8000 | Server port (Railway sets automatically) |
| `PYTHONUNBUFFERED` | No | 1 | Disable Python output buffering |

---

## Resource Requirements

### Free Tier Limits
- **RAM:** 512MB (sufficient for YOLOv8n model)
- **CPU:** Shared vCPU
- **Storage:** 1GB
- **Bandwidth:** 100GB/month

### Recommended Upgrades
For production with multiple concurrent streams:
- **Hobby Plan:** $5/month
  - 8GB RAM
  - 8 vCPU
  - 100GB storage

---

## Troubleshooting

### Issue: Build Fails with "Out of Memory"

**Solution:** The YOLOv8 model download during build might exceed memory limits.

```dockerfile
# In Dockerfile, add this before pip install:
ENV PIP_NO_CACHE_DIR=1
```

### Issue: Health Check Fails

**Solution:** Increase health check timeout in `railway.json`:

```json
{
  "deploy": {
    "healthcheckTimeout": 200
  }
}
```

### Issue: Model Download Slow

**Solution:** Pre-download the model and commit it to the repository:

```bash
# Download model locally
python -c "from ultralytics import YOLO; YOLO('yolov8n.pt')"

# Add to git (remove from .dockerignore first)
git add yolov8n.pt
git commit -m "Add pre-downloaded YOLOv8 model"
```

### Issue: YouTube Downloads Fail

**Solution:** Ensure `yt-dlp` is in requirements.txt (already added) and Railway has internet access (it does by default).

---

## Monitoring and Scaling

### View Metrics

In Railway dashboard:
- CPU usage
- Memory usage
- Network traffic
- Request logs

### Scaling

Railway auto-scales within your plan limits. For manual scaling:

1. Go to **Settings** → **Resources**
2. Adjust replicas (Hobby plan and above)

---

## Cost Estimation

### Free Tier
- **Cost:** $0/month
- **Limits:** 512MB RAM, $5 execution credit
- **Best for:** Development, testing, low traffic

### Hobby Plan
- **Cost:** $5/month
- **Limits:** 8GB RAM, 8 vCPU
- **Best for:** Production, multiple concurrent streams

---

## Updating Deployment

### Automatic (GitHub Integration)

```bash
# Make changes
git add .
git commit -m "Update feature"
git push origin main

# Railway auto-deploys on push
```

### Manual (CLI)

```bash
railway up
```

---

## Security Best Practices

1. **Environment Variables:** Store sensitive data in Railway environment variables, not in code
2. **HTTPS:** Railway provides automatic HTTPS (no configuration needed)
3. **CORS:** Configure CORS in `server.py` to allow only your frontend domain

---

## Next Steps

1. ✅ Deploy backend to Railway
2. ✅ Deploy frontend to Vercel/Netlify
3. ✅ Update frontend API URL to Railway backend
4. ✅ Test end-to-end video streaming
5. ✅ Monitor logs and metrics

---

## Support

- **Railway Docs:** [docs.railway.app](https://docs.railway.app)
- **Railway Discord:** [discord.gg/railway](https://discord.gg/railway)
- **SmartEye Issues:** GitHub repository issues

---

**SmartEye on Railway** - Production-ready video streaming and object detection! 🚀
