# Student-to-driver live pickup navigation

This adds the missing two-way pickup flow:

1. A student opens the active ride map. When the ride ID is a real Supabase UUID, the student's GPS position is upserted to `student_locations` as GPS updates arrive.
2. The assigned driver opens Active Trip > Navigate to waiting student, enters the student's Supabase auth user UUID and the ride UUID, and sees the student's live marker.
3. The driver app gets its own GPS position, requests an OSRM road route from driver to student, and draws the purple route. The route refreshes as either endpoint moves.
4. Supabase RLS restricts student-location writes to that student and reads to the assigned ride driver (or the student).

## Required setup
- Run the updated `supabase/schema.sql` in Supabase SQL Editor (it adds `student_locations` and RLS).
- Both student and driver must sign into the same Supabase project.
- The ride must exist in `rides`, and the student must have a pending or accepted `ride_requests` row for it.
- Use the actual UUID values from Supabase, not demo IDs like `RIDE-001`.
- Student must keep the ride map open and grant location permission while waiting. Browser GPS requires localhost or HTTPS.
- The driver must use the student's auth user UUID and the matching ride UUID.

This is not background location tracking: mobile OS background permissions/services are not configured here. The student must keep the app active on the ride map for continuous foreground sharing. The public OSRM demo routing service and OpenStreetMap tiles are used; production deployments should use a routing provider with an appropriate service agreement.
