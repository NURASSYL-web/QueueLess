# QueueLess

QueueLess is a startup-style Flutter mobile app for real-time queue discovery in Taraz.

It is built as a two-sided platform:

- Regular users can view live queues, report queue status, save alerts, and discover nearby places.
- Business users can register their venue, manage queue visibility, and use a dedicated business dashboard.

The project is built with Flutter + Firebase and is structured for demo presentation, team collaboration, and real user testing.

## Highlights

- Real Firebase Authentication with role-based signup
- Cloud Firestore as the main live database
- Queue reporting and recent aggregation logic
- Google Maps-based discovery flow
- Business dashboard and owner place management
- Firebase Storage support for queue update images
- FCM-ready short-queue notification flow
- Clean feature-based architecture
- Branded UI, splash screen, and app icons

## Product Model

QueueLess follows a simple B2C + B2B startup model.

### Regular users

- Explore nearby places
- See live queue conditions
- Receive short-queue alerts
- Upgrade later to premium plans

### Business users

- Register a business account
- Add and manage their place
- Update queue status faster
- Improve local visibility and attract nearby visitors

### Business pricing concept

- `Business Demo` — `490 ₸`
- `Business Start` — `2490 ₸ / month`
- `Business Growth` — `3990 ₸ / month`
- `Business Pro` — `4990 ₸ / month`

### Future monetization

- Premium consumer plans
- Local business promotion
- AI-based queue analytics and recommendations

## Tech Stack

- Flutter
- Firebase Authentication
- Cloud Firestore
- Firebase Storage
- Firebase Cloud Messaging
- Google Maps Flutter
- Provider-based state management
- Feature-first layered architecture

## Key Features

### User flow

- Email/password sign up and sign in
- Separate business registration flow
- Map-first discovery
- List view with filters
- Queue status updates: `Short / Medium / Long`
- Distance-aware filtering
- Nearby queue insights
- Alert subscriptions for short queues

### Business flow

- Business demo onboarding
- Create and edit owned place
- Business dashboard with KPI-style cards
- Queue status quick update
- Contact and venue visibility management
- Place-specific activity view

### Queue logic

- `short = 3 min`
- `medium = 10 min`
- `long = 20 min`
- only recent reports are used
- old reports automatically age out of the dashboard

## Screens

- Auth
- Business signup
- Map
- List
- Profile
- My reports
- Manage place
- Business dashboard
- Queue update sheet

## Project Structure

```text
lib/
  main.dart
  src/
    core/
      constants/
      location/
      services/
      theme/
      utils/
      widgets/
    features/
      app/
      auth/
      business/
      feedback/
      home/
      map/
      profile/
      queue/
    shared/
      models/
      repositories/
```

## Quick Start

### 1. Clone the repository

```bash
git clone https://github.com/NURASSYL-web/QueueLess.git
cd QueueLess
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Run the project

```bash
flutter run
```

## Team Setup

This repository is currently prepared with working demo Firebase values in code, which makes it easier to run for presentation and team onboarding.

If your team later wants to migrate QueueLess to a different Firebase or Google Maps project, use the template in [.env.example](/Users/nurasyltemirhan/Desktop/QuueLess/queue/.env.example) as a setup checklist.

### Recommended onboarding steps for teammates

1. Install Flutter and platform toolchains.
2. Run `flutter pub get`.
3. Confirm Firebase project access.
4. Confirm Google Maps API access.
5. Populate Firestore with the seed places file.
6. Apply Firestore and Storage rules.
7. Run on a real phone for notification testing.

## Environment Template

The repository includes a `.env.example` file for team reference.

Important:

- QueueLess does **not** auto-load `.env` files at runtime right now.
- The file is provided as a clean shared checklist for credentials and platform setup.
- If you move the app to another Firebase project, update:
  - `lib/src/core/services/app_firebase_options.dart`
  - Android Google Maps key in `AndroidManifest.xml`
  - iOS Google Maps key in `Info.plist`
  - web map key in `web/index.html`

## Firestore Collections

### `users`

```json
{
  "email": "user@example.com",
  "role": "user",
  "pushToken": "optional-token",
  "planId": "free_explorer",
  "planName": "Free Explorer",
  "planPriceTenge": 0,
  "planStatus": "active"
}
```

### `places`

```json
{
  "ownerId": "business-user-id",
  "name": "Keruen Coffee",
  "category": "coffee",
  "latitude": 42.8982,
  "longitude": 71.3942,
  "phone": "+7 700 202 0001",
  "instagram": "@keruen_coffee",
  "createdAt": "server timestamp"
}
```

### `queue_reports`

```json
{
  "placeId": "place-id",
  "userId": "firebase-auth-uid",
  "placeName": "Keruen Coffee",
  "queueLevel": "medium",
  "timestamp": "server timestamp",
  "imageUrl": "optional-image-url",
  "storagePath": "optional-storage-path"
}
```

### `feedback_entries`

```json
{
  "userId": "firebase-auth-uid",
  "email": "tester@example.com",
  "rating": 5,
  "comment": "Nice UX and fast update flow.",
  "createdAt": "server timestamp"
}
```

## Seed Data

The starter dataset for Taraz is in:

- [`assets/seed/taraz_places.json`](/Users/nurasyltemirhan/Desktop/QuueLess/queue/assets/seed/taraz_places.json)

Use it to populate Firestore so the list and map screens are not empty on first launch.

## Firebase Rules

### Firestore rules

```text
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    match /places/{placeId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null
        && request.resource.data.ownerId == request.auth.uid;
      allow update, delete: if request.auth != null
        && resource.data.ownerId == request.auth.uid;
    }

    match /queue_reports/{reportId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null
        && request.resource.data.userId == request.auth.uid;
      allow update, delete: if request.auth != null
        && resource.data.userId == request.auth.uid;
    }

    match /feedback_entries/{feedbackId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null
        && request.resource.data.userId == request.auth.uid;
    }
  }
}
```

### Storage rules

```text
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /queue_reports/{reportId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

## Notifications

QueueLess includes an FCM-ready flow for short-queue notifications.

Cloud Function source:

- [`functions/index.js`](/Users/nurasyltemirhan/Desktop/QuueLess/queue/functions/index.js)

Deploy with:

```bash
cd functions
npm install
firebase deploy --only functions
```

## Branding

Custom project branding already included:

- app logo
- branded splash assets
- Android launcher icons
- iOS app icons

## Validation Notes

This project is code-complete for demo and testing, but a few items still depend on real-world setup:

- Google Maps web permissions and billing
- Firebase project access
- deployed FCM function
- real device notification testing
- actual tester feedback and traction

## Commands

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## Repository

GitHub:

- `https://github.com/NURASSYL-web/QueueLess`

## License

This repository is currently intended for academic demo, startup validation, and internal team use.
