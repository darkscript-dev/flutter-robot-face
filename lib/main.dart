import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/loading_screen.dart';
import 'screens/connect_screen.dart';
import 'services/sound_manager.dart';
import 'screens/pod_face_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SoundManager().init();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);


  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      theme: ThemeData.dark(),

      initialRoute: '/loading',
      routes: {
        '/loading': (context) => const LoadingScreen(),
        '/connect': (context) => const ConnectScreen(),
        '/face': (context) => const PodFaceScreen(),
      },
    );
  }
}