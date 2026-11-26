# ShareTrip driver additions

## Registration
- The Welcome screen's Register button now asks whether the account is a Student or Driver.
- Student registration continues to use the existing student registration flow.
- Driver registration collects contact details and vehicle information.
- The only supported vehicle categories are Shuttle, Motorcycle, and Tricycle.
- Driver profile data is saved locally with `shared_preferences` for this prototype.

## Driver GPS
Student map tracking and driver trip tracking now use the same `LocationService` (`geolocator`).
On Chrome/Edge:
1. Run `flutter run -d chrome` (localhost is a secure context for browser geolocation).
2. Open the driver portal and start a trip.
3. Press **Start live GPS** and allow location access in the browser prompt.
4. If permission was previously blocked, open the browser site settings for `localhost`, set Location to Allow, reload, and try again.
5. Enable device location services. A desktop without a GPS sensor may use browser/OS location estimation and may be less accurate.

The driver screen shows latitude, longitude, accuracy, speed, update time, and a Google Maps link. Tracking stops when the screen is disposed or Stop is pressed.

## Student-to-driver messaging
- Student ride cards have a **Message Driver** action.
- The driver portal has a chat icon and a **Message student** action on request cards.
- Messages are stored locally using SharedPreferences. They can be exchanged when both portals are running in the same browser profile/device.

## Important integration boundary
This source project does not include a configured backend, API base URL, Firebase/Supabase project, user authentication provider, or push service. Therefore driver registration and chat are local prototype persistence, not cross-device accounts or real-time remote messaging. To make students and drivers on different devices exchange messages, and to publish driver's live GPS to the student's ride map, connect a shared backend (for example, an existing REST/WebSocket service or Firebase) and authenticate each user. No server credentials or API endpoints were present in the uploaded project, so none have been invented.

## Driver live road navigation

The driver's **Active Trip** screen now uses the same Flutter Map + OpenStreetMap + Geolocator stack as the student live-navigation screen. It displays map tiles, the live driver marker, pickup and destination pins, an OSRM road-route polyline, route distance, estimated driving time, GPS accuracy and speed, map recentering, and the existing trip progress/check-in/report/SOS controls.

Before starting GPS, verify or edit the pickup and destination address fields for the actual trip, then select **Update route on map**. The default Bitin Junction → CMDI Main Campus addresses are example trip values and should be changed to the passenger's actual pickup and destination. The driver marker updates from device GPS; the road route is refreshed after movement or a time interval. Chrome/Edge location access requires localhost or HTTPS and browser location permission. Map tiles use OpenStreetMap; route geometry uses the public OSRM demo service, so both require internet access and are subject to service availability/rate limits.
