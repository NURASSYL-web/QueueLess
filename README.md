# QueueLess

QueueLess is a production-structured Flutter app for real-time queue tracking across Taraz. It is built as a two-sided platform: regular users can discover and report queues, while business users can manage their own place and attract nearby customers. The app uses Firebase Authentication, Cloud Firestore, Firebase Messaging, Firebase Storage, geolocation, and Google Maps Flutter.

## What is implemented

- Email/password authentication with persistent sessions and role selection
- Map-first and list-first queue browsing with category, queue, distance, and freshness filters
- Queue aggregation from recent Firestore reports only
- Google Map with color-coded markers and place detail sheet
- One-tap queue reporting sheet with optional image upload
- User-owned queue report CRUD: create, read, update, delete
- Business place creation and owner-only management
- GPS-based nearby filtering and distance-aware queue cards
- Profile screen with role-aware actions, logout, feedback capture, and recent validation feed
- FCM client token sync plus a deployable Cloud Function for short-queue alerts
- Firebase-ready architecture with repositories, feature modules, and presentation controllers
- Seed dataset for Taraz places in `assets/seed/taraz_places.json`
- Cloud Function source for push notifications in `functions/index.js`

## Project structure

```text
lib/
  main.dart
  src/
    core/
    features/
      app/
      auth/
      home/
      map/
      profile/
      queue/
    shared/
```

## Firebase setup

QueueLess is wired for real Firebase credentials and intentionally does not include fake keys.

1. Create a Firebase project.
2. Enable:
   - Authentication with Email/Password
   - Cloud Firestore
   - Cloud Messaging
   - Firebase Storage
3. Add Android and iOS apps in Firebase.
4. Run the app with real values:

```bash
flutter run \
  --dart-define=FIREBASE_PROJECT_ID=your-project-id \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=your-sender-id \
  --dart-define=FIREBASE_STORAGE_BUCKET=your-project.appspot.com \
  --dart-define=FIREBASE_ANDROID_API_KEY=your-android-api-key \
  --dart-define=FIREBASE_ANDROID_APP_ID=your-android-app-id \
  --dart-define=FIREBASE_IOS_API_KEY=your-ios-api-key \
  --dart-define=FIREBASE_IOS_APP_ID=your-ios-app-id \
  --dart-define=FIREBASE_IOS_BUNDLE_ID=com.queueless.app \
  --dart-define=GOOGLE_MAPS_API_KEY=your-google-maps-api-key
```

## Native Google Maps setup

Android:

- The manifest already reads `${GOOGLE_MAPS_API_KEY}`.
- Provide it through a Gradle property:

```properties
GOOGLE_MAPS_API_KEY=your-google-maps-api-key
```

iOS:

- `Info.plist` already reads `$(GOOGLE_MAPS_API_KEY)`.
- Add `GOOGLE_MAPS_API_KEY=your-google-maps-api-key` in your Xcode build settings or `.xcconfig`.

## Firestore collections

### `users`

```json
{
  "email": "student@example.com",
  "role": "user",
  "pushToken": "optional-fcm-token"
}
```

### `places`

```json
{
  "ownerId": "firebase-auth-uid-of-business",
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
  "placeId": "place-document-id",
  "userId": "firebase-auth-uid",
  "placeName": "Keruen Coffee",
  "queueLevel": "medium",
  "timestamp": "server timestamp",
  "imageUrl": "optional-storage-download-url",
  "storagePath": "optional-storage-path"
}
```

### `feedback_entries`

```json
{
  "userId": "firebase-auth-uid",
  "email": "tester@example.com",
  "rating": 5,
  "comment": "The update flow felt clear and fast.",
  "createdAt": "server timestamp"
}
```

## Seed data

Use `assets/seed/taraz_places.json` to manually create `places` documents in Firestore. The sample documents now include business ownership and contact fields so the business flow can be tested end-to-end.

## Suggested Firestore rules

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

## Suggested Storage rules

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

## Business flow notes

- Sign up as a `business` user to unlock place management in the profile screen.
- Business users can create a place, pin it on the map, and later edit only their own place.
- Any authenticated user can still contribute queue reports, which is useful for business owners and visitors alike.
- Nearby short-queue alerts depend on FCM topic subscriptions and the included Cloud Function.

## Push notification deployment

Deploy the included Cloud Function after installing Firebase CLI:

```bash
cd functions
npm install
firebase deploy --only functions
```

## Notes

- Queue calculations use reports from the last 15 minutes.
- The app refreshes queue aggregation continuously so old reports age out automatically.
- Push alerts require deploying the provided Cloud Function and testing on a real device.
- Google Maps on web requires a valid Maps JavaScript API key configured in Google Cloud with working billing and browser permissions.
- Validation with at least 3 testers cannot be fabricated in code. Use the in-app feedback form so real testers can leave evidence in `feedback_entries`.
