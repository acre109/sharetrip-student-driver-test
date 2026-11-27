# Find Ride analyzer warning fixes

Updated `lib/features/student/find_ride/find_ride_page.dart`:

- Migrated the Material import from `package:flutter/material.dart` to `package:material_ui/material_ui.dart`.
- Added `material_ui: ^1.0.0` to `pubspec.yaml`.
- Replaced deprecated `RadioListTile.groupValue` and `RadioListTile.onChanged` usage with a parent `RadioGroup<String>`.

The radio sort sheet keeps the same options and behavior: selecting an option closes the sheet and returns the selected sort value.

After extracting, run:

```powershell
flutter pub get
flutter analyze
```

This addresses the three diagnostics supplied for this file. I could not run Flutter/Dart analysis in this environment, so the resulting project still needs a local compile/analyze check.
