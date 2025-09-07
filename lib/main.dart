import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/loading_screen.dart';
import 'screens/connect_screen.dart';
import 'services/sound_manager.dart';
import 'screens/pod_face_screen.dart'; // CORRECTED IMPORT

void main() async {
  // Ensure that Flutter's widget binding is initialized before running the app
  WidgetsFlutterBinding.ensureInitialized();
  await SoundManager().init();

  // Lock screen orientation to landscape for the entire app
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Enable true full-screen mode by hiding system UI (status bar, navigation buttons)
  //await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Hides the "Debug" banner in the top-right corner
      debugShowCheckedModeBanner: false,

      // Sets a dark theme for the entire application
      theme: ThemeData.dark(),

      // The first screen the user will see is the loading screen
      initialRoute: '/loading',

      // Defines all the possible navigation paths and which screen widget they map to
      routes: {
        '/loading': (context) => const LoadingScreen(),
        '/connect': (context) => const ConnectScreen(),
        '/face': (context) => const PodFaceScreen(),
      },
    );
  }
}