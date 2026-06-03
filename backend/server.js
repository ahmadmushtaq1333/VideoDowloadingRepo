const express = require('express');
const { exec } = require('child_process');
const cors = require('cors');
const bodyParser = require('body-parser');
const { promisify } = require('util');

const app = express();
const execAsync = promisify(exec);

// Middleware
app.use(cors());
app.use(bodyParser.json());

// Video extraction endpoint
app.post('/api/extract', async (req, res) => {
  try {
    const { url } = req.body;

    if (!url) {
      return res.status(400).json({ error: 'URL is required' });
    }

    // Validate URL format
    try {
      new URL(url);
    } catch {
      return res.status(400).json({ error: 'Invalid URL format' });
    }

    // Run yt-dlp command to extract video info
    const { stdout } = await execAsync(`yt-dlp --dump-json --no-playlist "${url}"`, {
      timeout: 30000,
      maxBuffer: 10 * 1024 * 1024, // 10MB buffer for large responses
    });

    const videoData = JSON.parse(stdout);

    // Extract relevant information
    const formats = videoData.formats || [];
    const qualities = [];
    const seen = new Set();

    // Parse available qualities
    for (const format of formats) {
      if (format.height) {
        const label = `${format.height}p`;
        if (!seen.has(label)) {
          seen.add(label);
          qualities.push({
            label,
            resolution: `${format.width || '?'}x${format.height}`,
            fileSize: format.filesize ? `${(format.filesize / 1024 / 1024).toFixed(2)} MB` : null,
          });
        }
      }
    }

    // Sort qualities by height
    qualities.sort((a, b) => {
      const aHeight = parseInt(a.label);
      const bHeight = parseInt(b.label);
      return aHeight - bHeight;
    });

    // Detect platform
    let platform = 'Unknown';
    const hostname = new URL(url).hostname.toLowerCase();
    if (hostname.includes('youtube')) platform = 'YouTube';
    else if (hostname.includes('tiktok')) platform = 'TikTok';
    else if (hostname.includes('instagram')) platform = 'Instagram';
    else if (hostname.includes('twitter') || hostname.includes('x.com')) platform = 'Twitter';
    else if (hostname.includes('facebook')) platform = 'Facebook';

    // Extract available formats
    const formats_list = ['mp4', 'mkv', 'webm'];
    if (videoData.ext === 'mp3' || hostname.includes('youtube') || hostname.includes('soundcloud')) {
      formats_list.push('mp3');
    }

    const response = {
      url,
      title: videoData.title || 'Unknown',
      thumbnail: videoData.thumbnail || null,
      duration: videoData.duration ? Math.round(videoData.duration) : null,
      uploader: videoData.uploader || videoData.uploader_id || null,
      platform,
      formats: formats_list,
      availableQualities: qualities.length > 0 ? qualities : [
        {
          label: 'best',
          resolution: 'best available',
          fileSize: null,
        },
      ],
    };

    res.json(response);
  } catch (error) {
    console.error('Extraction error:', error.message);

    // Check if it's a timeout or yt-dlp not found
    if (error.message.includes('timeout')) {
      return res.status(504).json({
        error: 'Request timeout - video extraction took too long',
      });
    }

    if (error.message.includes('ENOENT')) {
      return res.status(500).json({
        error: 'yt-dlp is not installed on the server',
      });
    }

    res.status(400).json({
      error: error.message || 'Failed to extract video information',
    });
  }
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'video-extraction-api' });
});

// Start server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Video Extraction API running on port ${PORT}`);
  console.log(`Backend URL: http://localhost:${PORT}`);
  console.log(`API endpoint: POST http://localhost:${PORT}/api/extract`);
});
