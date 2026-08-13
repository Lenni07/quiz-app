import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'screens/mode_select_screen.dart';
import 'services/auth_service.dart';
import 'services/user_profile_service.dart';
import 'theme/app_theme.dart';
import 'utils/page_transitions.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    debugPrint('Firebase: initialized');
    final user = await AuthService().ensureSignedIn();
    debugPrint('Firebase: signed in as ${user.uid}');
    await UserProfileService().ensureProfileExists(user.uid);
    debugPrint('Firebase: profile ensured');
  } catch (e, stack) {
    // Kein Internet oder Firebase nicht erreichbar: App bleibt trotzdem
    // voll nutzbar (offline-first), nur der Cloud-Abgleich fehlt dann.
    debugPrint('Firebase: startup failed: $e');
    debugPrint('$stack');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quiz Up Your Rank',
      theme: buildAppTheme(),
      home: const StartScreen(),
    );
  }
}

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/ocean_sunset_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.25)),
          child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.directions_boat_filled, size: 80, color: Colors.white),
                const SizedBox(height: 24),
                const Text(
                  'Quiz Up Your Rank',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Teste dein Wissen über die deutsche Sprache',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: 220,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        buildFadeSlideRoute(const ModeSelectScreen()),
                      );
                    },
                    child: const Text('Spiel starten'),
                  ),
                ),
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }
}
