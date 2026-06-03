# Railway Deployment Guide - Backend Only

## Important: Backend Server Only

⚠️ **Note:** We're deploying **only the backend API server** to Railway. The Flutter app stays on your phone/Android device. Railway is a server hosting platform, not a mobile app platform.

### What's Being Deployed:
- ✅ Backend Express.js API server (`backend/server.js`)
- ✅ yt-dlp integration for video extraction
- ❌ NOT the Flutter app (that's on your Android device)

---

## Quick Deploy to Railway (2 Minutes)

### Step 1: Create Railway Account
1. Go to https://railway.app
2. Click **Sign Up**
3. Sign in with GitHub (recommended)
4. Authorize Railway to access your GitHub account

### Step 2: Deploy Backend to Railway

**Important:** Select ONLY the `backend/` directory when deploying.

1. In Railway dashboard, click **New Project**
2. Select **Deploy from GitHub repo**
3. Search for and select `ahmadmushtaq1333/VideoDowloadingRepo`
4. Select the `fix/clipboard-and-mock-data-issues` branch
5. ⚠️ **Important:** In the "Root Directory" settings, set it to: `backend`
6. Click **Deploy**

Railway will automatically:
- Detect Node.js project (from `backend/package.json`)
- Install dependencies (`npm install`)
- Start server (`npm start`)
- Assign a public URL

### Step 3: Wait for Deployment
- Watch the build logs in real-time
- Deployment takes 1-2 minutes
- You'll see "✓ Deployment successful" when complete

### Step 4: Get Your Backend URL
1. In Railway dashboard, go to **Domains** (or **Deployments**)
2. Copy the generated URL (looks like: `https://video-downloader-backend-prod.railway.app`)

**Save this URL!** You need it for the next step.

### Step 5: Test Backend
Open this in your browser (replace with your actual URL):
```
https://your-railway-url/health
```

You should see:
```json
{"status":"ok","service":"video-extraction-api"}
```

✅ **If you see this, backend is running successfully!**

---

## Step 6: Update Flutter App

Now that backend is deployed, update your Flutter app to use it.

### Edit the File:
```
lib/services/video_extraction_service.dart
```

### Find this line (around line 11):
```dart
final String _backendUrl = 'https://your-backend-url.com/api/extract';
```

### Replace with your Railway URL:
```dart
final String _backendUrl = 'https://video-downloader-backend-prod.railway.app/api/extract';
```

**Example:** If Railway gave you `https://my-app-xyz123.railway.app`, use:
```dart
final String _backendUrl = 'https://my-app-xyz123.railway.app/api/extract';
```

### Commit & Push Changes:
```bash
git add lib/services/video_extraction_service.dart
git commit -m "Update backend URL to Railway deployment"
git push origin fix/clipboard-and-mock-data-issues
```

---

## Step 7: Rebuild Flutter APK

Now rebuild the Flutter app with the updated backend URL.

```bash
flutter clean
flutter build apk --release
```

This creates:
```
build/app/outputs/flutter-apk/app-release.apk
```

### Install on Android Device:
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

Or use Android Studio:
1. Open Device Manager
2. Drag and drop APK to device
3. Tap install when prompted

---

## Step 8: Test Everything

### Test 1: Backend is Running
```
Open in browser: https://your-railway-url/health
Expected: {"status":"ok","service":"video-extraction-api"}
```

### Test 2: Backend Extracts Video Info
```bash
curl -X POST https://your-railway-url/api/extract \
  -H "Content-Type: application/json" \
  -d '{"url":"https://www.youtube.com/watch?v=dQw4w9WgXcQ"}'
```

Expected response (real video data):
```json
{
  "title": "Rick Astley - Never Gonna Give You Up",
  "thumbnail": "https://...",
  "duration": 212,
  "platform": "YouTube",
  "availableQualities": [...]
}
```

### Test 3: Flutter App Works
1. Open the app on your Android phone
2. Paste a YouTube URL → Should show **real** video info (not mock data)
3. Press Enter → Should extract info automatically
4. Select quality and format
5. Click "Download" → Should start download

✅ **If all tests pass, you're done!**

---

## Environment Variables in Railway

Railway automatically sets:
- `PORT=3000` ✅
- `NODE_ENV=production` ✅

No additional setup needed!

---

## Troubleshooting

### "Deployment Failed" Error
1. Check build logs in Railway dashboard
2. Verify you selected `backend` as root directory
3. Check that `backend/package.json` exists and is valid

### "Invalid URL format" or CORS Errors
- Verify backend URL is correct (with https://)
- Check URL is accessible: Open in browser
- Make sure to include `/api/extract` in requests

### Backend Returns "yt-dlp not found"
- This might happen on Railway's free tier
- Solution: Use paid tier ($5/month) or try Heroku instead
- Or update to Railway's new stack with yt-dlp pre-installed

### App Still Shows Mock Data
1. Verify backend URL was updated correctly
2. Rebuild APK: `flutter clean && flutter build apk --release`
3. Uninstall old app: `adb uninstall com.your.package`
4. Install new APK: `adb install app-release.apk`

---

## File Structure - What Gets Deployed

```
VideoDowloadingRepo/
├── backend/                    ← DEPLOYED to Railway ✅
│   ├── server.js               ← Main API server
│   ├── package.json            ← Node.js dependencies
│   ├── .env                    ← Configuration
│   └── README.md
│
├── lib/                        ← Stays on your phone ✅
│   ├── services/
│   │   └── video_extraction_service.dart  ← Updated with Railway URL
│   └── ...
│
└── (Flutter project files)     ← Compiled to APK
```

---

## Cost

- **Railway Free Tier:** $5 credit/month
- **Backend Usage:** ~$0/month (for personal use)
- **No credit card required** for free trial
- After free credits: $5/month starting plan

---

## Next Steps Summary

1. ✅ Deploy backend to Railway (follow steps above)
2. ✅ Get public URL from Railway
3. ✅ Update Flutter app with URL
4. ✅ Rebuild APK
5. ✅ Install on Android device
6. ✅ Test with real videos
7. ✅ Create PR when working

---

## Quick Reference

| Step | Time | Action |
|------|------|--------|
| 1 | 2 min | Deploy backend to Railway |
| 2 | 1 min | Get backend URL |
| 3 | 1 min | Update Flutter app URL |
| 4 | 2 min | Rebuild APK |
| 5 | 1 min | Install on phone |
| 6 | 2 min | Test everything |
| **Total** | **~9 min** | **Complete setup** |

---

**Everything is ready to go!** 🚀

Start with Step 1: Deploy to Railway (https://railway.app)
