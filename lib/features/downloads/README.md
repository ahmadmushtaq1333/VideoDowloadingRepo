# Downloads feature

This feature contains the download-related services, providers and UI.

Structure
- data/  - download_service.dart, video_extraction_service.dart
- providers/ - download_provider.dart
- presentation/ - downloads_screen.dart, widgets/

Migration notes
- These files are *copies* (for now) that point at the existing models in lib/models/
- In a follow-up PR we will move the shared models into feature/domain and update imports
