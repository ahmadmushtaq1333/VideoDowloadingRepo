# Complete Setup Guide: Video Downloader App + Backend

This guide walks you through setting up and deploying the complete video downloader solution.

## 🚀 Quick Start

### What Was Fixed

**Issue 1: Mock Data on Android APK**
- ❌ Old: App fell back to mock data when yt-dlp wasn't available
- ✅ New: Uses backend API for actual video extraction on mobile devices

**Issue 2: Download Button Only Works with Clipboard Paste**
- ❌ Old: Manual URL paste didn't trigger video info extraction
- ✅ New: Pressing Enter on the URL field automatically extracts video info

---

## 📱 Flutter App Setup

### 1. Update Backend URL

Edit `lib/services/video_extraction_service.dart`:

```dart
final String _backendUrl = 'https://your-backend-url.com/api/extract';
```

**For local testing:**
```dart
final String _backendUrl = 'http://localhost:3000/api/extract';
```

**For production (example URLs):**
- Railway: `https://your-app.railway.app/api/extract`
- Heroku: `https://your-app.herokuapp.com/api/extract`
- Custom Domain: `https://api.yourdomain.com/api/extract`

### 2. Build APK with Updated URL

```bash
flutter build apk --release
```

The APK will now use the backend API instead of mock data.

---

## 🖥️ Backend Server Setup

### Local Development

#### Prerequisites
```bash
# Install Node.js (v14+)
# https://nodejs.org/

# Install yt-dlp
# macOS:
brew install yt-dlp

# Linux:
sudo apt-get install yt-dlp

# Or via pip:
pip install yt-dlp
```

#### Start Backend

```bash
cd backend
npm install
npm run dev
```

Server runs on `http://localhost:3000`

Test the API:
```bash
curl -X POST http://localhost:3000/api/extract \
  -H "Content-Type: application/json" \
  -d '{"url":"https://www.youtube.com/watch?v=dQw4w9WgXcQ"}'
```

---

## 🌐 Production Deployment

### Option 1: Railway (Recommended - Easiest)

1. **Create Railway Account**
   - Go to https://railway.app
   - Sign up with GitHub

2. **Deploy Backend**
   ```bash
   # From project root
   git push origin fix/clipboard-and-mock-data-issues
   
   # In Railway dashboard:
   # - Connect GitHub repository
   # - Select this repo
   # - Railway auto-detects Node.js
   ```

3. **Set Environment Variables**
   - In Railway Dashboard: Variables tab
   - Add: `PORT=3000`

4. **Get Backend URL**
   - In Railway Dashboard: Domains tab
   - Copy the generated URL (e.g., `https://video-downloader-backend.railway.app`)

5. **Update Flutter App**
   ```dart
   final String _backendUrl = 'https://video-downloader-backend.railway.app/api/extract';
   ```

### Option 2: Heroku

1. **Install Heroku CLI**
   ```bash
   # macOS
   brew tap heroku/brew && brew install heroku
   
   # Linux/Windows
   # https://devcenter.heroku.com/articles/heroku-cli
   ```

2. **Deploy**
   ```bash
   heroku create your-app-name
   heroku buildpacks:add https://github.com/yt-dlp/yt-dlp.git
   git push heroku fix/clipboard-and-mock-data-issues:main
   ```

3. **Get Backend URL**
   ```
   https://your-app-name.herokuapp.com/api/extract
   ```

### Option 3: Docker + Any Server

1. **Create Dockerfile** (or use the one in backend/README.md)

2. **Build & Run**
   ```bash
   docker build -t video-extractor-api .
   docker run -p 3000:3000 video-extractor-api
   ```

3. **Deploy to VPS/Server**
   - Push Docker image to registry
   - Pull and run on your server

---

## ✅ Testing the Complete Solution

### Test 1: Backend API

```bash
# Health check
curl http://localhost:3000/health

# Extract video info
curl -X POST http://localhost:3000/api/extract \
  -H "Content-Type: application/json" \
  -d '{"url":"https://www.youtube.com/watch?v=dQw4w9WgXcQ"}'
```

Expected response:
```json
{
  "url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
  "title": "Rick Astley - Never Gonna Give You Up",
  "thumbnail": "https://...",
  "duration": 212,
  "uploader": "Rick Astley",
  "platform": "YouTube",
  "formats": ["mp4", "mkv", "webm", "mp3"],
  "availableQualities": [...]
}
```

### Test 2: Flutter App (Local)

```bash
# Run app with local backend
flutter run

# In app: Paste/type a YouTube URL and press Enter
# You should see actual video info, not mock data
```

### Test 3: APK (Production)

1. Build release APK
   ```bash
   flutter build apk --release
   ```

2. Install on Android device
   ```bash
   adb install build/app/outputs/flutter-apk/app-release.apk
   ```

3. Test with actual URLs
   - App should fetch real video data from backend
   - Download button should work correctly

---

## 🔄 Git Workflow

### Create Pull Request

```bash
# Current branch: fix/clipboard-and-mock-data-issues
git push origin fix/clipboard-and-mock-data-issues
```

Then go to GitHub and create a PR from `fix/clipboard-and-mock-data-issues` → `main`

### Changes Included in PR

✅ Fixed video extraction (now uses backend API on mobile)
✅ Fixed download button (now works with manual paste + Enter)
✅ Added backend server with yt-dlp integration
✅ Added deployment documentation

---

## 📊 API Response Examples

### YouTube Video
```json
{
  "url": "https://www.youtube.com/watch?v=...",
  "title": "Amazing Tutorial",
  "platform": "YouTube",
  "availableQualities": [
    {"label": "360p", "resolution": "640x360", "fileSize": "25.50 MB"},
    {"label": "720p", "resolution": "1280x720", "fileSize": "85.75 MB"},
    {"label": "1080p", "resolution": "1920x1080", "fileSize": "150.25 MB"}
  ],
  "formats": ["mp4", "mkv", "webm", "mp3"]
}
```

### TikTok Video
```json
{
  "url": "https://www.tiktok.com/...",
  "title": "Viral TikTok",
  "platform": "TikTok",
  "availableQualities": [
    {"label": "540p", "resolution": "720x540", "fileSize": "15.50 MB"}
  ],
  "formats": ["mp4", "mkv"]
}
```

---

## 🐛 Troubleshooting

### Backend Not Starting
```bash
# Check if yt-dlp is installed
yt-dlp --version

# Check if port 3000 is free
lsof -i :3000
```

### App Shows "Failed to extract video"
1. Check backend is running: `curl http://localhost:3000/health`
2. Check backend URL in `video_extraction_service.dart`
3. Check network connectivity
4. Check URL is valid

### Mock Data Still Appearing
1. Rebuild APK: `flutter clean && flutter build apk --release`
2. Verify backend URL is correct
3. Check backend is accessible from mobile device

### Video Download Fails
1. Check download directory permissions
2. Check disk space
3. Check yt-dlp can handle the URL: `yt-dlp "url" --dump-json`

---

## 📦 File Structure

```
VideoDowloadingRepo/
├── lib/
│   ├── services/
│   │   └── video_extraction_service.dart  ✅ Updated
│   ├── screens/
│   │   └── home/
│   │       ├── home_screen.dart  ✅ Updated
│   │       └── widgets/
│   │           └── url_input_field.dart  ✅ Updated
│   └── ...
├── backend/                     ✨ New
│   ├── server.js
│   ├── package.json
│   ├── .env.example
│   └── README.md
└── ...
```

---

## 🎯 Next Steps

1. ✅ Deploy backend (Railway/Heroku/Docker)
2. ✅ Update backend URL in Flutter app
3. ✅ Rebuild and test APK
4. ✅ Create and merge pull request
5. ✅ Release new version with fixes

---

## 💡 Tips

- **Development**: Use `http://localhost:3000` for local testing
- **Production**: Use deployed URL for release builds
- **Speed**: Railway is fastest to set up (2 minutes)
- **Cost**: Railway & Heroku free tier sufficient for personal use
- **Monitoring**: Check Railway/Heroku logs if issues occur

---

## 📞 Support

If you encounter issues:
1. Check backend logs: `npm run dev`
2. Test API endpoint with curl
3. Verify yt-dlp is working: `yt-dlp "https://youtube.com/watch?v=..."`
4. Check network connectivity between app and backend
