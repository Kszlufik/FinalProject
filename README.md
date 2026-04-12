# PlayPal

> A social platform for game tracking, discovery and sharing — built with Flutter Web and Firebase.

[![Live App](https://img.shields.io/badge/Live-playpal--app--123.web.app-00E5FF?style=flat-square)](https://playpal-app-123.web.app)
[![GitHub](https://img.shields.io/badge/GitHub-Kszlufik%2FFinalProject-30363D?style=flat-square&logo=github)](https://github.com/Kszlufik/FinalProject)

---

## About

PlayPal lets you discover games, track what you are playing, connect your Steam library, and see what your friends are up to — all in one place. Built as a final year project at South East Technological University using Flutter Web and Firebase.

Everything on the live site is real data. No mocks, no placeholder content.

---

## Features

- Game discovery via RAWG API (500,000+ titles)
- Reviews, star ratings and play status tracking (Playing / Completed / Dropped)
- Steam library and achievement import
- Friends system with profiles, requests and notifications
- Real-time activity feed from friends
- Per-game discussion forums with live updates and a top comment badge
- Favourites, recently viewed strip, avatar colour picker
- Fully responsive — tested on iPhone SE

---

## Stack

| Technology | Role |
|---|---|
| Flutter Web | Frontend framework |
| Firebase Auth | Authentication |
| Cloud Firestore | Database |
| Cloud Functions | Node.js backend / Steam proxy |
| RAWG API | Game data (500k+ titles, CORS supported) |
| Steam Web API | Library and achievements (proxied via Cloud Functions) |
| Firebase Hosting | Deployment |

---

## Getting Started

**Prerequisites:** [Flutter SDK](https://flutter.dev/docs/get-started/install) 3.x+, [Firebase CLI](https://firebase.google.com/docs/cli), Node.js 18+

### 1. Clone the repo

```bash
git clone https://github.com/Kszlufik/FinalProject.git
cd FinalProject
```

### 2. Install Flutter dependencies

```bash
flutter pub get
```

### 3. Connect Firebase

Create a project at [console.firebase.google.com](https://console.firebase.google.com) then run:

```bash
flutterfire configure
```

### 4. Add your RAWG API key

Get a free key at [rawg.io/apidocs](https://rawg.io/apidocs) and replace the key constant in `lib/services/rawg_service.dart`.

### 5. Deploy Cloud Functions with your Steam API key

Steam's API has no CORS headers so all Steam calls go through Firebase Cloud Functions. The API key is stored as a Firebase Secret and never appears in source code.

```bash
cd functions
npm install
firebase functions:secrets:set STEAM_API_KEY
firebase deploy --only functions
```

### 6. Create Firestore composite indexes

Go to **Firebase Console → Firestore → Indexes** and create these two indexes manually. Without them the activity feed and forums return empty results silently with no error.

```
Index 1 — activity feed
  Collection: activity
  Fields: uid (Ascending), timestamp (Descending)

Index 2 — forum top comment
  Collection: forums/{gameId}/posts
  Fields: likeCount (Descending), timestamp (Descending)
```

### 7. Run locally

```bash
flutter run -d chrome --web-renderer html
```

> **Note:** The `--web-renderer html` flag is required. CanvasKit causes a black screen on Safari mobile.

---

## Deployment

```bash
flutter build web --web-renderer html
firebase deploy --only hosting
```

Cloud Functions deploy separately:

```bash
firebase deploy --only functions
```

> **Remember:** Firestore composite indexes must be created before deploying. They are not created automatically and the app will appear broken without them.

---

## Known Issues

- Activity feed queries run sequentially for users with 10+ friends — `Future.wait` parallelism is a planned improvement
- Steam achievements require the user's Steam profile and game library to be set to **Public**
- Safari on older iOS versions may have occasional rendering issues

---

## Links

- [Live Application](https://playpal-app-123.web.app)
- [Landing Page](https://kszlufik.github.io)
- [Final Report (PDF)](https://kszlufik.github.io/PlayPal_Final_Report.pdf)
- [AI Usage Log (PDF)](https://kszlufik.github.io/Appendix_G_AI_Usage_Log.pdf)

---

## Author

**Kamil Szlufik** — 15377821  
HDip in Science in Computer Science  
South East Technological University  
Supervisor: Mujanid  
Academic Year 2025/2026
