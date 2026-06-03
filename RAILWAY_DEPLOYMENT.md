# Railway Deployment Guide

## Quick Deploy to Railway (2 Minutes)

### Step 1: Create Railway Account
1. Go to https://railway.app
2. Click **Sign Up**
3. Sign in with GitHub (recommended)
4. Authorize Railway to access your GitHub account

### Step 2: Deploy Backend to Railway
1. In Railway dashboard, click **New Project**
2. Select **Deploy from GitHub repo**
3. Search for and select `ahmadmushtaq1333/VideoDowloadingRepo`
4. Select the `fix/clipboard-and-mock-data-issues` branch
5. Click **Deploy**

Railway will automatically:
- Detect Node.js project
- Install dependencies (`npm install`)
- Start server (`npm start`)
- Assign a public URL

### Step 3: Wait for Deployment
- Watch the build logs in real-time
- Deployment takes 1-2 minutes
- You'll see "✓ Deployment successful" when complete

### Step 4: Get Your Backend URL
1. In Railway dashboard, go to **Domains**
2. Copy the generated URL (looks like: `https://video-downloader-backend-prod.railway.app`)

### Step 5: Update Flutter App
Update `lib/services/video_extraction_service.dart`:

```dart
final String _backendUrl = 'https://your-railway-url/api/extract';
```

Replace `your-railway-url` with the URL from Step 4.

Example:
```dart
final String _backendUrl = 'https://video-downloader-backend-prod.railway.app/api/extract';
```

### Step 6: Test Backend
Open this in your browser to verify it's running:
```
https://your-railway-url/health
```

You should see:
```json
{"status":"ok","service":"video-extraction-api"}
```

### Step 7: Rebuild & Deploy APK
```bash
flutter clean
flutter build apk --release
```

Then install on Android device.

---

## Environment Variables in Railway

If you need to set environment variables:

1. In Railway dashboard, go to **Variables**
2. Add variables:
   - `PORT`: 3000
   - `NODE_ENV`: production

These are already in `backend/.env` but Railway settings take priority.

---

## Troubleshooting

### "Deployment Failed"
- Check build logs for errors
- Verify `package.json` has correct scripts
- Make sure `server.js` listens on `process.env.PORT`

### "Cannot extract video info"
- Test API: `https://your-url/health`
- Check Railway logs for yt-dlp errors
- Verify URL is accessible from public internet

### "CORS errors on Flutter app"
- Backend has CORS enabled ✅
- Check backend URL is correct in app
- Make sure you're using the full URL with https://

---

## Automatic Deployments

After initial setup, Railway automatically deploys when you push to GitHub:

```bash
git push origin fix/clipboard-and-mock-data-issues
```

Your backend updates in 1-2 minutes without manual intervention!

---

## Cost

- **Free tier**: 500 hours/month (plenty for personal use)
- **Paid**: $5/month starting plan
- **No credit card** for free tier (but limited to 500 hours)

---

## Next Steps

1. ✅ Deploy to Railway (follow steps above)
2. ✅ Get public URL
3. ✅ Update Flutter app with URL
4. ✅ Rebuild APK
5. ✅ Test real video downloads
