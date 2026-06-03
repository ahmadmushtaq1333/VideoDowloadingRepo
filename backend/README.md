# Video Extraction Backend API

This is the backend server for the Video Downloader app. It provides an API endpoint for extracting video metadata using yt-dlp.

## Prerequisites

- Node.js (v14 or higher)
- npm or yarn
- yt-dlp installed on the server
  ```bash
  # macOS
  brew install yt-dlp
  
  # Linux (Ubuntu/Debian)
  sudo apt-get install yt-dlp
  
  # Or install via pip
  pip install yt-dlp
  ```

## Installation

1. Navigate to the backend directory:
   ```bash
   cd backend
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Create `.env` file from `.env.example`:
   ```bash
   cp .env.example .env
   ```

4. Update `.env` with your configuration:
   ```
   PORT=3000
   NODE_ENV=development
   ```

## Running the Server

### Development
```bash
npm run dev
```

The server will start on `http://localhost:3000` and automatically restart on file changes.

### Production
```bash
npm start
```

## API Endpoints

### Health Check
- **GET** `/health`
- **Response**: `{ status: "ok", service: "video-extraction-api" }`

### Extract Video Information
- **POST** `/api/extract`
- **Request Body**:
  ```json
  {
    "url": "https://www.youtube.com/watch?v=..."
  }
  ```

- **Response (Success)**:
  ```json
  {
    "url": "https://www.youtube.com/watch?v=...",
    "title": "Video Title",
    "thumbnail": "https://...",
    "duration": 245,
    "uploader": "Channel Name",
    "platform": "YouTube",
    "formats": ["mp4", "mkv", "webm", "mp3"],
    "availableQualities": [
      {
        "label": "360p",
        "resolution": "640x360",
        "fileSize": "25.50 MB"
      },
      {
        "label": "720p",
        "resolution": "1280x720",
        "fileSize": "85.75 MB"
      }
    ]
  }
  ```

- **Response (Error)**:
  ```json
  {
    "error": "Error message describing what went wrong"
  }
  ```

## Environment Variables

- `PORT` - Server port (default: 3000)
- `NODE_ENV` - Environment mode (development/production)

## Deployment Options

### Heroku
```bash
heroku create your-app-name
heroku buildpacks:add heroku/nodejs
heroku config:set BUILDPACK_URL=https://github.com/yt-dlp/yt-dlp.git
git push heroku main
```

### Railway
1. Push code to GitHub
2. Connect repository to Railway
3. Set `PORT` to `3000`
4. Deploy

### Docker
Create a `Dockerfile`:
```dockerfile
FROM node:18-alpine

# Install yt-dlp
RUN apk add --no-cache python3 py3-pip
RUN pip install yt-dlp

WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .

EXPOSE 3000
CMD ["npm", "start"]
```

Build and run:
```bash
docker build -t video-extractor-api .
docker run -p 3000:3000 video-extractor-api
```

## Updating the Flutter App

Update the backend URL in `lib/services/video_extraction_service.dart`:

```dart
final String _backendUrl = 'https://your-deployed-backend.com/api/extract';
```

## Troubleshooting

### yt-dlp not found
Make sure yt-dlp is installed and accessible from the command line:
```bash
yt-dlp --version
```

### CORS errors
The API already includes CORS headers. If you still get errors, check:
1. Backend URL is correct
2. Backend server is running
3. Network connectivity between app and backend

### Timeout errors
If videos take longer than 30 seconds to extract, increase the timeout in `server.js`:
```javascript
timeout: 60000, // 60 seconds
```

## License

MIT
