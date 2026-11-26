# ShareTrip backend setup (Supabase + Firebase Cloud Messaging)

This project uses **Supabase as the primary backend** and **Firebase Cloud Messaging (FCM) only for push delivery**. The existing local prototype UI has not been silently replaced; `BackendService` is the cloud data layer to wire into the registration, profile, rides, chat, GPS and SOS screens.

## 1. Supabase

1. Create a project at https://supabase.com/dashboard.
2. Open SQL Editor and run `supabase/schema.sql`.
3. In Project Settings > API, copy the Project URL and publishable/anon key. Never use the service-role key in Flutter.
4. Run the app with:

```powershell
flutter pub get
flutter run -d chrome --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLISHABLE_OR_ANON_KEY
```

For Android, use the same `--dart-define` values with `flutter run`. The app initializes Supabase only when both values are supplied.

## 2. Storage

The SQL creates a `profile-photos` bucket and owner-folder policies. `BackendService.uploadProfilePhoto(XFile)` uploads an image to `<auth-user-id>/...` and saves its public URL to the signed-in user's profile. The bucket is public-read for avatar display; do not use it for private identity documents. Create a separate private bucket and stricter policies for sensitive documents.

## 3. Firebase Cloud Messaging

1. Create a Firebase project at https://console.firebase.google.com/.
2. Install FlutterFire CLI and run `flutterfire configure` from this project root, selecting Android and Web (and iOS if needed). This generates `lib/firebase_options.dart` and platform config files.
3. Initialize Firebase using `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` before using `FirebaseMessaging`.
4. Configure Web Push certificates/VAPID in Firebase Console and provide the web VAPID key to `FirebaseMessaging.getToken(vapidKey: ...)` for Chrome/Edge.
5. Configure Android notification channel/permissions and iOS APNs credentials in Firebase.
6. Register FCM tokens in `device_tokens` using `BackendService.savePushToken(token, platform: 'web'|'android'|'ios')`.
7. Send push messages from a trusted server/Edge Function using Firebase Admin SDK. Never put Firebase service-account credentials in the Flutter app. Do not send FCM directly from the client.

## 4. Available cloud operations

`lib/core/services/backend_service.dart` provides methods for Supabase signup/login, profile read/update, profile image upload, ride search/create, ride requests, realtime chat stream/send, driver-location upsert/watch, emergency-alert creation, and device-token registration. Vehicle values are constrained to Shuttle, Motorcycle, and Tricycle.

## 5. Important integration and security notes

- **Credentials are not included**: this archive is not connected to your projects until you provide your Supabase URL/key and run FlutterFire configuration.
- Existing screen flows still need to call these cloud methods in place of local-only `SharedPreferences` methods. This package adds the backend layer and schema, not a claim that every screen is already switched over.
- Realtime database changes require enabling Realtime for `messages` and `driver_locations` in Supabase Dashboard.
- The included RLS policies are a starting point. Review them with your project rules before production. In particular, the emergency-alert table currently lets users create and read their own alerts; dispatch/administrator access must be added securely.
- Location writes should run only during an active, consented trip and be stopped at trip end. Students can read a driver's location only when they have an accepted request for that ride.
- FCM delivery requires a trusted server-side function triggered by database events. The Flutter client must never hold server secrets.

## 6. Run

```powershell
flutter clean
flutter pub get
flutter analyze
flutter run -d chrome --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLISHABLE_OR_ANON_KEY
```
