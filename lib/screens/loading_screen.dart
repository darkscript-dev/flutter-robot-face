import 'package:flutter/material.dart';
import '../api/pod_api.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({Key? key}) : super(key: key);

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    _checkSavedIpAndNavigate();
  }

  void _checkSavedIpAndNavigate() async {
    await Future.delayed(const Duration(milliseconds: 50));
    await PodApi().initialize();

    if (!mounted) return;

    if (PodApi().isConfigured()) {
      Navigator.pushReplacementNamed(context, '/face');
    } else {
      Navigator.pushReplacementNamed(context, '/connect');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: CircularProgressIndicator(color: Colors.amber),
      ),
    );
  }
}