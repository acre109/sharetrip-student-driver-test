import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/backend_config.dart';

import 'core/theme/app_theme.dart';
import 'features/authentication/welcome/welcome_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (BackendConfig.supabaseConfigured) {
    await Supabase.initialize(url: BackendConfig.supabaseUrl,
      anonKey: BackendConfig.supabaseAnonKey);
  }
  runApp(const ShareTripApp());
}

class ShareTripApp extends StatelessWidget {
  const ShareTripApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShareTrip Student',

      debugShowCheckedModeBanner: false,

      theme: AppTheme.lightTheme,

      home: const WelcomePage(),
    );
  }
}
