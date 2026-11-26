# ShareTrip Student and Driver

Flutter application containing separate Student and Driver portals.

## Portals

- **Student Portal:** Existing welcome, registration, login, ride search, ride map, and My Rides features are retained.
- **Driver Portal:** Open it from the welcome screen using **Driver Portal**. The separate driver sign-in leads to a driver workspace with:
  - Online/offline availability
  - Driver dashboard and pending ride requests
  - Accept/decline request controls
  - Post a ride form and seat availability
  - Active, upcoming, and completed trip views
  - Trip details, passenger check-in, and trip progress
  - Fare contribution summary
  - Driver profile, vehicles, document checklist, and passenger reviews
  - Driving schedule and notification preferences
  - Safety center, SOS information, and problem reporting

## Run

From this directory:

```bash
flutter pub get
flutter run
```

For a web build:

```bash
flutter build web
```

## Driver safety and device features

The driver portal now includes the following device-level implementations:

- **Notifications:** app-generated driver events (such as accepting/declining a request, posting a ride, and changing trip progress) are shown in the in-app notification list and sent as local OS notifications when permission is granted.
- **Live GPS:** trip status and the safety center can request location permission and display live latitude/longitude, accuracy, speed, and update time using the device GPS. Tracking is foreground-only and stops when the tracking screen is closed or tracking is stopped.
- **Emergency SOS:** the driver can save an emergency phone number. SOS obtains the current GPS position and opens the device SMS composer with a Google Maps location link. The driver must review and send the message. A separate Call 911 action opens the phone dialer.

### Required platform setup

This source archive does not include Android or iOS platform runner folders. When generating them with `flutter create .`, apply the platform permission setup below.

**Android** — in `android/app/src/main/AndroidManifest.xml`, add inside the root `<manifest>` element:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.CALL_PHONE" />
```

The app opens the dialer rather than placing calls directly, so `CALL_PHONE` is not required and may be omitted. No background-location permission is requested because tracking is foreground-only.

**iOS** — in `ios/Runner/Info.plist`, add:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>ShareTrip uses your location during an active trip to show your live position and include it in an SOS message.</string>
```

Then run:

```bash
flutter pub get
flutter analyze
flutter run
```

### Important production boundaries

These features use the driver's device; they do **not** constitute a complete server-connected safety system:

- Local notifications are not remote push notifications. Alerts from a server while the app is closed require a backend, push provider (such as FCM/APNs), device-token registration, and server event integration.
- GPS is currently displayed on the driver's device. It is not uploaded or shared live with students, dispatchers, or other accounts. That requires authenticated backend endpoints, access control, and a trip-sharing policy.
- SOS opens the SMS composer; it does not silently send a message, notify ShareTrip staff, or dispatch emergency responders. The driver must press Send. A real dispatch workflow requires a staffed endpoint/backend and operational escalation procedures.
- Driver login and sample ride/request data remain prototype data; these device features do not make authentication or ride state server-backed.
